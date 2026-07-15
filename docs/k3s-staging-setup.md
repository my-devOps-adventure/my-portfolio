# K3s Staging Setup

Use this guide to prepare the cluster that receives portfolio staging deployments.

## Prerequisites

- A K3s cluster with kubectl access
- Traefik ingress enabled (default in K3s)
- Network access from GitHub Actions runners to the Kubernetes API

## Install K3s Locally (Optional)

```bash
curl -sfL https://get.k3s.io | sh -
sudo kubectl get nodes
```

## Fix Local Kubeconfig (Common Pipeline Blocker)

K3s stores admin credentials in `/etc/rancher/k3s/k3s.yaml` with root-only permissions. If `kubectl` fails with `permission denied`, copy the file into your home directory:

```bash
./scripts/setup-k3s-kubeconfig.sh
kubectl get nodes
```

For GitHub Actions, the kubeconfig server must be reachable from the public internet (not `127.0.0.1`). Use your K3s machine IP or hostname:

```bash
./scripts/setup-k3s-kubeconfig.sh 192.168.1.50
```

Open port `6443` on the K3s host firewall if GitHub runners cannot reach the API.

Copy kubeconfig for GitHub Actions:

```bash
base64 -w 0 ~/.kube/config
```

Store the output as the `K3S_KUBECONFIG_B64` secret in the GitHub `staging` environment.

GitHub UI path:

1. Repository Settings -> Environments -> staging.
2. Environment secrets -> Add secret.
3. Name: `K3S_KUBECONFIG_B64`.
4. Value: output of `base64 -w 0 ~/.kube/config`.

The deployment workflow validates the secret first, writes kubeconfig to `$HOME/.kube/config`, and checks cluster access using `kubectl cluster-info` before apply.

## Apply Staging Manifests

Local deploy (same logic as the GitHub workflow, but uses the image already loaded in K3s):

1. Fix kubeconfig once (so you do not need `sudo kubectl`):

```bash
./scripts/setup-k3s-kubeconfig.sh
kubectl get nodes
```

2. Build, import, and deploy:

```bash
docker build -t ghcr.io/my-devops-adventure/portfolio:local .
./scripts/import-image-to-k3s.sh ghcr.io/my-devops-adventure/portfolio:local
IMAGE_TAG=local ./scripts/deploy-staging-local.sh
```

The local deploy script sets `imagePullPolicy: Never` so K3s uses the imported image instead of pulling from GHCR.

Do not use `sudo k3s ctr images import <(docker save ...)` — sudo cannot read shell process-substitution file descriptors.

Manual apply:

```bash
kubectl apply -k k8s/staging
kubectl rollout status deployment/portfolio --namespace portfolio-staging
```

The deployment uses placeholder image `ghcr.io/example/portfolio:latest`. GitHub Actions replaces it with `ghcr.io/<owner>/portfolio:<tag>` during deploy.

## Local Ingress Testing

Add to `/etc/hosts`:

```text
127.0.0.1 portfolio.local
```

Then open `http://portfolio.local`.

## GHCR Pull Access

If the container package is private, create an image pull secret in `portfolio-staging` and reference it in the deployment spec.

For learning, making the GHCR package public is the simplest path.
