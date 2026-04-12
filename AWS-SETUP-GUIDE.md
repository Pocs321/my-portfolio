# AWS Console Setup Guide — Static Site CI/CD Pipeline

Follow these steps in the AWS Management Console to set up the infrastructure.

---

## Step 1: Create an S3 Bucket

1. Go to **S3** → **Create bucket**
2. **Bucket name**: `your-portfolio-site-2026` (must be globally unique)
3. **Region**: Choose your preferred region (e.g., `ap-southeast-1`)
4. **Uncheck** "Block all public access" → Acknowledge the warning
5. Click **Create bucket**

### Enable Static Website Hosting

1. Open your bucket → **Properties** tab
2. Scroll to **Static website hosting** → **Edit**
3. **Enable** static website hosting
4. **Index document**: `index.html`
5. **Save changes**
6. Note the **Bucket website endpoint** URL displayed

### Add Bucket Policy (Public Read Access)

1. Go to **Permissions** tab → **Bucket policy** → **Edit**
2. Paste this policy (replace `your-portfolio-site-2026` with your bucket name):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::your-portfolio-site-2026/*"
        }
    ]
}
```

3. **Save changes**

---

## Step 2: Create a CloudFront Distribution

1. Go to **CloudFront** → **Create distribution**
2. **Origin domain**: Select your S3 bucket from the dropdown
   - IMPORTANT: Choose the **S3 website endpoint** format:
     `your-portfolio-site-2026.s3-website-<region>.amazonaws.com`
   - Do NOT use the S3 REST API endpoint
3. **Origin access**: Select **Public** (since we set up public bucket policy)
4. **Viewer protocol policy**: **Redirect HTTP to HTTPS**
5. **Default root object**: `index.html`
6. **Price class**: Choose "Use only North America and Europe" (cheapest)
7. Click **Create distribution**
8. Wait for status to change to **Deployed** (takes 5-10 minutes)
9. Note your **Distribution domain name** (e.g., `d1234abcdef.cloudfront.net`)
10. Note your **Distribution ID** (e.g., `E1ABCDE2FGHIJ`) — needed for GitHub Actions

---

## Step 3: Create an IAM User for GitHub Actions

1. Go to **IAM** → **Users** → **Create user**
2. **User name**: `github-actions-deploy`
3. Click **Next**
4. Select **Attach policies directly**
5. Click **Create policy** (opens new tab):

### Create Custom Policy

1. Switch to **JSON** editor
2. Paste this policy (replace `your-portfolio-site-2026` with your bucket name, and `E1ABCDE2FGHIJ` with your CloudFront Distribution ID):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3DeployAccess",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::your-portfolio-site-2026",
                "arn:aws:s3:::your-portfolio-site-2026/*"
            ]
        },
        {
            "Sid": "CloudFrontInvalidation",
            "Effect": "Allow",
            "Action": "cloudfront:CreateInvalidation",
            "Resource": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/E1ABCDE2FGHIJ"
        }
    ]
}
```

3. **Policy name**: `github-actions-s3-cloudfront-deploy`
4. **Create policy**

### Back to Create User

1. Go back to the user creation tab → **Refresh** the policy list
2. Search for `github-actions-s3-cloudfront-deploy` → Select it
3. Click **Next** → **Create user**

### Create Access Keys

1. Open the user `github-actions-deploy`
2. Go to **Security credentials** tab
3. **Create access key**
4. Select **Third-party service** → Check the confirmation → **Next**
5. **Create access key**
6. **SAVE** the Access Key ID and Secret Access Key — you won't see the secret again!

---

## Step 4: Set Up GitHub Repository Secrets

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add these 4 secrets:

| Secret Name                    | Value                                         |
| ------------------------------ | --------------------------------------------- |
| `AWS_ACCESS_KEY_ID`            | Your IAM user's Access Key ID                 |
| `AWS_SECRET_ACCESS_KEY`        | Your IAM user's Secret Access Key             |
| `AWS_REGION`                   | Your S3 bucket region (e.g., `ap-southeast-1`)|
| `S3_BUCKET_NAME`              | Your bucket name (e.g., `your-portfolio-site-2026`) |
| `CLOUDFRONT_DISTRIBUTION_ID`  | Your CloudFront Distribution ID               |

---

## Step 5: Deploy!

1. Push your code to the `main` branch:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: static portfolio site with CI/CD"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

2. Go to your repo → **Actions** tab to watch the deployment
3. Once complete, visit your CloudFront URL: `https://d1234abcdef.cloudfront.net`

---

## Architecture Diagram

```
Developer pushes code
        │
        ▼
   GitHub (main branch)
        │
        ▼
   GitHub Actions Workflow
   ┌────────────────────────┐
   │ 1. Checkout code       │
   │ 2. Configure AWS creds │
   │ 3. Sync to S3          │
   │ 4. Invalidate CF cache │
   └────────────────────────┘
        │                │
        ▼                ▼
   S3 Bucket        CloudFront
   (static files)   (CDN/HTTPS)
                         │
                         ▼
                    Users access
                    website via
                    CloudFront URL
```

---

## Troubleshooting

- **403 Forbidden from S3**: Check the bucket policy is correctly set to public read
- **GitHub Actions fails on AWS credentials**: Double-check all 5 secrets are set correctly
- **CloudFront shows old content**: The invalidation may take 1-2 minutes, or check that the invalidation step ran successfully
- **Website not loading**: Make sure `index.html` is in the root of the S3 bucket (inside `src/` folder gets synced to bucket root)
