# Deployment Guide

This project supports two deployment methods:

1. **GitHub Actions** (automated CI/CD)
2. **AWS CLI** (manual deployment)

Both methods read configuration from `config.yaml`.

---

## Configuration

Edit `config.yaml` with your AWS resources:

```yaml
aws:
  region: ap-southeast-1
  s3:
    bucket_name: your-portfolio-site-2026
  cloudfront:
    distribution_id: E1ABCDE2FGHIJ
```

### Required GitHub Secrets (for GitHub Actions)

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `AWS_REGION` | AWS region (e.g., `ap-southeast-1`) |
| `S3_BUCKET_NAME` | S3 bucket name |
| `CLOUDFRONT_DISTRIBUTION_ID` | CloudFront distribution ID |

---

## Method 1: GitHub Actions (Automated)

Every push to `main` branch triggers automatic deployment:

```bash
git add .
git commit -m "Update website content"
git push origin main
```

Watch deployment progress: **GitHub Repo → Actions tab**

---

## Method 2: AWS CLI (Manual)

### Prerequisites

1. **Install AWS CLI**
   - Download: https://aws.amazon.com/cli/
   - Or use package manager:
     ```bash
     # macOS
     brew install awscli

     # Windows (with winget)
     winget install Amazon.AWSCLI
     ```

2. **Configure AWS credentials**
   ```bash
   aws configure
   ```
   Enter:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region name: `ap-southeast-1`
   - Default output format: `json`

### Deploy

**On Linux/macOS (Git Bash, WSL):**
```bash
chmod +x deploy.sh
./deploy.sh
```

**On Windows:**
```cmd
deploy.bat
```

---

## Troubleshooting

### AWS CLI not found
```bash
# Verify installation
aws --version

# If not found, add to PATH or reinstall
```

### Credentials error
```bash
# Clear and reconfigure
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_REGION=ap-southeast-1
```

### S3 bucket not found
- Ensure bucket name in `config.yaml` matches exactly
- Bucket names must be globally unique across AWS

### CloudFront invalidation fails
- Check distribution ID is correct (starts with `E`)
- Verify IAM user has `cloudfront:CreateInvalidation` permission

### 403 Forbidden from website
- Check S3 bucket policy allows public read
- Verify static website hosting is enabled on the bucket

---

## Architecture

```
┌─────────────┐
│   GitHub    │
│   (code)    │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ GitHub Actions  │  OR  ┌──────────────┐
│ (on push)       │       │ AWS CLI      │
└──────┬──────────┘       │ (manual)     │
       │                  └──────┬───────┘
       └──────────┬──────────────┘
                  ▼
         ┌────────────────┐
         │   S3 Bucket    │
         │ (static files) │
         └───────┬────────┘
                 │
                 ▼
         ┌────────────────┐
         │  CloudFront    │
         │     (CDN)      │
         └───────┬────────┘
                 │
                 ▼
         ┌────────────────┐
         │   End Users    │
         └────────────────┘
```
