#!/usr/bin/env bash

# chmod +x run-playbook.sh

# run-playbook.sh update-packages.yaml

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

repo_root="$(cd -- "${script_dir}/.." && pwd)"

playbook_file="${script_dir}/playbooks/${1}"

exec ansible-playbook \
  --inventory "${script_dir}/inventory.ini" \
  "${playbook_file}" \
  "${@:2}"
