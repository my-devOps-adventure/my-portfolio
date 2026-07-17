# GitHub Self-Hosted Runner For K3s Staging

The **Deploy Staging** workflow uses a self-hosted runner because GitHub's cloud runners cannot reach a private home-network IP like `192.168.1.103:6443`.

```text
GitHub cloud runner  --X-->  192.168.1.103:6443   (timeout)
Self-hosted runner   --OK--> 127.0.0.1:6443      (same machine as K3s)
```

CI and image publish still run on GitHub-hosted runners. Only deploy runs on your machine.

## 1. Prepare kubeconfig for the runner

On the K3s machine, use `127.0.0.1` (the runner and K3s are on the same host):

```bash
cd /path/to/my-portfolio
./scripts/setup-k3s-kubeconfig.sh
kubectl cluster-info
base64 -w 0 ~/.kube/config
```

Update the GitHub **staging** environment secret `K3S_KUBECONFIG_B64` with that output.

Also add staging environment secrets for private GHCR pulls:

| Secret | Value |
|--------|--------|
| `GHCR_PULL_USERNAME` | Your GitHub username |
| `GHCR_PULL_TOKEN` | PAT with `read:packages` |

## 2. Install a repository-level runner (recommended)

Use a **repository** runner, not an organization runner. Org runners often cause jobs to sit in **Waiting for a runner** unless runner-group repository access is configured correctly.

1. Open **my-portfolio → Settings → Actions → Runners → New self-hosted runner**
2. Choose **Linux / x64** and copy the registration token
3. On the K3s machine:

```bash
cd /path/to/my-portfolio
RUNNER_TOKEN=paste_token_here ./scripts/install-repo-runner.sh
```

The workflow uses:

```yaml
runs-on: self-hosted
```

Or with an explicit label: `runs-on: [self-hosted, k3s-staging]`

### Quick fix for runner registration

```bash
cd /path/to/my-portfolio
RUNNER_TOKEN=paste_token_here ./scripts/fix-repo-runner.sh
```

### Migrate from an org-level runner

If you previously registered at `https://github.com/my-devOps-adventure`:

1. Org → **Settings → Actions → Runners** → remove `k3s-staging-runner`
2. Install again with `./scripts/install-repo-runner.sh` using a **repository** token

## 3. Runner prerequisites

The K3s host needs:

- `kubectl` (from K3s or standalone)
- Network access to `broker.actions.githubusercontent.com` and `ghcr.io`

Install kubectl if needed:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## 4. Test the deploy workflow

1. Confirm the runner appears as **Idle** under **repository** Settings → Actions → Runners
2. Run **Deploy Staging** manually (workflow_dispatch)
3. The job log should show `Runner name: bzinedda` (or your runner name) and pass `kubectl cluster-info`

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Waiting for a runner to pick up this job` | Use a **repository** runner; restart with `./scripts/restart-github-runner.sh` |
| `Runner connect error: broker.actions.githubusercontent.com` | Network issue — restart runner; check firewall/DNS |
| `dial tcp 127.0.0.1:6443: connection refused` | Job ran on GitHub cloud, not self-hosted — fix runner pickup first |
| `InvalidImageName` | Image name must be lowercase — merge latest deploy workflow |
| `ImagePullBackOff` / `not found` | Check image tag (`:latest` exists); add GHCR secrets if private |
| `Missing K3S_KUBECONFIG_B64` | Add secret to **Environments → staging** |

### Runner not picking up jobs

1. **Restart the runner**:

```bash
./scripts/restart-github-runner.sh
```

Confirm logs show `Listening for Jobs`.

2. **Verify runner is repository-level**

Check **my-portfolio → Settings → Actions → Runners**, not only the org runners page.

3. **Cancel stuck workflow runs**

Actions → cancel old **Deploy Staging** runs stuck in *Queued* or *In progress*.

4. **Reinstall with a fresh token**

Tokens are one-time use:

```bash
RUNNER_TOKEN=new_token ./scripts/install-repo-runner.sh
```

## Security notes

- The self-hosted runner executes workflow code from your repo. Use it only for trusted repos/branches.
- For production, prefer a dedicated VM with K3s and a locked-down runner.
