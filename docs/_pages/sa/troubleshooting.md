---
title: "Troubleshooting: Common Errors"
permalink: /sa/troubleshooting/
layout: single
classes: wide
---

## Common Errors and Solutions

This page documents common errors you might encounter during deployment and how to resolve them.

---

### 1. Helm Installation Failed - Name Already In Use

**Error Message:**
```
Error: installation failed

  with helm_release.user_openvscode["arena-american12"],
  on openvscode.tf line 47, in resource "helm_release" "user_openvscode":
  47: resource "helm_release" "user_openvscode" {

cannot re-use a name that is still in use
```

**Cause:**  
This error occurs when Terraform/Terragrunt tries to install a Helm chart, but a release with the same name already exists in the Kubernetes cluster. This can happen if:
- A previous deployment failed midway
- Resources were not properly cleaned up
- The Terraform state is out of sync with the actual cluster state

**Solution:**

1. **List all Helm releases** to identify the problematic release:
   ```bash
   helm list --all-namespaces
   ```
   
   Look for the release name mentioned in the error (e.g., `arena-american12`).

2. **Uninstall the existing release:**
   ```bash
   helm uninstall <release-name> -n <namespace>
   ```
   
   For example:
   ```bash
   helm uninstall arena-american12 -n default
   ```
   
   > 💡 **Note:** Replace `<release-name>` with the actual release name and `<namespace>` with the appropriate namespace (often `default` unless specified otherwise).

3. **Verify the release is removed:**
   ```bash
   helm list --all-namespaces
   ```

4. **Re-run the Terraform/Terragrunt apply:**
   ```bash
   terragrunt apply --all
   ```

**Alternative Solution:**  
If you need to import the existing Helm release into Terraform state instead of uninstalling it:
```bash
terragrunt import --working-dir=eks-cluster 'helm_release.user_openvscode["arena-american12"]' default/arena-american12
```

---

### 2. Nginx 50x Bad Gateway / Service Unavailable Error

**Error Message:**
```
502 Bad Gateway
```
or
```
503 Service Unavailable
```
when accessing any of the workshop URLs (e.g. `https://<user>.<domain>/...`).

**Cause:**
The `mdb-nginx` pod can occasionally get stuck serving stale configuration or environment variables. This happens because the Deployment's rolling-restart trigger (a checksum annotation) does not always cover every value that can change, so `terraform apply` can update the underlying Helm values/ConfigMaps without Kubernetes automatically restarting the pod to pick them up. The fix is to manually delete the pod so Kubernetes recreates it with the current configuration.

**Solution:**

1. **Identify the `mdb-nginx` pod:**
   ```bash
   kubectl get pods -n default | grep nginx
   ```

2. **Delete the `mdb-nginx` pod** (replace with the actual pod name from the previous step):
   ```bash
   kubectl delete pod mdb-nginx-<pod-hash> -n default
   ```

3. **Verify a new pod comes up and is `Running` / `1/1 Ready`:**
   ```bash
   kubectl get pods -n default | grep nginx
   ```

   > 💡 **Note:** The Deployment (and its Pod Disruption Budget) will automatically create a replacement pod within a few seconds. There is no need to re-run `terraform apply` or `terragrunt apply` for this — deleting the pod is sufficient.

4. **(Optional) Check the new pod's logs if the error persists:**
   ```bash
   kubectl logs -n default <new-pod-name>
   kubectl describe pod -n default <new-pod-name>
   ```

---

### 3. Atlas Credentials Rejected - Error Getting Credentials for Provider

**Error Message:**
```
│ Error: Error getting credentials for provider
│ 
│   with provider["registry.terraform.io/mongodb/mongodbatlas"],
│   on main.tf line 16, in provider "mongodbatlas":
│   16: provider "mongodbatlas" {
│ 
│ Service Account credentials (starting with 'mdb_sa') were provided in
│ public_key/private_key which are meant for Programmatic Access Keys. Please
│ use client_id and client_secret arguments for Service Account
│ authentication
```

**Cause:**
Atlas has two kinds of credentials, and each has its own pair of fields in `config.yaml`:

- **Programmatic API Key** → `mongodb.public_key` + `mongodb.private_key`
- **Service Account** (values starting with `mdb_sa_id_` / `mdb_sa_sk_`) → `mongodb.client_id` + `mongodb.client_secret`

This error means Service Account values ended up in the API key fields. The Atlas provider rejects that combination outright.

**Solution:**

1. **Move the credentials into the matching fields** in your customer's `config.yaml`:
   ```yaml
   mongodb:
     client_id: "mdb_sa_id_..."
     client_secret: "mdb_sa_sk_..."
   ```
   Remove (or comment out) `public_key` and `private_key` so only one pair is set.

2. **Re-run the apply:**
   ```bash
   terragrunt apply --all
   ```

> 💡 **Note:** Current versions of the module detect `mdb_sa_...` values wherever they are and authenticate correctly, so this error usually means the checkout predates that support. Keeping each credential type in its own pair works on every version.

**Related error:** if the two fields hold credentials of *different* types (for example an API key public key with a Service Account secret), Atlas returns an authentication failure instead. Make sure both values come from the same credential.

---

## Getting Help

If you encounter an error not listed here, please:
1. Check the Terraform/Terragrunt logs for detailed error messages
2. Verify your AWS credentials and permissions
3. Ensure all prerequisites are met (see the Setup page)
4. Contact the team for assistance

---

