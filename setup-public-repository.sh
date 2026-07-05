#!/usr/bin/env bash

# chmod +x setup-public-repository.sh

set -euo pipefail

# FUNCTIONS #

strip_registry_from_images() {
  local root_dir="$1"

  find "$root_dir" -type f -name "*.yaml" -print0 | while IFS= read -r -d '' file; do
    local tmp_file

    tmp_file=$(mktemp)

    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ $line =~ ^([[:space:]]*image:[[:space:]]*)([\"\']?)([^\"\']+)([\"\']?)$ ]]; then
        local prefix quote value registry remainder
        prefix=${BASH_REMATCH[1]}
        quote=${BASH_REMATCH[2]}
        value=${BASH_REMATCH[3]}

        if [[ $value == */* ]]; then
          registry=${value%%/*}
          remainder=${value#*/}

          if [[ $registry == localhost || $registry == *.* || $registry == *:* ]]; then
            value=$remainder
          fi
        fi

        printf '%s%s%s%s\n' "$prefix" "$quote" "$value" "$quote" >>"$tmp_file"
      else
        printf '%s\n' "$line" >>"$tmp_file"
      fi
    done <"$file"

    mv "$tmp_file" "$file"
  done
}

# SETUP #

TEMP_DIR=$(mktemp -d)

git clone "https://github.com/nixonjoshua98/nixon-gitops.git" $TEMP_DIR

# MISC #

find "$TEMP_DIR" -type d -name ".git" -exec rm -rf {} +
find "$TEMP_DIR" -type d -name ".archived" -exec rm -rf {} +

find "$TEMP_DIR" -type d -name "documentation" -exec rm -rf {} +
find "$TEMP_DIR" -type d -name "manifests" -exec rm -rf {} +
find "$TEMP_DIR" -type d -name "scripts" -exec rm -rf {} +

find "$TEMP_DIR" -type f -name ".gitignore" -delete
find "$TEMP_DIR" -type f -name ".gitattributes" -delete

find "$TEMP_DIR" -type f -name "workspace.code-workspace" -delete

# TERRAFORM #

find "$TEMP_DIR" -type d -name ".terraform" -exec rm -rf {} +

find "$TEMP_DIR" -type f -name ".terraform.lock.hcl" -delete
find "$TEMP_DIR" -type f -name "*.tfstate.backup" -delete
find "$TEMP_DIR" -type f -name "*.tfstate" -delete
find "$TEMP_DIR" -type f -name "vars.auto.tfvars" -delete
find "$TEMP_DIR" -type f -path "*/cloud-init.yaml" -delete

# HELM #

find "$TEMP_DIR" -type d -path "*/helm/values" -exec rm -rf {} +

find "$TEMP_DIR" -type f -path "*/charts/cluster-resources/values.yaml" -delete
find "$TEMP_DIR" -type f -path "*/configuration/*-postgresql.yaml" -delete

# CONFIGURATION #

strip_registry_from_images "$TEMP_DIR/configuration"

# ANSIBLE #

find "$TEMP_DIR" -type f -path "*/ansible/inventory.ini" -delete

# K3S #

find "$TEMP_DIR" -type f -path "*/k3s/cluster.yaml" -delete

# COPY #

rm -rf "./nixon-gitops"

mv $TEMP_DIR "./nixon-gitops"
