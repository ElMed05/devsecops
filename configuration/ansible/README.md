# Gastkonfiguration mit Ansible

OpenTofu verwaltet VM-Lifecycle und virtuelle Hardware. Ansible verwaltet das
Betriebssystem innerhalb der VMs.

## Rollen

```text
roles/
├── node_identity/             Hostname und Cloud-Init-Schutz
├── kubernetes_prerequisites/  Pakete, Kernelmodule, sysctl und Swap
├── container_runtime/         containerd mit systemd-cgroups
├── kubernetes_packages/       kubelet, kubeadm und kubectl
├── kubernetes_control_plane/  kubeadm-init und kubeconfig
├── cni_calico/                Calico CNI und NetworkPolicy
├── kubernetes_worker/         kurzlebiger kubeadm-Join und Worker-Label
├── helm/                      gepinnte Helm-Installation
├── argocd_bootstrap/           initialer GitOps-Controller
└── argocd_repository/          privates Git-Repository und Root-Application
```

```bash
cd configuration/ansible
ansible-playbook playbooks/prepare-kubernetes-nodes.yml --check --diff
ansible-playbook playbooks/prepare-kubernetes-nodes.yml --diff
```

Cluster-Initialisierung, Worker-Join und CNI werden bewusst in getrennten Rollen
umgesetzt, nachdem diese Basisschicht verifiziert wurde.

## Cluster-Bootstrap

```bash
ansible-playbook playbooks/bootstrap-kubernetes.yml --check --diff
ansible-playbook playbooks/bootstrap-kubernetes.yml --diff
```

Die lokale Datei `artifacts/admin.conf` enthält Cluster-Administrator-Zugang und
wird deshalb von Git ignoriert. Join-Tokens werden nur kurzlebig erzeugt und in
Ansible nicht ausgegeben.

Die DHCP-Adressen im Inventory müssen nach einer Adressänderung anhand der
OpenTofu-Ausgaben beziehungsweise des QEMU Guest Agents aktualisiert werden.

## Plattform-Werkzeuge

Helm wird nur auf der Control Plane installiert und verwendet dort die bereits
vorhandene Kubernetes-Admin-Konfiguration.

```bash
ansible-playbook playbooks/install-platform-tools.yml --check --diff
ansible-playbook playbooks/install-platform-tools.yml --diff
```

## GitOps-Bootstrap

Argo CD wird über ein fest gepinntes und SHA-256-geprüftes Helm-Chart als
interner `ClusterIP`-Service installiert. Dex bleibt bis zur späteren
Keycloak-Integration deaktiviert.

```bash
ansible-playbook playbooks/bootstrap-gitops.yml --check --diff
ansible-playbook playbooks/bootstrap-gitops.yml --diff
```

Die lokale Weboberfläche kann ohne öffentliche Service-IP über einen Tunnel
erreicht werden:

```bash
kubectl --kubeconfig artifacts/admin.conf -n argocd port-forward svc/argocd-server 8080:443
```

Der private read-only Deploy-Key wird lokal unter
`artifacts/argocd-devsecops-deploy-key` erwartet. Das gesamte
`artifacts/`-Verzeichnis wird von Git ignoriert. Der Key wird bei der
Konfiguration nur temporär auf die Control Plane kopiert und anschließend
entfernt.

## Gateway

Gateway API und Istio stellen Argo CD per TLS über einen Kubernetes-NodePort
bereit. Die Adresse wird am Ende des Playbooks ausgegeben.

```bash
ansible-playbook playbooks/install-gateway.yml --diff
```

Auf dem Controller muss `argocd.lab.local` auf die IP eines Kubernetes-Nodes
zeigen. Das Zertifikat ist für das lokale Lab selbstsigniert.

```text
192.168.0.251 argocd.lab.local
```

Aktueller HTTPS-Zugang im Lab: `https://argocd.lab.local:30959`.
