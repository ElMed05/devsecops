# GitOps-Plattform

Dieses Verzeichnis ist die deklarative Quelle für Kubernetes-Ressourcen, die
später durch Argo CD synchronisiert werden. Bis ein extern erreichbares
Git-Repository konfiguriert ist, werden die Ressourcen nur lokal gerendert und
validiert.

## Struktur

```text
platform/
├── bootstrap/root-application/  Argo-CD-Einstiegspunkt
├── clusters/lab/                gewünschter Zustand des Lab-Clusters
├── infrastructure/              Plattformkomponenten
└── applications/demo/           kleine Testanwendung
```

## Lokale Validierung

```bash
kubectl kustomize platform/clusters/lab
```

Die Datei `bootstrap/root-application/application.yaml.example` wird erst nach
dem Eintragen der echten Git-Repository-URL aktiviert.
