# Sage drives: the format

A drive is a folder with `.sage/drive.yaml`. Its records are Markdown files
whose YAML frontmatter is the data; everything under `.sage/` declares what
records there are, where they go and what must hold. Every declaration file
is Markdown: only its frontmatter between `---` lines is read, the body is
documentation for people. **Unknown or misspelled keys are ignored silently**,
so a declaration that "does nothing" usually has a key in the wrong place; the
grammar below is exact.

```
.sage/drive.yaml      name, id, workspace, ignore, constants, validity
.sage/drive.md        summary and keywords (frontmatter)
.sage/types/<type>/   type.md, schema.json, template.md
.sage/folders/*.md    where records of a kind are filed
.sage/rules/*.md      what must hold, as findings of `sage check`
.sage/queries/*.md    named tables (`sage query`, `![[query/name]]`)
.sage/relations/*.md  named record sets that rules and queries reuse
.sage/lenses/*.md     notes the editor's sidebar keeps lit (query grammar)
guide.md              at the drive root: how the drive is worked
```

Hidden folders, `dist/`, `target/`, `node_modules/` and `vendor/` are not
indexed. Drives do not nest. After any change to `.sage/`, run `sage check`:
every problem in a declaration is a `definition` error.

## drive.yaml

All keys are optional; an empty file makes a drive.

```yaml
name: Tickets                  # display name; default the folder name
id: tickets                    # how other drives link here: [[tickets:TKT-001]]
workspace: [../shared]         # more folders whose drives this drive's links reach
ignore: [drafts/, "*.tmp"]     # gitignore-style; `!path` takes one back
constants: {terminal: [done, declined]}   # read in CEL as constants.terminal
validity: {from: valid_from, to: valid_to} # keys --on DATE reads; inclusive, missing = open
```

Drives beside each other in one parent folder form a workspace already;
`workspace` adds others, one way only.

## drive.md and guide.md

```markdown
---
summary: Work tickets and milestones for the gate project.
keywords: [tickets, issues, roadmap]
---
```

`sage drives` shows the summary, so an agent can pick the drive without
opening it. Without one, the first paragraph of `guide.md`, `home.md` or
`README.md` serves. `guide.md` at the drive root is printed in full by
`sage drive` as the drive's working instructions; write one for any drive
others will work in.

## Types: `.sage/types/<type>/`

The folder name is the type. A record belongs to it by `type: <type>` in its
frontmatter. A record without a string `type` skips every schema, id,
filename, reference and placement check, so put `type` in `required`.

**type.md**

```markdown
---
title: Ticket
prefix: TKT            # ids are TKT-001, TKT-002 …; the dash is added
padding: 3             # digits, default 3
filename: "{id}-{slug}.md"   # {slug} is the title, lowercased and dashed
derived:
  closed: r.status in constants.terminal   # r.closed in rules and queries
---
What a ticket is, for people.
```

Without `prefix`, `sage new` uses the title's slug as the id. `check`
enforces `filename` only when declared; `{id}` must match exactly, with its
case.

**schema.json** is JSON Schema (draft 2020-12), checked against the whole
frontmatter, `type` and `id` included. Two Sage keys:

- `"recordRef": "<type>"` on a property, or on `items` of a list: the value
  must name a record of that type. Write the value as the bare id
  (`milestone: MS-001`, `depends_on: [TKT-002]`) or as a quoted link
  (`milestone: "[[MS-001]]"`). Unquoted `[[x]]` is a YAML list, not a link.
  Prefer ids: rules and relations resolve ids, aliases, stems and paths, never
  titles.
- `"x-sage-show": false` hides a long field's value in `show --text`.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["type", "id", "title", "status"],
  "properties": {
    "type": {"const": "ticket"},
    "id": {"type": "string"},
    "title": {"type": "string"},
    "status": {"enum": ["open", "done", "declined"]},
    "priority": {"type": "integer", "minimum": 1, "maximum": 3},
    "milestone": {"type": "string", "recordRef": "milestone"},
    "depends_on": {"type": "array", "items": {"type": "string", "recordRef": "ticket"}}
  }
}
```

**template.md** is what `sage new` writes, with `{{id}}`, `{{title}}`,
`{{type}}` and `{{today}}` filled in; `--set key=value` overrides fields.

```markdown
---
type: {{type}}
id: "{{id}}"
title: "{{title}}"
status: open
opened: {{today}}
---
# {{title}}
```

## Folders: `.sage/folders/*.md`

```markdown
---
path: tickets
order: 10                    # lower is tried first
match: r.type == "ticket"    # CEL; the first matching folder takes the record
facets:                      # one subfolder per value, in order
  - field: status
    match: value in ["done", "declined"]
---
```

An open ticket belongs in `tickets/`, a done one in `tickets/done/`. The record
must sit exactly in that folder, not below it: when a facet field changes,
move the file, or `check` reports `placement`. A folder needs `path` or
`layout`: `layout: customers/{r.customer}` computes the path from fields.
**A folder without `match` takes every record**; give each folder a `match`.
`records: false` makes a folder take none.

## Rules: `.sage/rules/*.md`

```markdown
---
for: {type: ticket, where: '!r.closed'}
when: {none: {type: milestone, outgoing: milestone}}
message: an open ticket belongs to no milestone
severity: warn          # error (default) | warn | info
---
```

A rule reports each record that `for` selects and `when` holds for: write
`for`/`when` to describe the **problem**, and `message` to say what is wrong.
Without `when`, every selected record is reported. The file stem is the rule's
name in findings. `message` is required.
**`type` and `where` go under `for:`**; a top-level `where` is ignored and
the rule then fires on every document.

`when` is a frame, a test about other records:

- `exists`, `none`: a matching record is there or not; `count`, whose leaf
  carries `at_least` and/or `at_most`; `not`, `all`, `any` (a list is `all`).
- A leaf: `type`, `where` (CEL over the other record, also called `r`), and
  either `outgoing: field` (this record's field names it) or `incoming: field`
  (its field names this record); `closure: true` follows the field
  transitively; `relation: name` limits it to a relation's records.

```yaml
# a milestone with more than ten open tickets
when: {count: {type: ticket, incoming: milestone, where: r.status == "open", at_least: 11}}
```

## Queries: `.sage/queries/*.md`

```markdown
---
name: Open tickets
summary: Tickets nobody has finished
for: {type: ticket, where: r.status == "open"}
order_by: [-priority, id]        # - sorts descending
presentation:
  columns: [id, title, priority, milestone]
  labels: {priority: P}
  empty: nothing open
---
```

Same `for` and `when` as rules; no top-level `where`, `sort` or `fields`.
Columns are top-level frontmatter keys (lowercase), plus `path` and `title`;
`order_by` sorts only by a shown column, `id` or `path`. Run it with
`sage query open`, or embed it in a page as a table:
`![[query/open]]`, `![[query/open?milestone=MS-001]]`.

## Relations: `.sage/relations/*.md`

```markdown
---
for: {type: ticket, where: r.status == "open"}
reach: {type: ticket, outgoing: depends_on, closure: true, where: '!r.closed'}
---
```

A named set (`for: {relation: blocked}` or a leaf's `relation: blocked`). The
id, the file stem, takes letters, digits and `_` only.

## CEL

Rules, queries and relations compile CEL to SQL over the index; folders run
it directly. Variables: `r` (the frontmatter; keys are case-sensitive),
`now` (today, `YYYY-MM-DD`) and `constants`.

Works: `== != < <= > >=`, `&& || !`, `? :`, `+ - * / %`, `in` a list,
`has(r.x)`, `size()`, `.startsWith() .endsWith() .contains()` (case-sensitive),
`.lowerAscii() .upperAscii() .trim()`, `.exists(x, p)`, `.all(x, p)`,
`date()`, `timestamp()`, `duration("72h")`, `int() double() string()`, and
date arithmetic such as `now - r.updated > duration("72h")`.

Not available: `matches()`, `map`, `filter`, `exists_one`, map literals,
comparing lists with `==`. Such an expression is a `definition` finding, never
silently true.

Dates stay `YYYY-MM-DD` strings and compare as strings. A missing field is
null and matches no comparison: `r.priority > 2` is false without a
priority, and so is `!(r.priority > 2)`; test `has(r.priority)` first when it
matters.

## Links

- `[[Name]]`, `[[folder/Name]]`, `[[Name#Heading]]`, `[[Name|label]]`;
  a name is a path, file stem, id, alias or title.
- `![[Name]]` and `![[Name#Heading]]` embed a page or a section.
- `[[drive-id:Name#Heading]]` links into another drive of the workspace,
  by the id `sage drive` lists for it.
- Anchors are GitHub-style: `## Fix the login` is `#fix-the-login`.
- In frontmatter, a quoted `"[[X]]"` is a link; a bare id in a `recordRef`
  field is a reference too.

## What `sage check` reports

| Finding | Means |
|---|---|
| `definition` | a declaration in `.sage/` is broken |
| `schema` | a record breaks its type's schema |
| `ref-dangling` | a `recordRef` names nothing, or a record of another type |
| `id-mismatch` | the id lacks the type's prefix |
| `filename-mismatch` | the file name breaks the type's `filename` |
| `placement` | the record belongs in another folder (`check` names it) |
| `catalog` | a `type` the drive does not declare |
| `duplicate-id` | two records share an id |
| `broken-link`, `broken-anchor` | a link or `#heading` resolves to nothing |
| `embed-dangling`, `embed-cycle`, `embed-invalid` | an embed or query embed fails |
| `orphan`, `outside-index` | information only |
| a rule's name | that rule, at its severity |

## Working a drive

1. `sage drive`, and read `guide.md` if it prints one.
2. New record: `sage new <type> "Title" --set key=value`. It picks the id,
   folder and file name and lists what is still missing. Prefer it to
   writing the file by hand.
3. Edit records in place; keep `type` and `id`; move the file when `check`
   says `placement`.
4. Changing `.sage/`: edit one declaration, then `sage check`. A new type
   needs `type.md` and, for checked fields, `schema.json`; give it a folder
   with a `match`.
5. `sage check` until no errors remain; report the warnings you left.
