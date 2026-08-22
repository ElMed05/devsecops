# Demo application security walkthrough

This guide documents the complete setup and validation of the demo
application, its Istio Gateway API route and its Calico-enforced Kubernetes
NetworkPolicies.

The goal is to allow only the traffic that the application needs:

```text
Browser
  -> Istio Gateway
  -> HTTPRoute
  -> Service/demo-web:80
  -> Pod/demo-web:8080

Pod/demo-web
  -> CoreDNS:53/UDP,TCP
```

All other newly initiated ingress and egress connections are denied.

## Resulting resources

```text
platform/applications/demo/
├── README.md
├── deployment.yaml
├── httproute.yaml
├── kustomization.yaml
├── namespace.yaml
├── networkpolicy-allow-dns.yaml
├── networkpolicy-allow-gateway.yaml
├── networkpolicy-default-deny.yaml
└── service.yaml
```

## Prerequisites

- Kubernetes nodes are `Ready`.
- Calico is installed and healthy.
- Istio manages `Gateway/lab-gateway`.
- Argo CD manages `Application/lab-root`.
- `demo.lab.local` resolves to a Kubernetes node.
- Commands are executed from the repository root.

Set the lab kubeconfig for the current shell:

```bash
cd ~/devsecops

export KUBECONFIG="$HOME/devsecops/configuration/ansible/artifacts/admin.conf"
```

Verify the starting state:

```bash
kubectl get nodes
kubectl -n demo get pods,service,httproute -o wide
kubectl -n argocd get application lab-root -o wide
```

Expected state:

```text
k8s-control-plane   Ready
k8s-worker-01       Ready
demo-web            Running
lab-root            Synced   Healthy
```

## 1. Discover labels for policy selectors

NetworkPolicies select namespaces and pods through labels. Read the actual
cluster labels before writing a policy.

### Namespace labels

```bash
kubectl get namespace demo istio-ingress kube-system --show-labels
```

Required labels:

```text
kubernetes.io/metadata.name=demo
kubernetes.io/metadata.name=istio-ingress
kubernetes.io/metadata.name=kube-system
```

### Istio Gateway pod labels

```bash
kubectl -n istio-ingress get pods --show-labels
```

The gateway is selected through:

```text
gateway.networking.k8s.io/gateway-name=lab-gateway
```

### CoreDNS pod labels

```bash
kubectl -n kube-system get pods \
  -l k8s-app=kube-dns \
  --show-labels
```

CoreDNS is selected through:

```text
k8s-app=kube-dns
```

## 2. Deny traffic by default

File: `networkpolicy-default-deny.yaml`

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

`podSelector: {}` selects every pod in the `demo` namespace. Because the
policy has no `ingress` or `egress` rules, all traffic is denied unless another
policy explicitly allows it.

Validate the individual file without storing it:

```bash
kubectl apply \
  --dry-run=server \
  --namespace demo \
  -f platform/applications/demo/networkpolicy-default-deny.yaml
```

## 3. Allow ingress only from the Istio Gateway

File: `networkpolicy-allow-gateway.yaml`

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-from-istio-gateway
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: demo-web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: istio-ingress
          podSelector:
            matchLabels:
              gateway.networking.k8s.io/gateway-name: lab-gateway
      ports:
        - protocol: TCP
          port: 8080
```

The `namespaceSelector` and `podSelector` are part of the same `from` item.
They therefore form a logical AND: the source must be the `lab-gateway` pod
and it must be in the `istio-ingress` namespace.

The Kubernetes Service listens on port 80 and forwards to the pod's target
port 8080. NetworkPolicy therefore permits TCP port 8080.

Validate the file:

```bash
kubectl apply \
  --dry-run=server \
  --namespace demo \
  -f platform/applications/demo/networkpolicy-allow-gateway.yaml
```

## 4. Allow DNS egress only to CoreDNS

File: `networkpolicy-allow-dns.yaml`

```yaml
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-coredns
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: demo-web
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

UDP 53 handles normal DNS queries. TCP 53 is also required for larger replies
and fallback cases. The two selectors form a logical AND and prevent port 53
access to arbitrary pods.

Validate the file:

```bash
kubectl apply \
  --dry-run=server \
  --namespace demo \
  -f platform/applications/demo/networkpolicy-allow-dns.yaml
```

## 5. Add all policies to Kustomize atomically

The relevant part of `kustomization.yaml` is:

```yaml
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - httproute.yaml
  - networkpolicy-default-deny.yaml
  - networkpolicy-allow-gateway.yaml
  - networkpolicy-allow-dns.yaml
```

All three policies must be added in the same commit. Synchronizing only the
default-deny policy would interrupt application access.

Render the complete cluster configuration locally:

```bash
kubectl kustomize platform/clusters/lab \
  > /tmp/demo-with-networkpolicies.yaml
```

List the rendered resources:

```bash
grep -E '^(kind:|  name:)' /tmp/demo-with-networkpolicies.yaml
```

Expected resource count: seven.

Validate the complete rendering without persisting anything:

```bash
kubectl apply \
  --dry-run=server \
  -f /tmp/demo-with-networkpolicies.yaml
```

Verify formatting:

```bash
git diff --check
```

## 6. Commit and push the policy set

Stage only the intended files:

```bash
git add \
  platform/applications/demo/kustomization.yaml \
  platform/applications/demo/networkpolicy-default-deny.yaml \
  platform/applications/demo/networkpolicy-allow-gateway.yaml \
  platform/applications/demo/networkpolicy-allow-dns.yaml
```

Review the Git index:

```bash
git diff --cached --check
git diff --cached --stat
git diff --cached --name-status
git status --short
```

Create the commit:

```bash
git commit -m "Enforce network isolation for demo application"
```

Push it:

```bash
git push origin main
```

## 7. Review the Argo CD diff before synchronization

Refresh only the comparison cache:

```bash
kubectl -n argocd annotate application lab-root \
  argocd.argoproj.io/refresh=hard \
  --overwrite
```

Read the application status:

```bash
kubectl -n argocd get application lab-root -o wide
```

List every managed resource and its sync status:

```bash
kubectl -n argocd get application lab-root \
  -o jsonpath='{range .status.resources[*]}{.kind}{"/"}{.namespace}{"/"}{.name}{" status="}{.status}{" health="}{.health.status}{"\n"}{end}'
```

Before synchronization, only these resources should be `OutOfSync`:

```text
NetworkPolicy/demo/allow-egress-to-coredns
NetworkPolicy/demo/allow-ingress-from-istio-gateway
NetworkPolicy/demo/default-deny-all
```

Synchronize them together in the Argo CD UI. Keep `Prune`, `Force` and
`Apply only` disabled.

Verify the result:

```bash
kubectl -n argocd get application lab-root -o wide
kubectl -n demo get networkpolicy
kubectl -n demo get pods -o wide
```

Expected application state:

```text
Synced   Healthy
```

## 8. Positive test: Gateway ingress remains allowed

```bash
curl --insecure \
  --resolve demo.lab.local:30959:192.168.0.251 \
  --output /dev/null \
  --write-out 'HTTP %{http_code}\n' \
  https://demo.lab.local:30959
```

Expected result:

```text
HTTP 200
```

## 9. Negative test: another pod cannot access the demo

Create `/tmp/netpol-deny-test.yaml` outside the repository:

```yaml
---
apiVersion: v1
kind: Pod
metadata:
  name: netpol-deny-test
  namespace: default
spec:
  automountServiceAccountToken: false
  restartPolicy: Never
  containers:
    - name: client
      image: busybox:1.37.0
      command:
        - sh
        - -c
      args:
        - |
          wget -T 5 -qO- http://demo-web.demo.svc.cluster.local
          result=$?
          echo "wget_exit=${result}"
          exit 0
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
        readOnlyRootFilesystem: true
        runAsNonRoot: true
        runAsUser: 65532
        seccompProfile:
          type: RuntimeDefault
```

Run the test:

```bash
kubectl apply -f /tmp/netpol-deny-test.yaml

kubectl -n default wait \
  --for=jsonpath='{.status.phase}'=Succeeded \
  pod/netpol-deny-test \
  --timeout=90s

kubectl -n default logs netpol-deny-test
```

Expected result:

```text
wget: download timed out
wget_exit=1
```

Remove the temporary pod:

```bash
kubectl -n default delete pod netpol-deny-test
kubectl -n default get pod netpol-deny-test
```

The final command should return `NotFound`.

## 10. Positive test: DNS egress is allowed

```bash
kubectl -n demo exec deployment/demo-web -- \
  nslookup kubernetes.default.svc.cluster.local
```

Expected DNS server and result:

```text
Server:  10.96.0.10
Name:    kubernetes.default.svc.cluster.local
Address: 10.96.0.1
```

## 11. Negative test: other egress is denied

```bash
kubectl -n demo exec deployment/demo-web -- \
  sh -c '
    wget --no-check-certificate \
      -T 5 \
      -qO- \
      https://kubernetes.default.svc.cluster.local:443

    result=$?
    echo "wget_exit=${result}"
    exit 0
  '
```

Expected result:

```text
wget: download timed out
wget_exit=1
```

NetworkPolicies are stateful. Response packets for the allowed incoming
Gateway connection remain permitted even though new egress connections from
the demo pod are denied.

## Traffic matrix

| Source | Destination | Protocol | Result |
|---|---|---:|---|
| Istio `lab-gateway` | `demo-web` | TCP 8080 | Allowed |
| Arbitrary pod | `demo-web` | TCP 8080 | Denied |
| `demo-web` | CoreDNS | UDP/TCP 53 | Allowed |
| `demo-web` | Kubernetes API | TCP 443 | Denied |
| `demo-web` | Other destinations | Any | Denied |

## Troubleshooting

### The external URL times out

Check the route, gateway and policy selectors:

```bash
kubectl -n demo get httproute demo-web -o yaml
kubectl -n istio-ingress get gateway lab-gateway
kubectl -n istio-ingress get pods --show-labels
kubectl -n demo describe networkpolicy allow-ingress-from-istio-gateway
```

### DNS fails inside the demo pod

Check the actual CoreDNS labels and endpoints:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns --show-labels
kubectl -n kube-system get service kube-dns
kubectl -n demo describe networkpolicy allow-egress-to-coredns
```

### Argo CD remains OutOfSync

```bash
kubectl -n argocd annotate application lab-root \
  argocd.argoproj.io/refresh=hard \
  --overwrite

kubectl -n argocd get application lab-root -o wide
```

Always inspect the resource diff before starting another sync.
