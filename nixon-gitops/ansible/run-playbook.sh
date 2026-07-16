#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

repo_root="$(cd -- "${script_dir}/.." && pwd)"

playbook_file="${script_dir}/${1}"

export ANSIBLE_ROLES_PATH="${script_dir}/roles${ANSIBLE_ROLES_PATH:+:${ANSIBLE_ROLES_PATH}}"

exec ansible-playbook \
  --inventory "${script_dir}/inventory.ini" \
  "${playbook_file}" \
  "${@:2}"
