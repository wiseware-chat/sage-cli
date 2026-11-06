#!/bin/sh
# Installs the sage CLI v0.1.0-5e8a513 from github.com/wiseware-chat/sage-cli into ~/.local/bin
# (SAGE_INSTALL_DIR chooses another folder) and, when Claude Code is on PATH,
# adds the plugin's marketplace and installs the plugin.
#
#   curl -fsSL https://raw.githubusercontent.com/wiseware-chat/sage-cli/main/install.sh | sh
#
# SAGE_NO_PLUGIN=1 skips the plugin.
set -eu

repo=wiseware-chat/sage-cli
tag=v0.1.0-5e8a513
dir=${SAGE_INSTALL_DIR:-${HOME:?HOME is not set}/.local/bin}

say() { printf 'sage install: %s\n' "$*" >&2; }
fail() { say "$*"; exit 1; }

case $(uname -s) in
  Linux) os=linux ;;
  Darwin) os=darwin ;;
  MINGW*|MSYS*|CYGWIN*|Windows*) fail "Windows is not supported yet; under WSL, sage installs as on Linux" ;;
  *) fail "no sage build for $(uname -s); builds exist for Linux and macOS" ;;
esac
case $(uname -m) in
  x86_64|amd64) arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) fail "no sage build for $(uname -m)" ;;
esac
[ "$os-$arch" != darwin-amd64 ] || fail "no sage build for Intel Macs yet"
asset=sage-$os-$arch

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# One release asset into $tmp: the public download URL, else through gh or
# the API with a token, for a repository that is not public.
fetch() {
  if command -v curl >/dev/null 2>&1 &&
    curl -fsSL "https://github.com/$repo/releases/download/$tag/$1" -o "$tmp/$1" 2>/dev/null; then
    return 0
  fi
  if command -v gh >/dev/null 2>&1 && gh release download "$tag" -R "$repo" -p "$1" -D "$tmp" --clobber 2>/dev/null; then
    return 0
  fi
  token=${GH_TOKEN:-${GITHUB_TOKEN:-}}
  [ -n "$token" ] || fail "cannot download $1 from github.com/$repo: is the network reachable?"
  api=https://api.github.com/repos/$repo
  id=$(curl -fsSL -H "Authorization: Bearer $token" "$api/releases/tags/$tag" |
    tr ',{' '\n\n' | awk -v f="\"$1\"" '
      /"url":/ && /\/releases\/assets\// { gsub(/.*\/assets\/|"/, ""); id = $0 }
      /"name":/ && index($0, f) { print id; exit }')
  [ -n "$id" ] || fail "release $tag of $repo has no $1, or the token cannot read it"
  curl -fsSL -H "Authorization: Bearer $token" -H 'Accept: application/octet-stream' \
    "$api/releases/assets/$id" -o "$tmp/$1" || fail "cannot download $1"
}

say "fetching $asset $tag from github.com/$repo"
fetch "$asset"
fetch SHA256SUMS
want=$(awk -v f="$asset" '$2 == f { print $1 }' "$tmp/SHA256SUMS")
if command -v sha256sum >/dev/null 2>&1; then
  got=$(sha256sum "$tmp/$asset" | awk '{print $1}')
else
  got=$(shasum -a 256 "$tmp/$asset" | awk '{print $1}')
fi
[ -n "$want" ] && [ "$got" = "$want" ] || fail "$asset has digest $got, SHA256SUMS says ${want:-nothing}"

mkdir -p "$dir"
chmod 755 "$tmp/$asset"
mv -f "$tmp/$asset" "$dir/sage"
say "installed $("$dir/sage" --version) as $dir/sage"
case ":$PATH:" in
  *":$dir:"*) ;;
  *) say "$dir is not on PATH; add it to your shell's profile" ;;
esac

if [ "${SAGE_NO_PLUGIN:-}" = 1 ]; then
  exit 0
fi
if ! command -v claude >/dev/null 2>&1; then
  say "Claude Code is not on PATH; to add the plugin later, run in Claude Code:"
  say "  /plugin marketplace add $repo"
  say "  /plugin install sage@sage"
  exit 0
fi
if claude plugin marketplace list 2>/dev/null | grep -q "$repo"; then
  claude plugin marketplace update sage >/dev/null || fail "cannot update the sage marketplace"
else
  claude plugin marketplace add "$repo" >/dev/null || fail "cannot add the marketplace $repo"
fi
claude plugin install sage@sage >/dev/null || fail "cannot install the plugin sage@sage"
say "installed the Claude Code plugin sage@sage; start a new session to use it"
