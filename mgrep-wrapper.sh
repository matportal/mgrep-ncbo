#!/usr/bin/env bash
set -euo pipefail

if [[ $# -eq 0 ]]; then
  exec /opt/mgrep/mgrep.bin match \
    -p 55555 \
    -d /srv/mgrep/dictionary.txt \
    -w /srv/mgrep/word_divider.txt \
    -c /srv/mgrep/CaseFolding.txt
fi

case "${1}" in
  match|extend|index|--help|-h|--version|-v)
    exec /opt/mgrep/mgrep.bin "$@"
    ;;
esac

# Compatibility layer for historical flags used by OntoPortal deployment scripts:
#   --port/-p, -f (dictionary), -w (word divider), -c (casefolding), -l (longest)
translated=(match)
while (($#)); do
  case "$1" in
    -f|--dictionary-file)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Missing value for dictionary option" >&2
        exit 2
      fi
      translated+=(-d "$1")
      ;;
    --dictionary-file=*)
      translated+=(-d "${1#*=}")
      ;;
    --port|-p)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Missing value for port option" >&2
        exit 2
      fi
      translated+=(-p "$1")
      ;;
    --port=*)
      translated+=(-p "${1#*=}")
      ;;
    *)
      translated+=("$1")
      ;;
  esac
  shift || true
done

exec /opt/mgrep/mgrep.bin "${translated[@]}"
