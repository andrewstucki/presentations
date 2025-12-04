#!/usr/bin/env bash

# this is to fix up the operator password in case the bootstrap user password synchronization fails

kubectl exec -it -n redpanda-system redpanda-0 -c redpanda -- rpk security user update kubernetes-controller --new-password $(kubectl get secret -n redpanda-system redpanda-bootstrap-user -o json | jq .data.password -r | base64 -d) --mechanism SCRAM-SHA-256
kubectl exec -it -n redpanda-system redpanda-console-enabled-0 -c redpanda -- rpk security user update kubernetes-controller --new-password $(kubectl get secret -n redpanda-system redpanda-console-enabled-bootstrap-user -o json | jq .data.password -r | base64 -d) --mechanism SCRAM-SHA-256
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk security user update kubernetes-controller --new-password $(kubectl get secret -n redpanda-system redpanda-shadow-bootstrap-user -o json | jq .data.password -r | base64 -d) --mechanism SCRAM-SHA-256