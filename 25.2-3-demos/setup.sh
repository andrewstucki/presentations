#!/usr/bin/env bash

k3d cluster create --image docker.io/rancher/k3s:v1.29.1-k3s1 --agents=3
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.12.2 --set installCRDs=true
helm install operator -n redpanda-system --create-namespace redpanda/operator --set="crds.enabled=true" --set="crds.experimental=true" --set="additionalCmdFlags[0]=--enable-shadowlinks" --set="additionalCmdFlags[1]=--enable-v2-nodepools"
kubectl apply -f manifests/base