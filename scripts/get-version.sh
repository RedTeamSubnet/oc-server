#!/bin/bash
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2

if [ -f ".env" ]; then
	source .env
fi

VERSION_FILE_PATH="${VERSION_FILE_PATH:-./VERSION.txt}"

if [ -f "${VERSION_FILE_PATH}" ]; then
	cat "${VERSION_FILE_PATH}"
else
	echo "0.0.0-$(date -u '+%y%m%d')"
fi
