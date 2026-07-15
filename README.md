# DevOps Portfolio - Zineddaine Badr.

Portfolio app used to practice a real DevOps delivery loop:

1. Plan work in Jira.
2. Link GitHub branches, commits, and pull requests with Jira issue keys.
3. Validate changes with GitHub Actions.
4. Publish a Docker image to GitHub Container Registry.
5. Deploy the image to a K3s staging environment.

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

- `.github/workflows/ci.yml`: validates Jira key convention, lints, tests, and builds.
- `.github/workflows/publish-image.yml`: publishes images to GitHub Container Registry.
- `.github/workflows/deploy-staging.yml`: deploys to K3s staging.

Required GitHub repository setup:

1. Create an environment named `staging`.
2. Add environment secret `K3S_KUBECONFIG_B64`.
3. Make sure the K3s cluster can pull `ghcr.io/<your-github-owner>/portfolio` images.

Create the kubeconfig secret:

```bash
base64 -w 0 ~/.kube/config
```

Store the output as `K3S_KUBECONFIG_B64`.

For production later, create a `production` environment with required reviewers.

## K3s Deployment

Manifests live in `k8s/staging`.

Apply manually:

```bash
kubectl apply -k k8s/staging
kubectl rollout status deployment/portfolio --namespace portfolio-staging
```

If you use the default ingress host, add this to `/etc/hosts` for local testing:

```text
127.0.0.1 portfolio.local
```

## First Practice Loop

Use story **`BZINEDDA-137`** (`feat: portfolio homepage`):

1. Move `BZINEDDA-137` to `todo` in Jira.
2. Create branch `BZINEDDA-137-feat-homepage`.
3. Commit with `BZINEDDA-137 feat: portfolio homepage`.
4. Open PR `BZINEDDA-137 feat: portfolio homepage`.
5. Wait for CI.
6. Merge to `main`.
7. Confirm the image publish and staging deployment.
8. Move `BZINEDDA-137` to `done`.

This creates the professional trace:

```text
Jira work item -> branch -> commit -> PR -> CI -> image -> staging deployment
```
