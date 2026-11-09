---
name: sage
description: Search, read, add to and check a folder of Markdown or a Sage drive with the `sage` CLI — full-text search, the [[wikilink]] graph, frontmatter records, templates, named queries and the drive gate, as JSON. Use when answering from Markdown notes, an Obsidian vault or a folder with `.sage/`; when adding, filing or importing new information into one; or when setting up or reorganising a drive.
---

# The sage CLI

`sage` indexes every Markdown file under a root into a local SQLite database
and answers as one JSON object on stdout. The index refreshes itself on each
call. Run it as `"${CLAUDE_SKILL_DIR}/scripts/sage"` (written `sage` below;
a shell variable such as `sage="${CLAUDE_SKILL_DIR}/scripts/sage"` and then
`"$sage" drive` saves repeating it). The first call downloads the pinned build
from GitHub into `~/.cache/sage/plugin`, which needs network access once;
`SAGE_CLI=/path/to/sage` runs a local build instead. Builds exist for macOS on
Apple silicon and Linux (x86_64, arm64); Windows is not supported yet.

## Start here

- In a folder of drives: `sage drives` lists each drive with its id, summary,
  record types and size. Pick the drive from its summary.
- In a drive (a folder with `.sage/drive.yaml`): `sage drive` gives the record
  types with their required fields, the named queries, the rules and the
  drive's `guide.md`, which says how the drive is meant to be worked. Read it
  before editing records. `sage drive --type TYPE` lists every field of a type.
- From elsewhere, name the drive: `sage --drive <id|dir> ...`.

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
put it in a drive.

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
3. Add one type at a time from the keys the notes already use: `type.md`,
   `schema.json`, `template.md` and a folder with a `match`. `sage check`
   after each.
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
