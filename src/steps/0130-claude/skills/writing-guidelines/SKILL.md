---
name: writing-guidelines
description: "Prose in any container (Markdown, a README, a report, a PR body, a commit message, a code comment or docstring). Use before you write such prose, and when you review it."
metadata:
  version: "3.1.0"
  argument-hint: <file-or-pattern>
  source: adapted from vercel-labs/writing-guidelines and cursor/plugins pstack (technical-writing, unslop)
---

# Writing guidelines

Read these rules before you draft, and write to them from the first sentence, so the first draft already follows them.

When a rule makes a sentence worse, rewrite the sentence until it obeys the rule and reads naturally. The rules serve the reader.

## Write to the rules

1. Name the reader and what they will do with the text: configure, decide, debug, merge. Every choice below serves that job.
2. Pick the document kind under "Tone by document kind" and hold its tone throughout.
3. Draft to the rules. Lead with the conclusion, then the reasons.
4. Read every sentence once at speech pace. Done when each sentence parses on the first read and every rule holds.

## Review against the rules

Read the target files, or ask the user which. Then apply every rule to every line by hand.

Report each violation as `file:line: rule, fix`, grouped by file, with a bare `pass` for a clean file. Sacrifice grammar for brevity. Done when every rule has met every line.

## By container

The rules target documentation pages. Every container keeps the sentence-level rules (reader first, voice, word choice, concision, ambiguity, AI tells, placeholders, units, emphasis, punctuation). The page-level rules (tone by document kind, headings, structure, lists, code, source formatting, links) apply as follows:

- **Code comment or docstring**: one idea, present tense, the why over the what. No headings, summaries, or links. Lines wrap at the file's column limit, and source formatting does not apply.
- **Commit message**: imperative subject line, then a body in paragraphs that say why the change exists and what it trades off.
- **PR body**: a first paragraph with what changed and why, then what to review as a list. A reviewer reads it in under a minute, so link logs, SHA lists, and metric tables rather than paste them.
- **README, report, or page**: every rule applies.

## Reader first

- Lead with the conclusion, then reasons and detail. A reader who stops after the first sentence still leaves with the point.
- One idea per paragraph, 2 to 4 sentences. Split any paragraph that covers two ideas.
- The common case first, exceptions after.
- Concrete over abstract: an example, a number, or a name beats a category.
- Name the mechanism, not the feeling: "types that follow your schema" becomes "a column rename fails the build". A sentence that could appear unchanged in another project's docs says nothing about this one, so cut it.
- Say why, not only what. The reason is the part the reader cannot infer from the artifact itself.
- Earn every detail: cut a number, name, or implementation detail when a more general phrasing leaves the reader's understanding and next action unchanged.

## Choose voice, tense, and sentence length

- Active voice, with the actor named: "the compiler validates queries". Mental test: append "by monkeys". If the sentence still parses, rewrite it. Passive stays only when the actor is unknown or beside the point.
- Direct address: `you`, in place of `the user` or `one can`.
- Imperative for steps, one instruction per sentence, and no "please": "Click **Add Project**", in place of "You will need to click **Add Project**".
- The condition or warning before the instruction: "To delete the project, click **Delete**." The reader skips what does not apply, and reads the risk before the step.
- Sentence length: 20 words as the target, with lengths varied below it. A short sentence states one point, and a longer one holds a fact with its condition. Split a sentence with two ideas, and keep a long sentence with one idea.
- Whole sentences in paragraphs, with their articles and verbs. Fragment: "Parser rejects bad date -> exit 2, no write". Whole sentence: "The parser rejects a bad date, exits with code 2, and writes nothing." A list item or a review report line can be a fragment.
- Write `you will` and `it is` in full, so a non-native reader and a translator parse every word.
- Present tense for what ships today. `Will` only for behaviour that happens later, and roadmap promises ("we will soon support") stay out.
- `We` for a deliberate action by the authors ("we recommend", "we deprecated"). In a tutorial, `we` also covers the steps the writer and the reader take together ("Now we add the route"). Everywhere else the reader is `you`.
- Statements, not rhetorical questions. A question the writer answers reads as marketing.
- Consecutive sentences in a paragraph open with different phrases.
- Second-read test: if you re-read a sentence to parse it, name the subject, the action, and the consequence. Cut metaphor verbs and pronouns whose referent sits more than one sentence back.

## Word choice

- The codebase is the word list. Write the real symbol, file, flag, or command, not a synonym or a description of it.
- The short, everyday word: `use` over `utilize` or `leverage`, `help` over `facilitate`, `do` over `perform`, `about` over `approximately`, `if` over `in the event that`. A long word buys its length with precision.
- `is` and `has` in place of `serves as`, `stands as`, `boasts`, and `features`.
- `-ing` words only as the name of a thing, such as "the heading" or "a welding torch". Rewrite any other `-ing` word: "When you are doing this" becomes "When you do this".
- Plain words in place of AI vocabulary: `additionally`, `crucial`, `delve`, `enduring`, `enhance`, `foster`, `garner`, `interplay`, `intricate`, `landscape` (as a metaphor), `pivotal`, `showcase`, `tapestry` (as a metaphor), `testament`, `underscore`, `vibrant`.
- The words a developer says out loud. Invent no jargon, and define a term the document coins on first use.
- Literal nouns in place of metaphor nouns: `substrate` becomes `base`, `vector` becomes `way`, `wedge in` becomes `add`, `gold-plating` becomes `more than the job needs`, `evacuate` (as in "evacuate the module") becomes `move out`, `endgame` becomes `the last phase`, and `north star` becomes `goal`. `ratchet` (as a metaphor) becomes the mechanism's real name or `a limit that only tightens`. For `locus`, `vantage`, `nexus`, `primitive` (as a noun), `harness` (as a metaphor), `surface` (as in "API surface"), `bedrock`, `scaffolding` (as a metaphor), `modality`, `paradigm`, and `flywheel`, write the concrete thing the word stands for. A named pattern is fine when the document defines it on first use.
- `easy`, `simple`, and `quick` pressure the reader and read as marketing. Replace them with the concrete fact: "one command", "default settings", "most projects skip this".
- `very`, `just`, `really`, `simply`: filler. Cut or rewrite.

## Cut filler and vague qualifiers

- Filler phrases: "in order to" becomes "to", "due to the fact that" becomes "because", and "it is important to note that" goes.
- Weasel words: replace vague qualifiers (`significantly`, `many`, `often`, `typically`, `generally`) with a specific number or claim.
- Vague quantifiers: `near-zero`, `sub-second`, `most requests` become a figure with a source (`99.37% of requests see zero cold starts`).
- Adverbs that prop up a weak verb: "significantly improves" becomes the measured delta, and "runs quickly" becomes the number.
- Hedging: one qualifier at most. "Could potentially be argued that it might" becomes "may".
- Attribution: name the source behind "experts believe" or "industry reports suggest", or cut the claim.
- Metaphor verbs: name the literal action in place of cadence or a figure. The verbs `moves through`, `lands`, `carries`, `hits`, `rides along`, and `stands on` become the actual step.

## Write sentences that read one way

Every sentence reads one way, for a tired engineer, a non-native reader, a translator, and an agent alike:

- One name per thing, everywhere. A document that says "the gate", "the ratchet", and "the budget check" for one thing teaches three things. The same holds for actions: `start` throughout, not `start` here and `initiate` there. Each word keeps one meaning. If "check" means inspect, it never means restrain.
- Unchanged sentences stay unchanged between edits. A reworded sentence costs the reader a re-read for no new meaning.
- `only` and `not` sit next to the word they change: "only fails on growth" and "fails only on growth" say different things.
- Noun strings become a clause: "the proto import budget check script" becomes "the script that checks the proto-import budget".
- Every `it`, `they`, and `this` points at one obvious noun. Repeat the noun when in doubt, and point `this` or `which` at a noun, never at a whole clause.
- Every clause keeps its verb: "Phase 1 moves the converters and Phase 2 the runtime" leaves Phase 2 without one.
- The small structure words stay. Keep articles: "remove the backup file". Keep `that`: "ensure that the switch is off". Repeat the article for two distinct things: "the client and the host".
- `both...and`, `either...or`, and `if...then` when a series can group two ways.
- Text in parentheses forms a full grammatical unit. Plurals are spelled out, never `(s)`.
- `a, b, or both` in place of `a/b` or `and/or`.
- English in place of Latin abbreviations: `for example`, `that is`. In place of `etc.`, say up front that a list is partial.
- Literal phrasing in place of idioms and colloquialisms.

## AI-generated tells

- Summary-style transitions: a paragraph that opens with a recap of the last one (`With this setup complete...`, `Now that we've explored...`). Pivot straight to the next point (`In practice...`, `The catch is...`).
- Stop-start sentences: one dependent idea split into choppy fragments (`Previously this was manual. Now it's automatic. This saves time.` becomes one sentence). Short sentences for emphasis stay.
- Spec-sheet voice: sentences that read like a system that recites a datasheet (`provides`, `is configurable`, `is explicitly labeled`).
- Cold-open paragraphs: a body paragraph whose first sentence works as a standalone heading has no antecedent. Open with a word that links back to the prior subject (`Because...`, `Once...`).
- Personified artifacts: machines that do human-physical actions. `hand the browser a URL` becomes `the browser fetches the URL`. `the token holds...` becomes `the server stores the token`.
- Mannered prose: aphorisms ("wire it or delete it") and rhetorical fragments for effect. Say the literal thing.
- Reused framing: the angle comes from this document, not a template (`The question most teams face is whether...`).
- Superficial `-ing` tails: "..., highlighting its flexibility", "..., ensuring reliability". State the fact or cut the tail.
- "Not just X, but Y": state the point directly.
- Forced triads: use the natural number of items, not three by habit.
- False ranges: "from startups to enterprises", where the ends share no scale. List the items.
- Generic conclusions: "The future looks bright." End on a specific plan or fact.

## Tone by document kind

Answer two questions to pick the kind. Does the reader act or understand, and do they learn or work? Each pair of answers names a kind:

- Act and learn: tutorial.
- Act and work: how-to.
- Understand and work: reference.
- Understand and learn: conceptual.
- Something broke: troubleshooting.

Each kind has its own tone:

- **Tutorial**: warm, supportive, predictable structure, no traps. Open with what the reader will build, and show the expected output after every step. Cut each explanation to one clause and a link.
- **How-to**: terse and direct, because the reader is mid-task. The guide solves a problem the reader has, not an operation the machine can perform. The title names the task: "Calibrate the radar array". Assume competence, and link the background rather than teach it. Allow forks: "If you want x, do y."
- **Reference**: neutral, exhaustive, quotable. State facts, options, limits, and errors with no hedging. The structure mirrors the thing it describes, so the reader can navigate code and docs together. Describe only, with no instruction or opinion. Generate the content from code where possible, so it stays true.
- **Conceptual**: one bounded topic that the reader can follow away from the product. Explain it so the reader could teach it back. Examples, analogies, and a view on trade-offs are welcome here. Opinion belongs here and in no other kind. The title tolerates an implicit "About..." in front. Answer one real "why" question with its context: design decisions, history, constraints, and alternatives.
- **Troubleshooting**: empathetic, with no apology. Acknowledge, then fix.

A document does one job: tutorial or how-to or reference, one at a time. Split and link when content drifts into another kind.

## Write headings that name the reader's task

- Sentence case at every level: "Configure environment variables".
- The title is user-shaped (the reader's question), not feature-shaped (the engineer's name).
- A task heading is a verb phrase ("Create an instance"), and a concept heading is a noun phrase.
- Subheadings descriptive, never a single generic word: "Caveats when self-hosting on Cloudflare", in place of "Caveats", "Overview", or "Notes".
- The reader can guess a section's content from its heading alone.
- One `h1` per page, and levels descend one step at a time.

## Structure a document around its reader

- The document opens with a one-paragraph summary of what it covers.
- Every major section opens with a summary sentence, except a section that holds only a list, per "Format lists".
- Acronyms spelled out on first use: "Content Security Policy (CSP) blocks inline scripts".
- Every term defined the first time it appears, with a link to its conceptual page where one exists.
- Reference material organised by the structure of the thing it describes, and educational material organised by reader task.

## Format lists

- Three or more list-shaped items in a paragraph become a list.
- Bulleted for unordered, numbered for ordered (lifecycles, sequential steps).
- A complete sentence introduces every list, and a colon ends that sentence. A section that holds only a list takes its heading as the introduction.
- Items share one grammatical form.
- Periods at the end of list items only when the items are full sentences.
- Definition lists, where the term is the item's subject, use `- **Term**: description`. When the description restates its label ("**Performance**: performance improved"), drop the label and write the item as prose.

## Format code blocks

- Every code block has a language tag.
- Highlight the key lines where the renderer supports it: ` ```typescript {8-12,23-37} `.
- At most 80 columns per line and 25 lines per snippet. Longer blocks split with prose between them.
- Omit defaults and repeated variable definitions.
- Prose explains what each code block does, and comments inside the block stay minimal.
- The document is the deliverable, so inline the code in place of a link to a full example file.
- A file count or directory tree in the text matches the repo at the commit that adds the text. The command that regenerates the count or tree follows it.

## Write placeholders that look fake

- Text placeholders in descriptive `snake_case`: `your_access_token_here`, so a double-click selects the whole placeholder.
- Number placeholders count up: `1234567890123`, recognisable as fake and predictable.
- `<TOKEN>`, `xxx`, `your-token`, and generic ALL_CAPS are banned.

## Format units

- Space, then an uppercase unit: `64 KB`, `5 KB`, `200 ms`. Seconds stay bare: `30s`.
- Consistent across the corpus, so readers learn one format.

## Use bold and inline code

- **Bold** marks a UI element or a critical fact. If you use bold to add tone, the sentence is weak, so rewrite it.
- `Inline code` for paths, file extensions, identifiers, and short snippets: `/api`, `.tsx`, `body`, `req`. If it would look odd outside a monospace font, monospace it.
- Headings and bullets hold words only, with no decorative emoji.

## Punctuate in plain ASCII

- ASCII punctuation in prose: straight quotes (`"`, `'`), three periods for an ellipsis (`Loading...`), and words in place of arrows and symbols.
- Periods and commas set the rhythm. When a thought needs separation, end the sentence or use a comma.
- A colon introduces a list, an example, or the description after a list item's label. It never joins two clauses mid-sentence.
- Semicolons become periods. The em dash, the en dash, and the hyphen used as a dash are banned.
- The serial comma: "a, b, and c".
- `&` in place of "and" only where space is constrained: nav labels and buttons.

## Source formatting

- One paragraph is one source line, and the editor wraps it.
- One blank line before a heading, and one before and after a code block.
- Headings separate sections, and horizontal rules (`---`) are banned.
- Blank lines only where a paragraph breaks.

## Write link text that names the destination

- Anchor text names the destination. Bare URLs and `here` or `link` are banned.
- Give a sentence of context on the page. Then link the canonical page for a product or concept rather than restate it.
