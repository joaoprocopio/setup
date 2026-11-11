#!/usr/bin/env bash
# Claude Code status line. Reads session JSON on stdin, prints 1 to 3 lines.
# Output is plain ASCII: glyphs render badly in some terminal fonts.
# Budget: one jq fork, one git fork (status), the rest is bash builtins.
# The PR lookup forks too, but in the background and at most every 120s.

# No set -e: ((n++)) from 0 returns 1, and a non-zero exit blanks the status line.
shopt -s extglob # vislen strips escapes with *(...) patterns

eval "$(jq -r '
  def v: if . == null then "" else tostring end;
  def pct: if type == "number" then round else null end;
  def int: if type == "number" then floor else null end;
  {
    model:      (.model.id // .model.display_name),
    effort:     .effort.level,
    agent:      .agent.name,
    wt:         (.worktree.name // .workspace.git_worktree),
    wt_from:    .worktree.original_branch,
    start:      (.worktree.original_cwd // .workspace.project_dir),
    cwd:        (.workspace.current_dir // .cwd),
    ndirs:      (.workspace.added_dirs // [] | length),
    host:       .workspace.repo.host,
    repo:       (.workspace.repo | if type == "object" and .name then [.host, .owner, .name] | map(select(. != null)) | join("/") else null end),
    ctx_pct:    (.context_window.used_percentage | pct),
    ctx_used:   (.context_window.total_input_tokens | int),
    ctx_size:   (.context_window.context_window_size | int),
    r5:         (.rate_limits.five_hour.used_percentage | pct),
    r5_at:      (.rate_limits.five_hour.resets_at | int),
    r7:         (.rate_limits.seven_day.used_percentage | pct),
    r7_at:      (.rate_limits.seven_day.resets_at | int)
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
vislen() { # $1 = string -> printed width, ignoring SGR colors and OSC 8 links
  local s=${1//$'\e]8;;'*([^$'\e'])$'\e\\'/}
  s=${s//$'\e['*([0-9;])m/}
  REPLY=${#s}
}
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

# Block 1: model and modes
b1=()
model=${model#claude-}
m="$B${model:-?}$R"
[[ -n $effort ]] && m+=" $MAG$effort$R"
b1+=("$m")
[[ -n $agent ]] && b1+=("$B${BLU}agent:$agent$R")
if [[ -n $wt ]]; then
  w="$B${YEL}wt:$wt$R"
  [[ -n $wt_from ]] && w+=" ${D}from $wt_from$R"
  b1+=("$w")
fi
join "${b1[@]}"
block1=$REPLY

# Block 2: where the session started, where the agent is now, and git.
# The current directory is yellow, so a cd away from the start stands out.
b2=()
tilde "${start:-${cwd:-$PWD}}"
[[ $REPLY == "~" ]] || REPLY=${REPLY##*/}
loc="$BLU$REPLY$R"
if [[ -n $cwd && -n $start && $cwd != "$start" ]]; then
  if [[ $cwd == "$start"/* ]]; then loc+=" $D->$R $YEL${cwd#"$start"/}/$R"
  else tilde "$cwd"; loc+=" $D->$R $YEL$REPLY$R"; fi
fi
if (( ndirs == 1 )); then loc+=" $D+1 dir$R"
elif (( ndirs > 1 )); then loc+=" $D+$ndirs dirs$R"; fi
b2+=("$loc")

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
  g="$GRN$head$R"
  (( st )) && g+=" ${GRN}staged:$st$R"
  (( md )) && g+=" ${YEL}mod:$md$R"
  (( un )) && g+=" ${D}new:$un$R"
  (( cf )) && g+=" ${RED}conflict:$cf$R"
  (( ahead )) && g+=" ${CYN}ahead:$ahead$R"
  (( behind )) && g+=" ${CYN}behind:$behind$R"
  b2+=("$g")

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
  if [[ -n $pr_id ]]; then
    # OSC 8 makes the badge a link in terminals that support it.
    pr="PR #$pr_id"
    [[ -n $pr_url ]] && pr="$E]8;;$pr_url$E\\$pr$E]8;;$E\\"
    if [[ $pr_draft == true ]]; then p="$D$pr draft$R"; else p="$B$MAG$pr$R"; fi
    b2+=("$p $D->$R $pr_dest")
  fi
fi
join "${b2[@]}"
block2=$REPLY

# Block 3: context and rate limits
b3=()
if [[ -n $ctx_size ]]; then
  fmt_tok "$ctx_size"; size=$REPLY
  if [[ -n $ctx_pct ]]; then
    color_pct "$ctx_pct"; c=$REPLY
    fmt_tok "${ctx_used:-0}"
    b3+=("ctx $c$ctx_pct%$R $REPLY/$size")
  else
    b3+=("ctx $D-/$size$R")
  fi
fi
limit 5h "$r5" "$r5_at"; b3+=("$REPLY")
limit 7d "$r7" "$r7_at"; b3+=("$REPLY")
join "${b3[@]}"
block3=$REPLY

# Layout: blocks 1 and 2 share a line when they fit, and block 3 sits flush
# right on the last line, or on its own line when it does not fit there.
# Claude Code indents the status line by 2 columns, and the rest of the
# margin keeps a line at full width from wrapping. A block never splits.
width=$(( ${COLUMNS:-0} - 4 ))
lines=()
vislen "$block1"; n1=$REPLY
vislen "$block2"; n2=$REPLY
if (( n1 + 3 + n2 <= width )); then lines+=("$block1$SEP$block2")
else lines+=("$block1" "$block2"); fi
if [[ -n $block3 ]]; then
  vislen "$block3"; n3=$REPLY
  last=${lines[-1]}
  vislen "$last"; nl=$REPLY
  if (( nl + 3 + n3 <= width )); then
    printf -v pad '%*s' $(( width - nl - n3 )) ''
    lines[-1]="$last$pad$block3"
  else
    pad=""
    (( n3 < width )) && printf -v pad '%*s' $(( width - n3 )) ''
    lines+=("$pad$block3")
  fi
fi

printf '%s\n' "${lines[@]}"
exit 0
