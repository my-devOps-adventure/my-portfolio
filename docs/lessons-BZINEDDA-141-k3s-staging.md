# Lessons Learned: BZINEDDA-141 — Deploy To K3s Staging

Story: **Deploy to K3s staging**  
Status: **Done** — full pipeline verified on 2026-07-17.

This document captures what we built, what broke, and what to avoid in the next lessons.

## What We Achieved

End-to-end delivery loop for this repository:

```text
Jira (BZINEDDA-141)
  -> branch / commit / PR
  -> CI (lint, test, build)
  -> Publish Image (GHCR)
  -> Deploy Staging (self-hosted runner + K3s)
  -> portfolio pods Running in portfolio-staging
```

### Infrastructure in place

| Component | Location / detail |
|-----------|---------------------|
| K3s cluster | Local machine (`bzinedda`), Traefik ingress |
| Staging namespace | `portfolio-staging` |
| Ingress host | `http://portfolio.local` |
| Container registry | `ghcr.io/my-devops-adventure/portfolio:latest` |
| GitHub environment | `staging` with kubeconfig + GHCR secrets |
| Self-hosted runner | Repository-level runner on the K3s host |
| Manifests | `k8s/staging/` (deployment, service, ingress) |

### Helper scripts added

| Script | Purpose |
|--------|---------|
| `scripts/setup-k3s-kubeconfig.sh` | Copy K3s admin config to `~/.kube/config` |
| `scripts/import-image-to-k3s.sh` | Load a local Docker image into K3s |
| `scripts/deploy-staging-local.sh` | Deploy without GHCR (local image) |
| `scripts/create-ghcr-pull-secret.sh` | Create GHCR pull secret in the cluster |
| `scripts/install-repo-runner.sh` | Register a repository self-hosted runner |
| `scripts/fix-repo-runner.sh` | Re-register runner with correct repo + labels |
| `scripts/restart-github-runner.sh` | Restart runner after broker disconnect |

## Mistakes We Hit (And How To Prevent Them)

### 1. GitHub cloud runner cannot reach home K3s

**Symptom:** `dial tcp 192.168.x.x:6443: i/o timeout`

**Cause:** `runs-on: ubuntu-latest` tries to reach a private LAN IP.

**Prevention:** Use a **self-hosted runner on the K3s machine**. Do not expose port 6443 to the public internet for learning setups.

---

### 2. Kubeconfig with `127.0.0.1` on a cloud runner

**Symptom:** `dial tcp 127.0.0.1:6443: connection refused`

**Cause:** Cloud runner's localhost is not your K3s host.

**Prevention:** Self-hosted runner on the same machine as K3s + kubeconfig with `127.0.0.1`.

---

### 3. Org runner vs repository runner

**Symptom:** `Waiting for a runner to pick up this job...` (minutes/hours)

**Cause:** Runner registered at **org** level (`my-devOps-adventure`) while the workflow runs in **my-portfolio**. Local `.runner` had org URL; repo runner in GitHub UI was a separate registration.

**Prevention:**

- Register at **my-portfolio → Settings → Actions → Runners**
- Use `./scripts/fix-repo-runner.sh` with a fresh repo token
- Verify `.runner` contains `"gitHubUrl": ".../my-portfolio"`
- Install as a **systemd service** (`sudo ./svc.sh install`), not foreground `./run.sh`

---

### 4. Missing runner label `k3s-staging`

**Symptom:** Job requests `self-hosted, k3s-staging` but runner only has `self-hosted, Linux, X64`.

**Cause:** Skipped "additional labels" during `./config.sh`.

**Prevention:** Pass `--labels k3s-staging` or use `runs-on: self-hosted` when you have only one repo runner.

---

### 5. K3s kubeconfig permission denied

**Symptom:** `error loading config file "/etc/rancher/k3s/k3s.yaml": permission denied`

**Cause:** K3s stores admin credentials root-only; kubectl defaults to that path.

**Prevention:** Run `./scripts/setup-k3s-kubeconfig.sh` once; export `KUBECONFIG=~/.kube/config`.

---

### 6. Docker image name casing

**Symptom:** `InvalidImageName` in Kubernetes

**Cause:** `my-devOps-adventure` (mixed case) in image reference. Docker/K8s require lowercase.

**Prevention:** Always use `ghcr.io/my-devops-adventure/portfolio`. Lowercase `repository_owner` in workflows.

---

### 7. `sudo k3s ctr images import <(docker save ...)`

**Symptom:** `ctr: open /proc/self/fd/18: no such file or directory`

**Cause:** `sudo` cannot read shell process substitution.

**Prevention:** Use `./scripts/import-image-to-k3s.sh` (saves to a temp file first).

---

### 8. Local deploy + `imagePullPolicy: Always`

**Symptom:** `ImagePullBackOff` for `:local` tag

**Cause:** K3s tries to pull from GHCR even when the image is imported locally.

**Prevention:** `./scripts/deploy-staging-local.sh` sets `imagePullPolicy: Never` for local tags.

---

### 9. Private GHCR without pull secret

**Symptom:** `ErrImagePull` / `not found` or auth errors

**Cause:** K3s cannot authenticate to pull private packages.

**Prevention:** Add staging secrets `GHCR_PULL_USERNAME` + `GHCR_PULL_TOKEN` (PAT with `read:packages`), or make the package public.

---

### 10. Deploy tag vs publish tag mismatch

**Symptom:** `failed to resolve reference ... not found` during rollout

**Cause:** Deploy used full commit SHA (`bcd9919611d29...`) but GHCR had `:latest` and short SHA only.

**Prevention:** Deploy uses `:latest` after `workflow_run` from Publish Image. Publish also tags `format=long` SHA for explicit pin deploys.

---

### 11. Runner broker disconnect

**Symptom:** Runner shows Idle in GitHub but jobs queue; logs show `broker.actions.githubusercontent.com` timeouts.

**Prevention:** `./scripts/restart-github-runner.sh` and ensure stable network access.

## Quick Reference: Staging Secrets

GitHub **Settings → Environments → staging**:

| Secret | Value |
|--------|--------|
| `K3S_KUBECONFIG_B64` | `base64 -w 0 ~/.kube/config` (with `127.0.0.1`) |
| `GHCR_PULL_USERNAME` | GitHub username that owns the PAT |
| `GHCR_PULL_TOKEN` | Classic PAT with `read:packages` |

## Verify Staging Is Healthy

```bash
kubectl get pods -n portfolio-staging
curl -s http://portfolio.local/healthz   # requires /etc/hosts entry
```

GitHub Actions: **Deploy Staging** should show `Runner name: bzinedda` (or your runner) and pass rollout.

## What's Next (Keep Learning)

Possible follow-up stories:

- **Production environment** with required reviewers and a cloud VM for K3s
- **Helm or Kustomize overlays** for staging vs production
- **Monitoring** (Prometheus/Grafana or simple health alerts)
- **TLS ingress** with cert-manager instead of `portfolio.local`
- **Automated rollback** on failed rollout
- **Jira deployment panel** linking GitHub Environment URL to staging

Each lesson should update this docs folder and keep the Jira → GitHub trace intact.
