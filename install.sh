#!/bin/sh
# Installs the Berth command line. Usage: curl -fsSL https://atberth.com/install.sh | sh
set -eu
dir="${BERTH_INSTALL_DIR:-${HOME}/.local/bin}"
url="${BERTH_CLI_URL:-https://raw.githubusercontent.com/mikeshobes718/berth-cli/main/berth}"
dest="${dir}/berth"
if ! command -v python3 >/dev/null 2>&1; then
  echo "berth needs python3 (3.9 or newer). Install it, then run this again." >&2
  exit 1
fi
if ! python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'; then
  echo "berth needs python3 3.9 or newer. Found $(python3 -V 2>&1)." >&2
  exit 1
fi
mkdir -p "${dir}"
tmp="${dest}.tmp.$$"
trap 'rm -f "${tmp}"' EXIT
curl -fsSL "${url}" -o "${tmp}"
if ! head -n 1 "${tmp}" | grep -q python3; then
  echo "The download did not look like the berth script. Try again later." >&2
  exit 1
fi
chmod 755 "${tmp}"
mv "${tmp}" "${dest}"
trap - EXIT
echo "Installed ${dest} ($("${dest}" --version))"
case ":${PATH}:" in
  *":${dir}:"*) ;;
  *) echo "Add this to your shell config: export PATH=\"${dir}:\$PATH\"" ;;
esac
