# DevOps Portfolio - Zineddaine Badr

Portfolio app used to practice a real DevOps delivery loop:

1. Plan work in Jira.
2. Link GitHub branches, commits, and pull requests with Jira issue keys.
3. Validate changes with GitHub Actions.
4. Publish a Docker image to GitHub Container Registry.
5. Deploy the image to a K3s staging environment.

## Current Status (BZINEDDA-141 — Done)

Staging deploy is **working end-to-end**:

```text
main push -> Publish Image (GHCR) -> Deploy Staging (self-hosted runner) -> K3s rollout
```

| Layer | Detail |
|-------|--------|
| Image | `ghcr.io/my-devops-adventure/portfolio:latest` |
| Cluster | Local K3s, namespace `portfolio-staging` |
| URL | `http://portfolio.local` (add `127.0.0.1 portfolio.local` to `/etc/hosts`) |
| Runner | Repository self-hosted runner on the K3s host |

**Lessons and mistakes from this story:** [docs/lessons-BZINEDDA-141-k3s-staging.md](./docs/lessons-BZINEDDA-141-k3s-staging.md)

## Jira And GitHub Linking

Install the official `GitHub for Jira` app in Jira Cloud, then connect the GitHub account or organization that owns this repository.

Use the Jira key everywhere:

```bash
git checkout -b BZINEDDA-107-feat-logout
git commit -m "BZINEDDA-107 feat: logout"
```

Pull request titles should follow the same pattern:

```text
BZINEDDA-107 feat: logout
```

The CI workflow checks the branch name and PR title for a Jira key. When the GitHub for Jira app is connected, Jira displays linked branches, commits, pull requests, builds, and deployments in the work item development panel.

See also: [docs/jira-github-workflow.md](./docs/jira-github-workflow.md)

## Local Development

```bash
npm install
npm run dev
```

Quality checks:

```bash
npm run lint
npm run test
npm run build
```

## Container

Build locally:

```bash
docker build -t portfolio:local .
docker run --rm -p 8080:8080 portfolio:local
```

Open `http://localhost:8080`.

## GitHub Actions

Workflows:

| Workflow | Runner | Purpose |
|----------|--------|---------|
| `.github/workflows/ci.yml` | GitHub-hosted | Jira key check, lint, test, build |
| `.github/workflows/publish-image.yml` | GitHub-hosted | Build and push to GHCR |
| `.github/workflows/deploy-staging.yml` | **Self-hosted** | Deploy to local K3s |

### Staging environment setup (one time)

1. Create GitHub environment **`staging`**.
2. Add secrets (environment scope, not repository):

| Secret | How to create |
|--------|----------------|
| `K3S_KUBECONFIG_B64` | `./scripts/setup-k3s-kubeconfig.sh` then `base64 -w 0 ~/.kube/config` |
| `GHCR_PULL_USERNAME` | Your GitHub username |
| `GHCR_PULL_TOKEN` | Classic PAT with `read:packages` |

3. Install a [repository self-hosted runner](./docs/github-self-hosted-runner.md) on the K3s machine:

```bash
RUNNER_TOKEN=token_from_github ./scripts/fix-repo-runner.sh
```

4. Merge to `main` and confirm **Publish Image** then **Deploy Staging** succeed.

Detailed guides:

- [K3s staging setup](./docs/k3s-staging-setup.md)
- [Self-hosted runner setup](./docs/github-self-hosted-runner.md)
- [Lessons learned (BZINEDDA-141)](./docs/lessons-BZINEDDA-141-k3s-staging.md)

## K3s Deployment

Manifests live in `k8s/staging`.

### Remote deploy (via GitHub Actions)

Triggered automatically after **Publish Image** on `main`, or manually via **Deploy Staging** workflow.

### Local deploy (without GHCR)

```bash
./scripts/setup-k3s-kubeconfig.sh
docker build -t ghcr.io/my-devops-adventure/portfolio:local .
./scripts/import-image-to-k3s.sh ghcr.io/my-devops-adventure/portfolio:local
IMAGE_TAG=local ./scripts/deploy-staging-local.sh
```

Add to `/etc/hosts` for ingress testing:

```text
127.0.0.1 portfolio.local
```

Verify:

```bash
kubectl get pods -n portfolio-staging
curl -s http://portfolio.local/healthz
```

## Helper Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup-k3s-kubeconfig.sh` | Fix local kubectl access to K3s |
| `scripts/import-image-to-k3s.sh` | Import Docker image into K3s |
| `scripts/deploy-staging-local.sh` | Deploy imported image to staging |
| `scripts/create-ghcr-pull-secret.sh` | GHCR pull secret for private packages |
| `scripts/fix-repo-runner.sh` | Register/repair repository runner |
| `scripts/restart-github-runner.sh` | Restart runner after broker issues |
| `scripts/validate-jira-key.sh` | Used by CI to enforce Jira keys |

## Practice Loops

| Story | Doc |
|-------|-----|
| BZINEDDA-137 — portfolio homepage | [docs/practice-loop-BZINEDDA-137.md](./docs/practice-loop-BZINEDDA-137.md) |
| BZINEDDA-141 — K3s staging deploy | [docs/lessons-BZINEDDA-141-k3s-staging.md](./docs/lessons-BZINEDDA-141-k3s-staging.md) |

Professional trace we aim for on every story:

```text
Jira work item -> branch -> commit -> PR -> CI -> image -> staging deployment -> done
```

## Next Learning Goals

- Production environment on a dedicated VM (not home LAN)
- TLS ingress and a real DNS name
- Rollback strategy and deployment health gates
- Observability (logs/metrics) for staging

We keep learning by shipping small stories through the same loop and documenting mistakes in `docs/`.
