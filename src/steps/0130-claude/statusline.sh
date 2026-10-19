#!/usr/bin/env bash
# Claude Code status line. Reads session JSON on stdin, prints 2 or 3 lines.
# Output is plain ASCII: glyphs render badly in some terminal fonts.
# Budget: one jq fork, two git forks (status, diff --shortstat), the rest is bash builtins.
# The PR lookup forks too, but in the background and at most every 120s.

# No set -e: ((n++)) from 0 returns 1, and a non-zero exit blanks the status line.
export LC_NUMERIC=C # printf %.2f must parse "1.23" under any locale

eval "$(jq -r '
  def v: if . == null then "" else tostring end;
  def pct: if type == "number" then round else null end;
  def int: if type == "number" then floor else null end;
  {
    sid:        .session_id,
    model:      (.model.id // .model.display_name),
    effort:     .effort.level,
    think:      .thinking.enabled,
    agent:      .agent.name,
    wt:         (.worktree.name // .workspace.git_worktree),
    wt_from:    .worktree.original_branch,
    start:      (.worktree.original_cwd // .workspace.project_dir),
    cwd:        (.workspace.current_dir // .cwd),
    ndirs:      (.workspace.added_dirs // [] | length),
    host:       .workspace.repo.host,
    repo:       (.workspace.repo | if type == "object" and .name then [.host, .owner, .name] | map(select(. != null)) | join("/") else null end),
    la:         (.cost.total_lines_added // 0),
    lr:         (.cost.total_lines_removed // 0),
    ctx_pct:    (.context_window.used_percentage | pct),
    ctx_used:   (.context_window.total_input_tokens | int),
    ctx_size:   (.context_window.context_window_size | int),
    r5:         (.rate_limits.five_hour.used_percentage | pct),
    r5_at:      (.rate_limits.five_hour.resets_at | int),
    r7:         (.rate_limits.seven_day.used_percentage | pct),
    r7_at:      (.rate_limits.seven_day.resets_at | int),
    rs:         (.rate_limits.spend_limit.used_percentage | pct),
    rs_at:      (.rate_limits.spend_limit.resets_at | int),
    c_warm:     (if .prompt_cache.caching_observed == false then null else .prompt_cache.warm end),
    c_exp:      (.prompt_cache.expires_at | int),
    cost:       .cost.total_cost_usd,
    dur_ms:     (.cost.total_duration_ms | int)
  } | to_entries[] | "\(.key)=\(.value | v | @sh)"
' 2>/dev/null)"

printf -v now '%(%s)T' -1

E=$'\e'
R="$E[0m" B="$E[1m" D="$E[2m"
RED="$E[31m" GRN="$E[32m" YEL="$E[33m" BLU="$E[34m" MAG="$E[35m" CYN="$E[36m"
SEP=" $D|$R "

# Helpers write to REPLY to avoid subshell forks.
color_pct() { # $1 = integer percent
  if (( $1 >= 80 )); then REPLY=$RED; elif (( $1 >= 50 )); then REPLY=$YEL; else REPLY=$GRN; fi
}
fmt_secs() { # $1 = seconds -> 3d4h, 1h12m, 38m, <1m
  local s=$1
  (( s < 0 )) && s=0
  if (( s >= 86400 )); then REPLY="$((s / 86400))d$((s % 86400 / 3600))h"
  elif (( s >= 3600 )); then REPLY="$((s / 3600))h$((s % 3600 / 60))m"
  elif (( s >= 60 )); then REPLY="$((s / 60))m"
  else REPLY="<1m"; fi
}
fmt_tok() { # $1 = tokens -> 180k, 1M, 1.5M
  local n=$1
  if (( n >= 1000000 )); then
    local f=$((n % 1000000 / 100000))
    if (( f )); then REPLY="$((n / 1000000)).${f}M"; else REPLY="$((n / 1000000))M"; fi
  elif (( n >= 1000 )); then REPLY="$((n / 1000))k"
  else REPLY=$n; fi
}
tilde() { if [[ $1 == "$HOME" || $1 == "$HOME"/* ]]; then REPLY="~${1#"$HOME"}"; else REPLY=$1; fi; }
join() { # joins "$@" with SEP into REPLY
  local out="" x
  for x in "$@"; do [[ -n $x ]] && out+="${out:+$SEP}$x"; done
  REPLY=$out
}
limit() { # $1 label, $2 pct, $3 resets_at
  [[ -z $2 ]] && { REPLY=""; return; }
  color_pct "$2"
  local c=$REPLY
  if [[ -n $3 ]]; then fmt_secs $(($3 - now)); REPLY="$1 $c$2%$R $D($REPLY)$R"
  else REPLY="$1 $c$2%$R"; fi
}

# Line 1: model and modes
l1=()
l1+=("$B${model:-?}$R")
[[ -n $effort ]] && l1+=("$MAG$effort$R")
case $think in
  true)  l1+=("${CYN}think$R") ;;
  false) l1+=("${D}no-think$R") ;;
esac
[[ -n $sid ]] && l1+=("${D}session:$sid$R")
join "${l1[@]}"
line1=$REPLY
[[ -n $agent ]] && line1+="  $B${BLU}agent:$agent$R"
if [[ -n $wt ]]; then
  line1+="  $B${YEL}wt:$wt$R"
  [[ -n $wt_from ]] && line1+=" ${D}from $wt_from$R"
fi

# Line 2: location, git, lines
l2=()
[[ -n $repo ]] && l2+=("$B$repo$R")

tilde "${start:-${cwd:-$PWD}}"
loc="$BLU$REPLY$R"
if [[ -n $cwd && -n $start && $cwd != "$start" ]]; then
  if [[ $cwd == "$start"/* ]]; then loc+=" $D->$R $CYN${cwd#"$start"/}/$R"
  else tilde "$cwd"; loc+=" $D->$R $CYN$REPLY$R"; fi
fi
if (( ndirs == 1 )); then loc+=" $D+1 dir$R"
elif (( ndirs > 1 )); then loc+=" $D+$ndirs dirs$R"; fi
l2+=("$loc")

if [[ -n $cwd ]] && gs=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null); then
  head="" oid="" ahead=0 behind=0 st=0 md=0 un=0 cf=0
  while IFS=' ' read -r a b c d _; do
    case $a in
      '#')
        case $b in
          branch.head) head=$c ;;
          branch.oid)  oid=$c ;;
          branch.ab)   ahead=${c#+}; behind=${d#-} ;;
        esac ;;
      1|2) [[ ${b:0:1} != . ]] && ((st++)); [[ ${b:1:1} != . ]] && ((md++)) ;;
      u) ((cf++)) ;;
      '?') ((un++)) ;;
    esac
  done <<< "$gs"
  [[ $head == "(detached)" ]] && head="@${oid:0:7}"
  g="${GRN}git:$head$R"
  (( st )) && g+=" ${GRN}staged:$st$R"
  (( md )) && g+=" ${YEL}mod:$md$R"
  (( un )) && g+=" ${D}new:$un$R"
  (( cf )) && g+=" ${RED}conflict:$cf$R"
  (( ahead )) && g+=" ${CYN}ahead:$ahead$R"
  (( behind )) && g+=" ${CYN}behind:$behind$R"
  l2+=("$g")

  # The branch's open PR, from the provider script named after the remote
  # host. Forge APIs take seconds, so the answer is cached per repo and
  # branch and refreshed in the background, and the line never waits.
  pr_id="" pr_dest="" pr_draft="" pr_url=""
  provider=~/.claude/statusline-pr/$host.sh
  if [[ -n $host && $head != @* && -x $provider ]]; then
    cache_dir=~/.claude/cache/statusline-pr
    key=${repo//%/%25}@${head//%/%25}
    cache=$cache_dir/${key//\//%2F}
    ts=0
    [[ -f $cache ]] && { read -r ts; IFS=$'\t' read -r pr_id pr_dest pr_draft pr_url; } < "$cache"
    if (( now - ts > 120 )); then
      # Stamp the old answer as fresh first, so the refreshes that follow
      # during the fetch reuse it instead of starting a second fetch.
      [[ -d $cache_dir ]] || mkdir -p "$cache_dir"
      printf '%s\n%s\t%s\t%s\t%s\n' "$now" "$pr_id" "$pr_dest" "$pr_draft" "$pr_url" > "$cache" 2>/dev/null
      (
        cd "$cwd" && out=$("$provider" "$head") &&
          printf '%s\n%s\n' "$now" "$out" > "$cache.$$" && mv "$cache.$$" "$cache"
      ) </dev/null >/dev/null 2>&1 &
      disown
    fi
  fi

  # Committed size of the branch against the PR's target, or the default
  # branch without a PR, as the PR would show it.
  base=origin/HEAD
  [[ -n $pr_dest ]] && git -C "$cwd" rev-parse -q --verify "origin/$pr_dest" >/dev/null && base=origin/$pr_dest
  ss=$(git -C "$cwd" --no-optional-locks diff --shortstat "$base...HEAD" 2>/dev/null)
  b=""
  if [[ -n $pr_id ]]; then
    # OSC 8 makes the badge a link in terminals that support it.
    pr="PR #$pr_id"
    [[ -n $pr_url ]] && pr="$E]8;;$pr_url$E\\$pr$E]8;;$E\\"
    if [[ $pr_draft == true ]]; then b="$D$pr draft$R"; else b="$B$MAG$pr$R"; fi
    b+=" $D->$R $pr_dest"
    [[ $base == origin/HEAD ]] && b+=" $D(vs origin/HEAD)$R"
  fi
  if [[ $ss =~ ([0-9]+)\ file ]]; then
    if [[ -n $b ]]; then b+=": "; else b="branch: "; fi
    b+="${BASH_REMATCH[1]} files"
    [[ $ss =~ ([0-9]+)\ insertion ]] && b+=" $GRN+${BASH_REMATCH[1]}$R"
    [[ $ss =~ ([0-9]+)\ deletion ]] && b+=" $RED-${BASH_REMATCH[1]}$R"
  fi
  [[ -n $b ]] && l2+=("$b")
fi

l2+=("$GRN+${la:-0}$R $RED-${lr:-0}$R")
join "${l2[@]}"
line2=$REPLY

# Line 3: context, limits, cache, cost
l3=()
if [[ -n $ctx_size ]]; then
  fmt_tok "$ctx_size"; size=$REPLY
  if [[ -n $ctx_pct ]]; then
    color_pct "$ctx_pct"; c=$REPLY
    fill=$(( (ctx_pct + 5) / 10 )); (( fill > 10 )) && fill=10
    bar="["
    for ((i = 0; i < 10; i++)); do (( i < fill )) && bar+="#" || bar+="-"; done
    bar+="]"
    fmt_tok "${ctx_used:-0}"
    l3+=("ctx $c$bar $ctx_pct%$R $REPLY/$size")
  else
    l3+=("ctx $D-/$size$R")
  fi
fi
limit 5h "$r5" "$r5_at"; l3+=("$REPLY")
limit 7d "$r7" "$r7_at"; l3+=("$REPLY")
limit spend "$rs" "$rs_at"; l3+=("$REPLY")
case $c_warm in
  true)
    if [[ -n $c_exp ]]; then fmt_secs $((c_exp - now)); l3+=("${GRN}cache warm$R $D$REPLY$R")
    else l3+=("${GRN}cache warm$R"); fi ;;
  false) l3+=("${YEL}cache cold$R") ;;
esac
[[ -n $cost ]] && { printf -v c '$%.2f' "$cost"; l3+=("$c"); }
[[ -n $dur_ms ]] && { fmt_secs $((dur_ms / 1000)); l3+=("$D$REPLY$R"); }
join "${l3[@]}"
line3=$REPLY

printf '%s\n' "$line1" "$line2"
[[ -n $line3 ]] && printf '%s\n' "$line3"
exit 0
