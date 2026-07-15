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

## 2. Install the runner (one time)

1. Open GitHub: **Repository → Settings → Actions → Runners → New self-hosted runner**.
2. Choose **Linux** and **x64**.
3. On the K3s machine, run the commands GitHub shows. Example:

```bash
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download (check GitHub UI for the latest version URL)
curl -o actions-runner-linux-x64-2.322.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.322.0/actions-runner-linux-x64-2.322.0.tar.gz
tar xzf ./actions-runner-linux-x64-*.tar.gz

# Configure — paste the token from the GitHub UI when prompted
./config.sh --url https://github.com/my-devOps-adventure/my-portfolio \
  --token YOUR_TOKEN_FROM_GITHUB \
  --labels k3s-staging \
  --name k3s-staging-runner

# Install and start as a service (survives reboot)
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

The label `k3s-staging` must match the workflow `runs-on` labels.

## 3. Runner prerequisites

The K3s host needs:

- `kubectl` (from K3s or standalone)
- Network access to pull from `ghcr.io` (for staging deploys)

Install kubectl on the runner user if needed:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## 4. Test the deploy workflow

1. Confirm the runner appears as **Idle** in GitHub → Settings → Actions → Runners.
2. Run **Deploy Staging** manually (workflow_dispatch) or merge to `main` and wait for **Publish Image** to finish.
3. The job should pick up the self-hosted runner and pass `kubectl cluster-info`.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `dial tcp 192.168.x.x:6443: i/o timeout` on `ubuntu-latest` | Expected — switch workflow to self-hosted runner (already done in repo) |
| **Waiting for a runner to pick up this job** (6+ min) | See [Runner not picking up jobs](#runner-not-picking-up-jobs) below |
| Job queued, no runner | Runner offline — run `sudo ./svc.sh status` in `~/actions-runner` |
| `Missing K3S_KUBECONFIG_B64` | Add secret to **Environments → staging**, not repository secrets |
| `ImagePullBackOff` after deploy | Add `GHCR_PULL_USERNAME` + `GHCR_PULL_TOKEN` secrets, or make GHCR package public |

### Runner not picking up jobs

1. **Restart the runner service** (broker can disconnect after a failed job):

```bash
cd ~/Desktop/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh start
sudo ./svc.sh status
```

Confirm the log shows `Listening for Jobs`.

2. **Allow org runners on the repository**

Repository → **Settings → Actions → General** → enable use of organization runners (wording varies).

3. **Runner group must include this repo**

Org → **Settings → Actions → Runner groups → Default → Repository access** → **All repositories** (or add `my-portfolio`).

4. **Cancel stuck workflow runs**

Actions → cancel any old **Deploy Staging** runs still marked *Queued* or *In progress*.

5. **Prefer a repository-level runner** (simplest for one repo)

Repo → **Settings → Actions → Runners → New self-hosted runner** (use a fresh token; tokens are one-time use).

When configuring, use `--labels k3s-staging` and press **Enter** for the runner group (Default).

## Security notes

- The self-hosted runner can run code from your repo when workflows trigger. Use it only for trusted repos/branches.
- For production, prefer a dedicated VM with K3s and a locked-down runner, not your daily driver laptop.
