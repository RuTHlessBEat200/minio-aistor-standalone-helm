# MinIO AIStor Standalone Helm Chart

This Helm chart deploys MinIO AIStor in standalone mode on Kubernetes.

## Features

- Standalone MinIO AIStor deployment
- Persistent storage support
- Configurable resource limits
- Ingress support for external access
- License management
- Security best practices with Pod Security Context
- Health checks (liveness and readiness probes)
- **User/access key provisioning** with policy attachment and custom inline policies
- **Bucket provisioning** with versioning, object locking, anonymous access, encryption, quota, lifecycle rules and tags

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent Volume provisioner support in the underlying infrastructure (if persistence is enabled)

## Installation

### From OCI Registry

Install the chart directly from GitHub Container Registry:

```bash
# Install latest version
helm install minio oci://ghcr.io/ruthlessbeat200/charts/minio-aistor-standalone \
  --namespace minio --create-namespace

# Install specific version
helm install minio oci://ghcr.io/ruthlessbeat200/charts/minio-aistor-standalone \
  --version 1.0.0 \
  --namespace minio --create-namespace

# Install with custom values
helm install minio oci://ghcr.io/ruthlessbeat200/charts/minio-aistor-standalone \
  --version 1.0.0 \
  -f values-custom.yaml \
  --namespace minio --create-namespace
```

### From Source

```bash
# Clone the repository
git clone https://github.com/RuTHlessBEat200/minio-aistor-standalone-helm.git
cd minio-aistor-standalone-helm

# Install with default values
helm install minio .

# Install with custom values
helm install minio . -f values-custom.yaml

# Install in a specific namespace
helm install minio . --namespace minio --create-namespace
```

### Using Custom Values

Create a `values-custom.yaml` file:

```yaml
minio:
  auth:
    rootUser: "myadmin"
    rootPassword: "mySecurePassword123"
  
  browserRedirectUrl: "https://s3-console.example.com"
  
  persistence:
    size: 100Gi
    storageClass: "fast-ssd"
  
  license:
    enabled: true
    content: "YOUR_LICENSE_CONTENT_HERE"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: s3.example.com
      paths:
        - path: /
          pathType: Prefix
          service:
            name: minio-api
            port: 9000
    - host: s3-console.example.com
      paths:
        - path: /
          pathType: Prefix
          service:
            name: minio-console
            port: 9001
  tls:
    - secretName: minio-tls
      hosts:
        - s3.example.com
        - s3-console.example.com
```

Then install:

```bash
helm install minio . -f values-custom.yaml
```

### Creating Secrets Manually

If you prefer to manage secrets separately using kubectl:

```bash
# Create MinIO credentials secret
kubectl create secret generic minio-secret \
  --from-literal=root-user=admin \
  --from-literal=root-password=yourSecurePassword123 \
  --namespace minio

# Create MinIO license secret (if you have a license)
kubectl create secret generic minio-license \
  --from-literal=minio.license='YOUR_LICENSE_JWT_TOKEN_HERE' \
  --namespace minio
```

Then configure your values file to use the existing secrets:

```yaml
minio:
  auth:
    existingSecret: "minio-secret"
    existingSecretUserKey: "root-user"
    existingSecretPasswordKey: "root-password"
  
  license:
    enabled: true
    existingSecret: "minio-license"
    existingSecretKey: "minio.license"
```

## Configuration

### MinIO Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.image.registry` | MinIO image registry | `quay.io` |
| `minio.image.repository` | MinIO image repository | `minio/aistor/minio` |
| `minio.image.tag` | MinIO image tag | `latest` |
| `minio.auth.rootUser` | MinIO root user | `admin` |
| `minio.auth.rootPassword` | MinIO root password | Random 32 chars |
| `minio.browserRedirectUrl` | Browser redirect URL | `""` |
| `minio.persistence.enabled` | Enable persistence | `true` |
| `minio.persistence.size` | Persistent volume size | `50Gi` |
| `minio.persistence.storageClass` | Storage class name | `""` |
| `minio.service.type` | Service type | `ClusterIP` |
| `minio.service.apiPort` | S3 API port | `9000` |
| `minio.service.consolePort` | Console port | `9001` |

### License Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minio.license.enabled` | Enable license | `false` |
| `minio.license.content` | License file content | `""` |
| `minio.license.existingSecret` | Existing secret with license | `""` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `""` |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | `[]` |

### User Provisioning

Users are created via a `post-install,post-upgrade` Helm hook Job after MinIO starts.

| Parameter | Description |
|-----------|-------------|
| `users[].accessKey` | Access key (username) |
| `users[].secretKey` | Secret key (password) |
| `users[].existingSecret` | Existing secret containing credentials |
| `users[].existingSecretAccessKeyKey` | Key in secret for access key (default: `access-key`) |
| `users[].existingSecretSecretKeyKey` | Key in secret for secret key (default: `secret-key`) |
| `users[].policies` | List of built-in or custom policies to attach |
| `users[].customPolicyName` | Name for an inline custom policy |
| `users[].customPolicy` | Inline JSON IAM policy |

Built-in MinIO policies: `readwrite`, `readonly`, `writeonly`, `diagnostics`, `consoleAdmin`

```yaml
users:
  # Basic user with built-in policy
  - accessKey: "myuser"
    secretKey: "mypassword"
    policies:
      - "readwrite"

  # User with credentials from existing secret
  - existingSecret: "my-user-secret"
    existingSecretAccessKeyKey: "access-key"
    existingSecretSecretKeyKey: "secret-key"
    policies:
      - "readonly"

  # User with custom inline policy
  - accessKey: "s3tables"
    secretKey: "mypassword"
    customPolicyName: "s3tables-policy"
    customPolicy: |
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": ["s3:*"],
            "Resource": [
              "arn:aws:s3:::tables/*",
              "arn:aws:s3:::tables"
            ]
          }
        ]
      }
```

### Bucket Provisioning

Buckets are created via the same provisioning Job.

| Parameter | Description |
|-----------|-------------|
| `buckets[].name` | Bucket name |
| `buckets[].type` | `basic` \| `versioned` \| `locked` |
| `buckets[].versioning.excludeFolders` | Exclude folders from versioning |
| `buckets[].versioning.excludedPrefixes` | List of prefix regex patterns to exclude from versioning |
| `buckets[].locking.mode` | Object lock mode: `compliance` \| `governance` |
| `buckets[].locking.validity` | Retention period value |
| `buckets[].locking.unit` | Retention period unit: `d` (days) \| `y` (years) |
| `buckets[].anonymous.enabled` | Enable anonymous access |
| `buckets[].anonymous.policy` | `download` \| `upload` \| `public` \| `none` |
| `buckets[].encryption.enabled` | Enable SSE-S3 encryption (requires KMS) |
| `buckets[].quota.enabled` | Enable storage quota |
| `buckets[].quota.size` | Quota size e.g. `10GiB` |
| `buckets[].lifecycle` | List of lifecycle rules |
| `buckets[].tags` | Map of key/value tags |

```yaml
buckets:
  # Basic bucket with quota and lifecycle
  - name: "mybucket"
    type: basic
    quota:
      enabled: true
      size: "50GiB"
    lifecycle:
      - id: "expire-tmp"
        prefix: "tmp/"
        expiry:
          days: 7
        noncurrentVersionExpiry:
          days: 3
    tags:
      env: production
      team: data

  # Versioned bucket excluding certain prefixes
  - name: "versioned-bucket"
    type: versioned
    versioning:
      excludeFolders: false
      excludedPrefixes:
        - "tmp/*"
        - "cache/*"

  # Locked bucket with compliance retention
  - name: "compliance-bucket"
    type: locked
    locking:
      mode: compliance
      validity: 365
      unit: d

  # Public download bucket
  - name: "public-assets"
    type: basic
    anonymous:
      enabled: true
      policy: download
```

> **Note:** `type: locked` automatically enables versioning. SSE-S3 `encryption` requires a KMS (e.g. MinIO KES / HashiCorp Vault) to be configured — the provisioning job will warn and continue if KMS is not available.

## Accessing MinIO

### Via Ingress (Recommended)

If you have ingress enabled, access MinIO at your configured domains:
- **S3 API**: `https://s3.example.com`
- **Console**: `https://s3-console.example.com`

### Port Forward (for ClusterIP service)

```bash
# S3 API
kubectl port-forward svc/<release-name>-minio-api 9000:9000 --namespace minio

# Console
kubectl port-forward svc/<release-name>-minio-console 9001:9001 --namespace minio
```

### Get Credentials

```bash
# Get root user
kubectl get secret --namespace minio <release-name>-secret -o jsonpath="{.data.root-user}" | base64 -d

# Get root password
kubectl get secret --namespace minio <release-name>-secret -o jsonpath="{.data.root-password}" | base64 -d
```

## Using MinIO Client (mc)

```bash
# Install mc
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
sudo mv mc /usr/local/bin/

# Configure alias (with ingress)
mc alias set myminio https://s3.example.com $(kubectl get secret --namespace minio <release-name>-secret -o jsonpath="{.data.root-user}" | base64 -d) $(kubectl get secret --namespace minio <release-name>-secret -o jsonpath="{.data.root-password}" | base64 -d)

# Or with port-forward
mc alias set myminio http://localhost:9000 <ROOT_USER> <ROOT_PASSWORD>

# Create a bucket
mc mb myminio/mybucket

# Upload a file
mc cp myfile.txt myminio/mybucket/

# List buckets
mc ls myminio
```

## Upgrading

```bash
# Upgrade from source
helm upgrade minio . -f values-custom.yaml

# Upgrade from OCI registry
helm upgrade minio oci://ghcr.io/ruthlessbeat200/charts/minio-aistor-standalone \
  --version 1.0.0 \
  -f values-custom.yaml

# Upgrade with specific parameters
helm upgrade minio . --set minio.resources.limits.memory=8Gi

# Force rollout restart after config changes
kubectl rollout restart statefulset <release-name>-minio -n minio
```

**Note:** Some StatefulSet fields are immutable (like serviceName, volumeClaimTemplates). If you encounter errors during upgrade, you may need to delete the StatefulSet and let Helm recreate it:

```bash
# Delete StatefulSet without deleting pods (to preserve data)
kubectl delete statefulset <release-name>-minio --cascade=orphan -n minio

# Run upgrade
helm upgrade minio . -f values-custom.yaml
```

## Uninstalling

```bash
# Uninstall the chart
helm uninstall minio --namespace minio

# Uninstall and delete PVCs (WARNING: This will delete all data!)
helm uninstall minio --namespace minio
kubectl delete pvc -l app.kubernetes.io/instance=minio -n minio
```

## Security Considerations

- Always set a strong `rootPassword` in production
- Use `existingSecret` for credentials instead of plain values
- Enable TLS via ingress for external access
- Review and adjust resource limits based on your workload
- Consider network policies to restrict access

## Troubleshooting

### Check pod status

```bash
kubectl get pods -n minio
kubectl get pods -l app.kubernetes.io/instance=minio -n minio
```

### View logs

```bash
kubectl logs <release-name>-minio-0 -n minio -f
```

### Describe pod

```bash
kubectl describe pod <release-name>-minio-0 -n minio
```

### Check PVC

```bash
kubectl get pvc -n minio
```

### Check Service Endpoints

If ingress returns 503, verify that services have endpoints:

```bash
kubectl get endpoints -n minio
kubectl get svc -n minio
```

If endpoints are empty, the service selectors may not match pod labels. Check:

```bash
# Check pod labels
kubectl get pod <release-name>-minio-0 -n minio --show-labels

# Check service selector
kubectl get svc <release-name>-minio-api -n minio -o yaml | grep -A 5 "selector:"
```

### Common Issues

**Issue: Helm warnings about unknown probe fields**
- Solution: Ensure you're using the latest chart version with proper probe configuration (without `enabled` field in the rendered YAML)

**Issue: Ingress returns 503**
- Solution: Check that service endpoints are populated. If not, recreate the pod:
  ```bash
  kubectl delete pod <release-name>-minio-0 -n minio
  ```

**Issue: StatefulSet update fails with "Forbidden" error**
- Solution: Delete the StatefulSet with `--cascade=orphan` and run `helm upgrade` again

**Issue: Pod stuck in Pending**
- Check PVC status and storage class availability
- Verify node has sufficient resources

## License

This Helm chart is open source. MinIO AIStor requires a valid license for production use.
