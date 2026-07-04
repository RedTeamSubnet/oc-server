#!/bin/bash
set -euo pipefail

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
_PROJECT_DIR="$(cd "${_SCRIPT_DIR}/.." >/dev/null 2>&1 && pwd)"
cd "${_PROJECT_DIR}" || exit 2

_IS_ALL=false

main()
{
	if [ -n "${1:-}" ]; then
		local _input
		for _input in "${@:-}"; do
			case ${_input} in
				-a | --all)
					_IS_ALL=true
					shift;;
				*)
					echo "[ERROR]: Failed to parsing input -> ${_input}!"
					echo "[INFO]: USAGE: ${0}  -a, --all"
					exit 1;;
			esac
		done
	fi

	echo "[INFO]: Cleaning..."

	find . -not -path "*/node_modules/*" -type f -name ".DS_Store" -print -delete || exit 2
	find . -not -path "*/node_modules/*" -type f -name "Thumbs.db" -print -delete || exit 2
	find . -not -path "*/node_modules/*" -type f -name ".coverage*" -print -delete || exit 2
	find . -not -path "*/node_modules/*" -type d -name "__pycache__" -exec rm -rfv {} + || exit 2
	find . -not -path "*/node_modules/*" -type d -name ".turbo" -exec rm -rfv {} + || exit 2
	find . -not -path "*/node_modules/*" -type d -name ".git" -prune -o -type d -name "logs" -exec rm -rfv {} + || exit 2

	if [ "${_IS_ALL}" == true ]; then
		rm -rfv ./dist || exit 2
		rm -rfv ./ts-dist || exit 2
		rm -rfv ./node_modules || exit 2
		find . -type d -name "node_modules" -not -path "./node_modules" -exec rm -rfv {} + || exit 2
	fi

	echo "[OK]: Done."
}

main "${@:-}"
