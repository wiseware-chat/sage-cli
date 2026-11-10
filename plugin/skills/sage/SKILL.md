---
name: sage
description: Search, read, add to and check a folder of Markdown notes or a Sage drive, the card index an agent keeps, with the `sage` CLI — full-text search, the [[wikilink]] graph, frontmatter records, templates, named queries and the drive gate, as JSON. Use when answering from the user's notes, an Obsidian vault or a folder with `.sage/` ("what did we decide about X", "who is Y", "do we have a card on Z"); when filing an email, a transcript or meeting notes as records or cards of people, meetings, decisions or projects; when designing a new kind of record or card; or when setting up, checking or reorganising a drive.
---

# The sage CLI

`sage` indexes every Markdown file under a root into a local SQLite database
and answers as one JSON object on stdout. The index refreshes itself on each
call. Run it as `"${CLAUDE_SKILL_DIR}/scripts/sage"`, `scripts/sage` in the
folder of this SKILL.md (written `sage` below; a shell variable such as
`sage="${CLAUDE_SKILL_DIR}/scripts/sage"` and then `"$sage" drive` saves
repeating it). The first call downloads the pinned build from GitHub into
`~/.cache/sage/plugin`, which needs network access once;
`SAGE_CLI=/path/to/sage` runs a local build instead. Builds exist for macOS on
Apple silicon and Linux (x86_64, arm64); Windows is not supported yet.

In a sandbox that allows writes only in the workspace, as Codex's does, `sage`
also needs its caches: ask to run it outside the sandbox, or set
`SAGE_PLUGIN_CACHE_DIR` (the build) and `SAGE_INDEX_CACHE` (the index) to
folders it can write. The first call still needs the network.

## Start here

- In a folder of drives: `sage drives` lists each drive with its id, summary,
  record types and size. Pick the drive from its summary.
- In a drive (a folder with `.sage/drive.yaml`): `sage drive` gives the record
  types with their required fields, the named queries, the rules and the
  drive's `guide.md`, which says how the drive is meant to be worked. Read it
  before editing records. `sage drive --type TYPE` lists every field of a type.
- From elsewhere, name the drive: `sage --drive <id|dir> ...`.

## The user's words: a card index

Users are taught to think of a drive as a card index the agent keeps. Answer
in their words; the commands and files keep Sage's.

| They say | Sage |
|---|---|
| the shelf | the drives in a folder: `sage drives` |
| a box; its label | a drive; the `summary` in `.sage/drive.md` |
| the instructions in the lid | `guide.md` |
| a card; a kind of card | a record; a record type |
| the form; must be filled in | the type's `schema.json`; `required` |
| a blank card | the type's `template.md` |
| the card number | the id (`prefix` in `type.md`) |
| "see card …" | a `[[link]]`, or a `recordRef` field |
| the tabs; moving behind another tab | `.sage/folders/`; `facets` |
| house rules | `.sage/rules/` |
| a standing list | a named query: `sage query NAME` |
| going through the box | `sage check` |
| loose papers | Markdown that is not in a drive yet |

- "File this", "put this in the box": Adding new information.
- "Do we have a card on …", "what does the box say about …": Answering from
  the notes.
- "Pull all …": `sage find --type T --where ...` or a named query; "I keep
  pulling this list": write a query for it.
- "Every X should have a Y": a rule.
- "A new kind of card for …": A new kind of card.
- "Go through the box": `sage check`, then report or fix what it finds.

## Answering from the notes

1. Choose the drive by its summary (`sage drives`), or search every drive of
   the workspace at once: `sage find "words" --workspace`.
2. `sage find "words"`, with synonyms: any word matches, more words rank
   higher. Each row names the document, heading and line. Before saying the
   notes do not have it, try other words, `prefix*` and `--workspace`.
3. `sage show DOC#anchor` (or `--section HEADING`) for the text; read the
   lines it points at, not whole files. `sage links DOC --related` for what
   sits beside it; `sage query NAME` when a named query asks the question.
4. Answer with the paths and headings you read.

## Adding new information

The user hands over notes, an email, a transcript or a document and asks to
put it in a drive ("file this").

1. Choose the drive (`sage drives`), then `sage drive` for its types, their
   required fields and its `guide.md`. Where the guide says how new material
   is filed, follow it.
2. Search before creating: `sage find "key words"`, and
   `sage find --type T --where ...` for the people, projects and dates the
   material names. Update the record that already covers it instead of
   adding a second one; `sage new` writes a record even when one with the
   same title exists, and only notes it.
3. Split the material along the drive's types: one record per meeting,
   decision, person or whatever the types describe, not one file for all of
   it. For material no type fits, follow the guide; without one, ask the
   user before inventing a type.
4. Create each record with `sage new TYPE "Title" --set key=value ...`,
   setting every required field `sage drive --type TYPE` lists; a recordRef
   field takes the other record's id. `--dry-run` shows the file first.
   Then write the body below the frontmatter.
5. Link it: fill recordRef fields and write `[[ID]]` or `[[Title]]` in the
   body to the records it relates to, so it is not an `orphan`.
6. `sage check` and fix its errors. Tell the user which records you created
   or changed, with their paths, and the warnings you left.

## A new kind of card

Design a type with the user before writing any file. Ask in their words, a
topic at a time, and propose answers from the notes they already have:

1. What is one card about: one per meeting, per decision, per person? An
   answer like "one per project, with all its meetings" is two kinds.
   (`type.md`: `title` and the body)
2. How is it numbered: a running number (`prefix: DEC`) for things that
   happen, the name's slug (no `prefix`) for things that exist? (`type.md`)
3. What is on the form? For each field: must it be filled in, is it a pick
   from a list (`enum`), a date or a number, or "see card …" to another
   kind (`recordRef`)? (`schema.json`)
4. What does a blank card hold: the headings they always write?
   (`template.md`)
5. Where is it filed, and does it move behind another tab when it changes?
   (`.sage/folders/`, `facets`)
6. When is a card of this kind wrong? Each answer is a rule; ask whether it
   is an error or a warning. (`.sage/rules/`)
7. Which lists of these cards do they pull? (`.sage/queries/`)

Show the design as a card, and change the card, not files, until the user
agrees:

```
┌─ DECISION ──────────────────────────────── DEC-014 ─┐
│ What was decided  _______________________ (title)   │
│ Date  __________  Status  proposed | decided |      │
│                           superseded                │
│ Decided in  → a meeting card                        │
│ Owner       → a person card                         │
│ Replaces    → a decision card              optional │
├─────────────────────────────────────────────────────┤
│ ## Context   ## Decision   ## Consequences          │
└─────────────────────────────────────────────────────┘
 Filed behind  decisions/, and decisions/superseded/
               once it is superseded
 House rules   a decided card names its meeting (warning)
               a superseded card has a decision that replaces it
 Lists         open decisions · decisions per owner
```

Then read `${CLAUDE_SKILL_DIR}/drives.md`, write the type, its folder, rules
and queries, and run `sage check`. Fill in the first card with the user
through `sage new`. Ask before giving existing notes the new type.

## A folder that is not a drive yet

Search, `show`, `links` and the link findings of `check` work on any folder
of Markdown or Obsidian vault as it is. Make it a drive only when the user
wants record types, templates, rules or queries; there is no `init` command.

1. See what the notes carry already: `sage find --count-by type` (or
   `tags`), and the frontmatter keys with
   `sage sql 'SELECT j.key, count(*) AS n FROM documents d, json_each(d.front) j GROUP BY j.key ORDER BY n DESC'`.
2. Read `${CLAUDE_SKILL_DIR}/drives.md`. Write `.sage/drive.yaml` (`name:`
   is enough), `.sage/drive.md` with `summary` and `keywords`, and a
   `guide.md` at the root saying how the drive is worked and where new
   material goes.
3. Add one type at a time from the keys the notes already use, designed
   with the user as in A new kind of card: `type.md`, `schema.json`,
   `template.md` and a folder with a `match`. `sage check` after each.
4. Adding `type` to existing notes puts them under the schema and the
   folders; do that in bulk only when the user asked, then `sage check`.

## Reading

- `sage find "words"` ranks heading sections by full-text search;
  `sage find --type T --where 'r.status == "open"'` lists records as rows.
- `sage show DOC` gives a document's frontmatter, outline with line ranges,
  and links; `--section HEADING` adds that section's text. Read the lines it
  points at instead of whole files.
- `sage links DOC` (`--in` for backlinks, `--related` for neighbours).
- `sage query NAME` runs a named query of the drive.
- `sage sql 'SELECT ...'` for anything else, read-only.

## Writing

Before writing records by hand or changing anything under `.sage/` (types,
schemas, templates, folders, rules, queries, relations), read
`${CLAUDE_SKILL_DIR}/drives.md`: the exact format, CEL, links, the check's
findings and the mistakes that are easy to make. Unknown keys in `.sage/` are
ignored silently, so guessing the grammar fails quietly.

- `sage new TYPE "Title" --set key=value` creates a record from the type's
  template, with its id, folder and filename, and prints what it still needs.
  The value is YAML: a list field takes `--set 'profiles=[wetten]'`, since
  `--set profiles=wetten` writes a string; `--set 'n="2"'` keeps a string.
- After editing records, `sage check [PATHS]` is the gate: fix its errors
  before calling the work done (`--strict` also fails on warnings).
- `sage render` writes the pages, rendered for reading, to `dist/`.

A `notes` list in the output says what the command could not do or what is
left, such as the required fields a new record still lacks as `--set` flags;
act on it. `sage --help` has every option. Exit 0 is done, 1 is a failing check, 2 is a
usage or input error with `{"error": ...}` on stderr; an unknown type, field
or document names the closest known ones. Add `--text` for human-readable
output.
