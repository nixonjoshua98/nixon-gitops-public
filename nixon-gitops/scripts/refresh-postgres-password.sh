#!/usr/bin/env bash

set -euo pipefail

CONTEXT="k3s-cluster-admin"

ENVIRONMENTS=(
    "untitledproject:devtest"
)

for entry in "${ENVIRONMENTS[@]}"; do
    IFS=":" read -r PROJECT ENV_NAME <<< "$entry"

    NAMESPACE="${PROJECT}-${ENV_NAME}"

    PG_NAME="${PROJECT}-postgresql-${ENV_NAME}"

    SECRET_NAME="${PG_NAME}-postgres"
    
    GUID="$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)"

    kubectl label secret "$SECRET_NAME" cnpg.io/reload="$GUID" \
        --namespace "$NAMESPACE" \
        --overwrite
done