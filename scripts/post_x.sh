#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/post_x.sh [--print] "post text"
  echo "post text" | scripts/post_x.sh [--print]

Options:
  --print         Print the resolved chrome-use workflow without sending the post.
  -h, --help      Show this help message.

Notes:
  - Uses chrome-use + Chrome for Testing, not xurl.
  - Reads post text from the first positional argument or stdin.
  - Uses the same managed browser session for publish and verification.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

print_only=0
text=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print)
      print_only=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      text="$1"
      shift
      if [[ $# -gt 0 ]]; then
        echo "unexpected extra arguments" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$text" && $# -gt 0 ]]; then
  text="$1"
fi

if [[ -z "$text" && ! -t 0 ]]; then
  text="$(cat)"
fi

if [[ -z "$text" ]]; then
  echo "missing post text" >&2
  usage >&2
  exit 1
fi

cmd=(node "$SCRIPT_DIR/post_x_via_chrome_use.mjs" --text "$text")
if [[ "$print_only" -eq 1 ]]; then
  cmd+=(--print)
fi

"${cmd[@]}"
