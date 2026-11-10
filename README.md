# sage CLI — beta

`sage` is the command line of the Sage Markdown editor, and this repository
holds its builds and a plugin that hands it to your AI agent: Claude (Claude
Code, the Claude desktop app, Cowork) and ChatGPT (Codex in the desktop app
and the Codex CLI). Point it at a folder of Markdown (notes, an Obsidian
vault, a Sage drive) and the agent can search it, follow its links, query
its frontmatter as data and check it, with every answer as JSON. The current
release is `v0.1.0-899db5d`.

`sage` runs on **macOS (Apple silicon) and Linux** (x86_64 and arm64). Windows
is not supported yet; under WSL, the Linux build works.

This is a beta. Commands, output and the drive format can still change
between releases, and it comes with no warranty: see [LICENSE](LICENSE).
Please report problems and surprises to the Wiseware team, with the command,
its output and `sage --version`.

## A card index for your agent

Think of a drive as a card index that your agent keeps for you. Every card
is a Markdown file. Each kind of card, such as a meeting, a person or a
decision, has its own printed form with the fields that must be filled in,
and its own place in the box. Cards refer to one another by number. Hand the
agent an email, a transcript or a pile of notes and it writes them up as
cards, files each one where it belongs, and goes through the box for cards
that are incomplete, misfiled or point at cards that do not exist. Ask it a
question and it pulls the right cards instead of reading the whole box.

If you know FileMaker, Airtable or Notion databases: it is that without the
app, since your agent is the interface, and every card is a Markdown file in
your own folder.

Talk to your agent in the words of the card index; the skill tells it what
each one means in `sage`:

| Say | Means | In the drive |
|---|---|---|
| a box | a drive | `.sage/drive.yaml` |
| the label on the box | what the drive is for | `.sage/drive.md` |
| the instructions in the lid | how the drive is worked | `guide.md` |
| a card | a record | a Markdown file with frontmatter |
| a kind of card | a record type | `.sage/types/<type>/` |
| the form | its fields, and which must be filled in | `schema.json` |
| a blank card | what a new card starts as | `template.md` |
| the card number | its id | `DEC-014` |
| "see card …" | a link to another card | `[[DEC-014]]` |
| the tabs | where each kind is filed, and when it moves | `.sage/folders/` |
| house rules | what a correct card must satisfy | `.sage/rules/` |
| a standing list | a pull you make often | `.sage/queries/` |
| going through the box | the check | `sage check` |
| loose papers | notes that are not in a drive | any folder of Markdown |

"We need a new kind of card for decisions" starts a short design talk: what
one card is about, how it is numbered, what is on the form, where it is
filed, when it is wrong and which lists you pull. The agent shows the design
as a card before it writes any files, and changes the card until you agree:

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

Then it writes the kind of card, its tabs, house rules and lists, goes
through the box and fills in the first card with you.

## Why sage

A wiki, or a folder of notes, is written for people who browse it. An agent
working in one has two poor choices: read whole files until it finds the
answer, or `grep` and guess. Both burn context on text it does not need, and
neither tells it whether what it wrote fits the rest. `sage` gives the agent
the tools a person gets from a good wiki, and the checks a wiki leaves to
discipline.

**Your files stay yours.** Notes remain plain Markdown with YAML frontmatter,
in your folder, under your version control. No server, no account, no
import: the index is a cache that `sage` brings up to date with the files on
every call, so it is never stale and deleting it loses nothing. Obsidian, your
editor and git keep working as before.

**The agent reads less and finds more.**

- `sage find` ranks heading sections by full-text search, with phrases,
  `+must`, `-not` and prefixes, and answers with the heading, line and a
  snippet, so the agent opens the ten lines that matter rather than ten
  files.
- `sage show` gives a page's outline with line ranges, its frontmatter and its
  links before anything is read in full.
- `sage links` follows the `[[wikilink]]` graph both ways: what a page links
  to, what links to it, and its neighbours.

**Notes become data.** Frontmatter is queryable: `sage find --type ticket
--where 'r.status == "open" && r.priority > 2'` lists records as rows, a
drive's named queries return the same table each time, and `sage sql` answers
anything else, read-only.

**A drive keeps the folder in shape.** Add a `.sage/` folder and the notes
get a structure that `sage` holds them to:

- *Record types* with a JSON Schema, a template and an id scheme. `sage new
  ticket "Login fails"` writes `TKT-014-login-fails.md` in the right folder
  with the right fields, and says what is still missing.
- *Folders* that say where each kind of record is filed, down to subfolders
  by status.
- *Rules* in CEL, such as "an open ticket belongs to a milestone", reported
  at the severity you choose.
- *Queries* that become tables, in the CLI and embedded in pages as
  `![[query/open]]`.

Then `sage check` is the gate: broken links and anchors, records that break
their schema, references to records that do not exist, duplicate ids,
misfiled records and every rule. An agent that edits your notes runs it
before it calls the work done, so a hundred edits later the knowledge base
still holds together, which a wiki only does when every editor is careful.

**Drives work together.** Drives beside each other link into one another,
`[[tickets:TKT-014]]`, and `sage drives` lists every drive in a folder with
its summary, so the agent picks the right one without opening them all.

| | A wiki or notes folder | With sage |
|---|---|---|
| Finding things | Browse, search by page | Ranked sections with line numbers, links both ways |
| Structured facts | Tables kept by hand | Frontmatter queried as rows, named queries |
| Consistency | Editors' care | `sage check`: schemas, references, links, filing, rules |
| New pages | Copy an old one | `sage new` from the type's template, filed and numbered |
| For an agent | Whole files in its context | JSON answers, only the lines it needs |
| Where it lives | A server or an app's store | Markdown in your folder and repository |

## How to use it

Once the plugin is installed, start a session in a folder of Markdown and ask
in your own words. The `sage` skill loads when the work calls for it; you do
not need to name it. For example:

- "What do my notes say about the coastal survey?" — `sage find`, then `show`
  on the best hits.
- "Which pages link to *Project Atlas*, and which of its links are broken?" —
  `sage links --in`, `sage check`.
- "List the open tickets with priority 3, by milestone." — `sage find --type
  ticket --where ...` or a named query.
- "Add a meeting note for today's review with Sam." — `sage new`, then the
  edit.
- "Check the drive and fix what it reports." — `sage check`, the fixes, and
  `sage check` again.
- "Turn this folder into a drive with tickets and milestones." — the agent
  writes `.sage/` from the format the skill carries, then checks it.

Any folder of Markdown works as it is. To make one a drive, create an empty
`.sage/drive.yaml`; record types, folders, rules and queries are each a small
Markdown file under `.sage/`, which the agent can write for you. A
`guide.md` at the drive's root tells every agent how the drive is meant to
be worked; `sage drive` prints it first.

On your own, `sage --help` lists every command and `--text` prints
human-readable output instead of JSON.

## Install

### The command line

One line installs `sage` into `~/.local/bin` and, when Claude Code is on
PATH, the Claude plugin:

```sh
curl -fsSL https://raw.githubusercontent.com/wiseware-chat/sage-cli/main/install.sh | sh
```

`SAGE_INSTALL_DIR` chooses another folder; `SAGE_NO_PLUGIN=1` skips the plugin.
Running it again installs the release it names and updates the plugin.

The plugins below do not need this: the first time the skill runs `sage`, it
downloads the build for your machine from this repository's release into
`~/.cache/sage/plugin` and checks its SHA-256 against the digest in the
plugin. To have them use a binary you installed, set `SAGE_CLI=/path/to/sage`.

### Claude Code in the terminal

```
/plugin marketplace add wiseware-chat/sage-cli
/plugin install sage@sage
```

Start a new session to use it.

### The Claude desktop app

The Claude desktop app runs on macOS and Windows, with a beta for Linux;
`sage` itself runs in sessions on macOS and Linux.

**Code tab.** It shares plugins with Claude Code on the same machine, so the
one-line installer above, or `claude plugin marketplace add wiseware-chat/sage-cli` in a
terminal, adds the marketplace. Then, in a local or SSH session, click **+**
beside the prompt box and choose **Add plugins** (or **Plugins**, then
**Browse plugins**), select **sage** and choose whether to install it for
your account, the project or this folder only. Plugins do not run in cloud
sessions.

**Cowork** (paid plans). Open **Customize** in the left sidebar (in Cowork,
open the **Cowork** tab first) and go to the **Plugins** tab. Click **Add**,
then **Add marketplace**, choose **Add from a repository** and enter
`wiseware-chat/sage-cli`. Then open **Discover**, select **sage** and click **Add**.
Cowork's sandbox must be able to reach github.com for the first download.

### ChatGPT: Codex in the desktop app and the CLI

`sage` works on the folders on your machine, so use it from Codex, in the
ChatGPT desktop app or the Codex CLI. Add this repository as a Codex
marketplace:

```sh
codex plugin marketplace add wiseware-chat/sage-cli
```

Then open the plugin browser, **Plugins** in Codex in the ChatGPT desktop
app or `/plugins` in the Codex CLI, choose the **Sage** marketplace, install
**Sage** and start a new chat. `codex plugin marketplace upgrade sage` fetches
a newer release. In a ChatGPT workspace, an admin can import the repository
for everyone from the admin console's plugin settings.

Codex's sandbox allows writes only in the workspace, while `sage` keeps the
downloaded build and its index in your cache folder: approve running it
outside the sandbox when Codex asks, or set `SAGE_PLUGIN_CACHE_DIR` and
`SAGE_INDEX_CACHE` to folders the sandbox can write. With `sage` installed by
the one-line installer, `SAGE_CLI=~/.local/bin/sage` skips the download.

## What to ask

You talk to Claude; Claude runs `sage`. Start Claude Code in the folder that
holds your notes or drives, and ask in your own words. For example:

- **Find your way:** "Which of my drives covers on-call?", "What is in this
  drive and how is it meant to be worked?"
- **Answer from your notes:** "What did we decide about the reserve fund?
  Cite the notes." Claude searches, reads only the sections that match and
  names the files it used.
- **Add new information:** "File these meeting notes in the VvE box",
  "File this email as a ticket for the gate milestone." Claude looks for an
  existing card first, creates new ones from the drive's templates, links
  them to what they relate to and runs the drive's check.
- **Design a kind of card:** "We need a new kind of card for decisions: what
  was decided, in which meeting, by whom." Claude asks what goes on the
  form, shows the card, and writes the type once you agree.
- **Keep a drive in order:** "What is still open?", "Run the check and fix
  what it finds", "Which notes link nowhere?"
- **Start a drive:** "Turn this folder of notes into a drive with a meeting
  type and a person type." Claude writes the `.sage/` declarations from the
  frontmatter your notes already have, and a `guide.md` that tells the next
  agent how the drive is worked.

A plain folder of Markdown or an Obsidian vault works as it is: search,
links and the link check need no setup. A drive (a folder with
`.sage/drive.yaml`) adds record types, templates, folders, rules and named
queries on top.

## Updates

Each plugin version pins one release; the new build downloads on first use.
Claude Code does not update third-party marketplaces by itself: open
**Marketplaces** in `/plugin`, choose `sage` and **Enable auto-update**, or
update by hand:

```
/plugin marketplace update sage
```

In Codex, run `codex plugin marketplace upgrade sage`. Running the one-line
installer again updates the command line and the Claude plugin.

## Platforms

| Build | Runs on |
|---|---|
| `sage-darwin-arm64` | macOS on Apple silicon |
| `sage-linux-amd64` | Linux x86_64 with glibc 2.34 or later (Ubuntu 22.04, Debian 12, Fedora 35 and newer) |
| `sage-linux-arm64` | Linux aarch64 with glibc 2.34 or later |

Windows is not supported yet (under WSL, use the Linux build). There is no
build for Intel Macs or musl (Alpine) yet.

The macOS build is not notarized. Through the installer, the plugin or `curl`
it runs as is; a copy downloaded with a browser is stopped by Gatekeeper,
which `xattr -d com.apple.quarantine sage-darwin-arm64` releases.

## The binaries on their own

```sh
base=https://github.com/wiseware-chat/sage-cli/releases/download/v0.1.0-899db5d
curl -fsSL -O "$base/sage-darwin-arm64" -O "$base/SHA256SUMS"
shasum -a 256 -c SHA256SUMS --ignore-missing
chmod +x sage-darwin-arm64 && mv sage-darwin-arm64 ~/.local/bin/sage
```

`sage --help` lists every command.

## Where things live

- The index: one SQLite database per drive in your user cache directory
  (`--db` chooses another file, `SAGE_INDEX_CACHE` another folder). It is
  rebuilt from the Markdown, so deleting it loses nothing.
- `sage render` writes rendered pages to the drive's `dist/` folder.
- `sage new` and your edits are the only writes to the drive itself.

Sage's source is at gitlab.com/wiseware-chat/sage; this repository is written
by its `plugin/publish` script, so changes made here are overwritten.
