#!/usr/bin/env bash

set -e

# argocd login \
#     --port-forward \
#     --insecure \
#     --plaintext \
#     --port-forward-namespace argocd

APP_NAMES=$(
    argocd app list \
        -o name \
        --port-forward \
        --insecure \
        --plaintext \
        --port-forward-namespace argocd
)

argocd app sync $APP_NAMES \
    --port-forward \
    --insecure \
    --plaintext \
    --port-forward-namespace argocd