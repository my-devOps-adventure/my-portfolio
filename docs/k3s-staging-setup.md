# K3s Staging Setup

Use this guide to prepare the cluster that receives portfolio staging deployments.

## Prerequisites

- A K3s cluster with kubectl access
- Traefik ingress enabled (default in K3s)
- A [self-hosted GitHub Actions runner](./github-self-hosted-runner.md) on the K3s machine (required for home LAN setups)

GitHub cloud runners **cannot** reach private IPs like `192.168.1.103`. If deploy fails with `dial tcp ... i/o timeout`, install the self-hosted runner — do not expose port 6443 to the public internet for learning setups.

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

For GitHub Actions with a **self-hosted runner** on the same machine, use `127.0.0.1`:

```bash
./scripts/setup-k3s-kubeconfig.sh
```

Copy kubeconfig for GitHub Actions:

```bash
base64 -w 0 ~/.kube/config
```

Store the output as the `K3S_KUBECONFIG_B64` secret in the GitHub `staging` environment.

See [github-self-hosted-runner.md](./github-self-hosted-runner.md) for full runner setup.

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

Private GHCR packages need credentials in the cluster. The deployment references `ghcr-pull-secret`.

### 1. Create a GitHub PAT

1. GitHub → **Settings → Developer settings → Personal access tokens**
2. Create a classic token with **`read:packages`**
3. The token owner must have access to `ghcr.io/my-devops-adventure/portfolio`

### 2. Add staging environment secrets

In **Settings → Environments → staging**, add:

| Secret | Value |
|--------|--------|
| `GHCR_PULL_USERNAME` | Your GitHub username |
| `GHCR_PULL_TOKEN` | PAT with `read:packages` |

The deploy workflow creates/updates `ghcr-pull-secret` in `portfolio-staging` before apply.

### 3. Create the secret manually (fix ErrImagePull now)

```bash
GHCR_PULL_USERNAME=your-github-user \
GHCR_PULL_TOKEN=ghp_xxxxxxxx \
./scripts/create-ghcr-pull-secret.sh

kubectl rollout restart deployment/portfolio -n portfolio-staging
kubectl rollout status deployment/portfolio -n portfolio-staging --timeout=180s
```

Alternative: make the GHCR package **public** (Package settings → Change visibility) and remove the pull secret requirement.
