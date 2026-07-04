#!/bin/bash
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2

if [ -f ".env" ]; then
	source .env
fi

if [ -z "$(which gh)" ]; then
	echo "[ERROR]: 'gh' not found or not installed!"
	exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
	echo "[ERROR]: You need to login: 'gh auth login'!"
	exit 1
fi

echo "[INFO]: Creating release..."

_version="$(./scripts/get-version.sh)"

if gh release view "v${_version}" >/dev/null 2>&1; then
	echo "[ERROR]: Release 'v${_version}' already exists!"
	exit 1
fi

gh release create "v${_version}" \
	--title "v${_version}" \
	--generate-notes

echo "[OK]: Release 'v${_version}' created."
