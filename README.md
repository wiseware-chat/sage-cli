# sage CLI — beta

Builds of `sage`, the command line of the Sage Markdown editor, and a Claude
Code plugin that lets Claude work with it. `sage` indexes a folder of Markdown
(notes, an Obsidian vault, a Sage drive) and answers as JSON: full-text search,
the `[[wikilink]]` graph, frontmatter records, a drive's named queries and its
check. The current release is `v0.1.0-9f18faa`.

This is a beta. Commands, output and the drive format can still change
between releases, and it comes with no warranty: see [LICENSE](LICENSE).
Please report problems and surprises to the Wiseware team, with the command,
its output and `sage --version`.

## Install

One line installs `sage` into `~/.local/bin` and, when Claude Code is on PATH,
the plugin:

```sh
curl -fsSL https://raw.githubusercontent.com/wiseware-chat/sage-cli/main/install.sh | sh
```

`SAGE_INSTALL_DIR` chooses another folder; `SAGE_NO_PLUGIN=1` skips the plugin.
Running it again installs the release it names and updates the plugin.

## Install the plugin by hand

In Claude Code:

```
/plugin marketplace add wiseware-chat/sage-cli
/plugin install sage@sage
```

Start a new Claude Code session and ask about a drive or a folder of
Markdown; the `sage` skill loads when the work calls for it. The first time
the skill runs `sage` it downloads the build for your machine from this
repository's release into `~/.cache/sage/plugin` and checks its SHA-256
against the digest in the plugin.

## What to ask

You talk to Claude; Claude runs `sage`. Start Claude Code in the folder that
holds your notes or drives, and ask in your own words. For example:

- **Find your way:** "Which of my drives covers on-call?", "What is in this
  drive and how is it meant to be worked?"
- **Answer from your notes:** "What did we decide about the reserve fund?
  Cite the notes." Claude searches, reads only the sections that match and
  names the files it used.
- **Add new information:** "Add these meeting notes to the VvE drive",
  "File this email as a ticket for the gate milestone." Claude looks for an
  existing record first, creates new ones from the drive's templates, links
  them to what they relate to and runs the drive's check.
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

To have the marketplace update itself, open **Marketplaces** in `/plugin`,
choose `sage` and **Enable auto-update**. Or update by hand:

```
/plugin marketplace update sage
```

Each plugin version pins one release; the new build downloads on first use.

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

The plugin is made for Claude Code. In Cowork it needs a sandbox that can
reach github.com to download the build.

## The binaries on their own

```sh
base=https://github.com/wiseware-chat/sage-cli/releases/download/v0.1.0-9f18faa
curl -fsSL -O "$base/sage-darwin-arm64" -O "$base/SHA256SUMS"
shasum -a 256 -c SHA256SUMS --ignore-missing
chmod +x sage-darwin-arm64 && mv sage-darwin-arm64 ~/.local/bin/sage
```

`sage --help` lists every command. To have the plugin run a binary of your own,
set `SAGE_CLI=/path/to/sage`.

## Where things live

- The index: one SQLite database per drive in your user cache directory
  (`--db` chooses another file). It is rebuilt from the Markdown, so deleting
  it loses nothing.
- `sage render` writes rendered pages to the drive's `dist/` folder.
- `sage new` and your edits are the only writes to the drive itself.

Sage's source is at gitlab.com/wiseware-chat/sage; this repository is written
by its `plugin/publish` script, so changes made here are overwritten.
