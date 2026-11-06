---
name: sage
description: Search, read and check a folder of Markdown or a Sage drive with the `sage` CLI — full-text search, the [[wikilink]] graph, frontmatter records, named queries and the drive gate, as JSON. Use when working in Markdown notes, an Obsidian vault or a folder with `.sage/`.
---

# The sage CLI

`sage` indexes every Markdown file under a root into a local SQLite database
and answers as one JSON object on stdout. The index refreshes itself on each
call. Run it as `"${CLAUDE_SKILL_DIR}/scripts/sage"` (written `sage` below;
a shell variable such as `sage="${CLAUDE_SKILL_DIR}/scripts/sage"` and then
`"$sage" drive` saves repeating it). The first call downloads the pinned build
into `~/.cache/sage/plugin`. The release lives in a private GitHub repository,
so `gh auth login` or `GH_TOKEN` must give read access; `SAGE_CLI=/path/to/sage`
runs a local build instead.

## Start here

- In a folder of drives: `sage drives` lists each drive with its id, summary,
  record types and size. Pick the drive from its summary.
- In a drive (a folder with `.sage/drive.yaml`): `sage drive` gives the record
  types with their required fields, the named queries, the rules and the
  drive's `guide.md`, which says how the drive is meant to be worked. Read it
  before editing records. `sage drive --type TYPE` lists every field of a type.
- From elsewhere, name the drive: `sage --drive <id|dir> ...`.

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

- `sage new TYPE "Title" --set key=value` creates a record from the type's
  template, with its id, folder and filename, and prints what it still needs.
- After editing records, `sage check [PATHS]` is the gate: fix its errors
  before calling the work done (`--strict` also fails on warnings).
- `sage render` writes the pages, rendered for reading, to `dist/`.

`sage --help` has every option. Exit 0 is done, 1 is a failing check, 2 is a
usage or input error with `{"error": ...}` on stderr; an unknown type, field
or document names the closest known ones. Add `--text` for human-readable
output.
