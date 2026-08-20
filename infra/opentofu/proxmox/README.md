# Proxmox-VMs mit OpenTofu

Diese Schicht erzeugt die VMs für das Kubernetes-Lab. Sie installiert Kubernetes
noch nicht; Konfiguration und Bootstrap folgen in einer getrennten Schicht.

Auf dem aktuellen Proxmox-Laptop ist das Lab bewusst auf zwei Kubernetes-VMs
begrenzt:

| VM | vCPU | RAM | Systemdisk |
| --- | ---: | ---: | ---: |
| `k8s-control-plane` | 2 | 2048 MiB | 32 GiB |
| `k8s-worker-01` | 2 | 2560 MiB | 40 GiB |

Damit belegen die beiden Kubernetes-VMs zusammen 4608 MiB. Gegenüber den bei
der letzten Prüfung verfügbaren rund 5,7 GiB verbleibt ungefähr 1,2 GiB Reserve
für Proxmox; der vorhandene Swap ist nur ein Notfallpuffer und keine reguläre
Kapazität für Kubernetes-Workloads.

Die optionale Plattform-VM bleibt standardmäßig deaktiviert, da GitLab und
Harbor die vorhandenen 12 GiB Host-RAM zusammen mit `prestino-prod` und dem
Kubernetes-Cluster überlasten würden.

## Struktur

```text
proxmox/
├── modules/proxmox-vm/     Wiederverwendbare Definition einer Cloud-Init-VM
└── environments/lab/       Konkrete VMs, Netzwerk und Größen des Labs
```

## Voraussetzungen

- OpenTofu >= 1.9
- Proxmox VE mit API-Token
- API-Rechte zum Herunterladen von Images und Erstellen/Klonen von VMs
- Öffentlicher SSH-Schlüssel
- Freie VM-IDs und IP-Adressen

Das Ubuntu-24.04-Cloud-Init-Template mit VM-ID `9000` wird von dieser Umgebung
selbst aus dem offiziellen Ubuntu-Cloud-Image erzeugt. Der QEMU Guest Agent ist
im Basis-Image nicht enthalten. Deshalb wartet OpenTofu beim ersten Bootstrap
nicht auf ihn; Installation und Aktivierung erfolgen später per Ansible über die
bekannten statischen IP-Adressen.

## Vorbereitung

```bash
cd infra/opentofu/proxmox/environments/lab
cp terraform.tfvars.example terraform.tfvars
```

Passe anschließend Endpoint, Node, Template-ID, Netzwerk, IP-Adressen und den
SSH-Schlüssel in `terraform.tfvars` an. Die echte Datei wird von Git ignoriert.
Die Kubernetes-VMs beziehen ihre Adressen zunächst per DHCP, weil kein Zugriff
auf die DHCP-Pool- und Reservierungseinstellungen des Routers besteht. Ein von
Ein von OpenTofu verwaltetes Cloud-Init-Snippet installiert den QEMU Guest Agent,
damit Proxmox die vergebenen IP-Adressen melden kann. Eindeutige Hostnamen und
weitere Gastkonfiguration werden anschließend mit Ansible verwaltet. Für einen dauerhaften Cluster
sollten später DHCP-Reservierungen oder ein eigenes kontrolliertes VM-Netz
eingerichtet werden.

Das Token nur in der Shell oder in einem Secret Store setzen:

```bash
export PROXMOX_VE_API_TOKEN='opentofu@pve!iac=REPLACE_WITH_SECRET'
```

## Sicherer Ablauf

```bash
tofu init
tofu fmt -check -recursive
tofu validate
tofu plan -out=lab.tfplan
```

Prüfe den Plan vollständig. `tofu apply lab.tfplan` erst danach bewusst und
manuell ausführen. Dieses Repository führt keinen Apply automatisch aus.

## State

Der Einstieg verwendet lokalen State, der von Git ignoriert wird. Vor Teamarbeit
oder produktiver Nutzung sollte ein verschlüsseltes Remote Backend mit Locking
konfiguriert werden. State und Plan-Dateien sind als vertraulich zu behandeln.
