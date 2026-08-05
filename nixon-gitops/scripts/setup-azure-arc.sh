
# kind create cluster --name arc-test
# kubectl config use-context kind-arc-test

az config set extension.use_dynamic_install=yes_without_prompt

kubectl config use-context k3s-cluster-admin

az connectedk8s connect \
    --name k3s-cluster-290726 \
    --resource-group rg-v1-shared \
    --location uksouth \
    --enable-oidc-issuer \
    --enable-workload-identity

# /etc/rancher/k3s/config.yaml
#   kube-apiserver-arg:  
#       - "service-account-issuer=${OIDC_ISSUER}"
#       - "service-account-max-token-expiration=24h"