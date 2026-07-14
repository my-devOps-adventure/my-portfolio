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

Copy kubeconfig for GitHub Actions:

```bash
base64 -w 0 ~/.kube/config
```

Store the output as the `K3S_KUBECONFIG_B64` secret in the GitHub `staging` environment.

## Apply Staging Manifests

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
