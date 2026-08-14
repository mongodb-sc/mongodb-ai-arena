# Arena Terragrunt - MongoDB AI Arena Infrastructure

Terragrunt configurations for deploying MongoDB AI Arena workshop environments.

## 📖 Full Documentation

For complete setup instructions, visit: **[mongoarena.com/sa/overview](https://mongoarena.com/sa/overview/)**

## 💬 Support

Need help? Join **[#ai-arena](https://mongodb.enterprise.slack.com/archives/C08JJKV3T0A)** on Slack

---

## Prerequisites

Before deploying, ensure you have the following installed and configured:

- **Terragrunt** and **Terraform** installed
- **AWS CLI** configured with appropriate access
- **Python 3.x** with venv enabled (required for database population scripts)

To set up Python virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate
```

---

## Quick Start

### 1. Setup Your Customer Folder

```bash
# Copy the airbnb folder and rename it with your customer name
cp -r airbnb your-customer-name
cd your-customer-name
```

### 2. Configure

Edit `config.yaml` with your customer details, MongoDB Atlas credentials, and AWS settings.

**✅ Validate Your Configuration (Optional)**

Before deploying, validate your `config.yaml` to ensure it's properly formatted:

```bash
python3 validate_config.py config.yaml
```

### 3. Deploy

```bash
# Login to AWS SSO
aws sso login --profile Solution-Architects.User-979559056307

# Navigate to your customer folder
cd ./utils/arena-terragrunt/
cd your-customer-name

# Initialize
terragrunt init --all --upgrade

# (Optional) To run `plan --all`, apply atlas-cluster first:
terragrunt apply --working-dir=atlas-cluster
terragrunt plan --all

# Apply (deploy)
terragrunt apply --all
```

### 4. Destroy

```bash
# ⚠️ Important: Download user_leaderboard data first!
terragrunt destroy --all
```

## Common Commands

```bash
# Apply specific module
terragrunt apply --working-dir=atlas-cluster

# Import existing Atlas project
terragrunt import --working-dir=atlas-cluster mongodbatlas_project.project <project_id>

# Taint specific module
terragrunt run -- taint 'helm_release.airbnb_arena_nginx' --working-dir=eks-cluster

# Destroy specific module
terragrunt destroy --working-dir=eks-cluster
```

## Troubleshooting

**Helm error: `cannot re-use a name that is still in use`** — a release with that name already exists in the cluster but is not in Terraform state. Uninstall it and re-apply:

```bash
helm list --all-namespaces
helm uninstall -n default <release-name>
terragrunt apply --all
```

**Kubectl context management** — list, check, and switch Kubernetes contexts:

```bash
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <context-name>
kubectl config delete-context <context-name>
```

**Kubectl pod management** — inspect and manage pods:

```bash
kubectl get pods -n default -o wide
kubectl logs <pod-name> -n default
kubectl delete pod <pod-name> -n default
```

