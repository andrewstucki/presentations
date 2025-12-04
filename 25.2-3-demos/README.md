# 25.2.x and 25.3.x

Since the 25.3.x chart has not yet been released for the operator. This leverages 25.2.x which is basically a flagged version of 25.3.x with ShadowLinks still marked as experimental and disabled by default. This enables it and overrides the Redpanda cluster image in any deployments.

## 0: Setup

Run `./setup.sh`, after the initial cluster brokers get to a `Running` state, run `./fix.sh` as I've run into a rare, flaky bug still in how the bootstrap-user password gets set for clusters with SASL enabled on them. In general it shouldn't be needed, and while it's been ages since I've seen this happen in CI, I've seen it happen locally on occasion, especially when provisioning multiple redpanda clusters simultaneously (slowness?). The script just ensures everything is fully functional in the operator for the demo so things don't accidentally go bad.

## 1: Console CRDs

Demo of Console CRD configuration:

`clusterRef`-based Console deployment.

```bash
kubectl apply -f manifests/01-console-cluster-ref.yaml
kubectl port-forward deploy/ref-console -n redpanda-system 8080:8080
```

`staticConfguration`-based Console deployment.

```bash
kubectl apply -f manifests/01-console-static-source.yaml
kubectl port-forward deploy/static-console -n redpanda-system 8080:8080
```

## 2: Console Migration

Deployment should already be running from the Setup step. To show migration transformations and check the
deployment.

```bash
kubectl get console -n redpanda-system redpanda-console-enabled -o yaml
kubectl port-forward deploy/redpanda-console-enabled-console -n redpanda-system 8080:8080
```

## 3: Role CRDs

Apply and see role in cluster:

```bash
kubectl apply -f manifests/03-role.yaml
kubectl get redpandarole -n redpanda-system
kubectl exec -it -n redpanda-system redpanda-0 -c redpanda -- rpk security role list
kubectl exec -it -n redpanda-system redpanda-0 -c redpanda -- rpk security role describe admin
```

Delete and see it cleaned up:

```bash
kubectl delete -f manifests/03-role.yaml
kubectl exec -it -n redpanda-system redpanda-0 -c redpanda -- rpk security role list
```

## 4: Node Pools

Change the replica count and then:

```bash
kubectl apply -f manifests/04-nodepools.yaml
```

Check the cluster health and broker info

```bash
kubectl exec -it -n redpanda-system redpanda-nodepool-blue-0 -c redpanda -- rpk cluster health
kubectl exec -it -n redpanda-system redpanda-nodepool-blue-0 -c redpanda -- rpk cluster info
```

or 

```bash
kubectl exec -it -n redpanda-system redpanda-nodepool-green-0 -c redpanda -- rpk cluster health
kubectl exec -it -n redpanda-system redpanda-nodepool-green-0 -c redpanda -- rpk cluster info
```

## 5: Shadow Links

```bash
kubectl apply -f manifests/05-shadowlink.yaml
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic list
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk shadow status mirror
```

Publish data to source cluster and consume in shadow

```bash
kubectl exec -it -n redpanda-system redpanda-0 -c redpanda -- rpk topic produce topic --key test
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic consume topic
```

See failure to produce and delete

```bash
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic produce topic --key test
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic delete topic
```

Delete and consume still works and now produce and delete work

```bash
kubectl delete -f manifests/05-shadowlink.yaml
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic consume topic
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic produce topic --key test
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic consume topic
kubectl exec -it -n redpanda-system redpanda-shadow-0 -c redpanda -- rpk topic delete topic
```