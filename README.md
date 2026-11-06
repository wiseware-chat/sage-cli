# sage CLI

Builds of `sage`, the command line of the Sage Markdown editor, and a Claude
plugin that runs it. Sage's source is at gitlab.com/wiseware-chat/sage; this
repository is written by its `plugin/publish` script.

## The plugin

In Claude Code:

```
/plugin marketplace add wiseware-chat/sage-cli
/plugin install sage@sage
```

The repository is private: Claude Code clones it with your git credentials
(`gh auth login` and `gh auth setup-git`). The skill's first run downloads
the pinned build into `~/.cache/sage/plugin` with `gh`, or with `GH_TOKEN`,
and checks its SHA-256. `SAGE_CLI` runs another binary instead.

## The binaries

Each release carries `sage-darwin-arm64`, `sage-linux-amd64` and
`sage-linux-arm64` (glibc 2.34 or later) with `SHA256SUMS`:

```
gh release download -R wiseware-chat/sage-cli -p "sage-$(uname -s | tr A-Z a-z)-arm64"
```
