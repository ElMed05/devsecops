# devsecops
# DevSecOps Kubernetes Lab

Nachvollziehbarer Aufbau einer Kubernetes-basierten DevSecOps-Plattform auf
Proxmox. Jede Plattformschicht erhält einen eigenen IaC-/GitOps-Bereich.

## Aktuelle Struktur

```text
infra/
└── opentofu/
    └── proxmox/             Proxmox-VM-Provisionierung
        ├── modules/         Wiederverwendbare IaC-Module
        └── environments/    Umgebungsspezifische Konfiguration
```

Der Einstieg und die benötigten Werte sind in
[`infra/opentofu/proxmox/README.md`](infra/opentofu/proxmox/README.md) beschrieben.
