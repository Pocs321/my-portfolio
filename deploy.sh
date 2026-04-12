#!/bin/bash
#
# AWS CLI Deployment Script for Static Website
# Reads configuration from config.yaml
#
# Usage: ./deploy.sh
#
# Prerequisites:
#   - AWS CLI installed and configured
#   - Run: aws configure
#   - Or set environment variables:
#       export AWS_ACCESS_KEY_ID=xxx
#       export AWS_SECRET_ACCESS_KEY=xxx
#       export AWS_REGION=ap-southeast-1
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

echo ""
echo "========================================"
echo "  Static Website Deployment Script"
echo "========================================"
echo ""

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: config.yaml not found at ${CONFIG_FILE}${NC}"
    exit 1
fi

# Parse config.yaml (requires yq or simple grep/sed)
# Using simple parsing - install yq for better YAML parsing:
#   brew install yq (macOS)
#   pip install yq (Linux/Windows with WSL)

if command -v yq &> /dev/null; then
    # Use yq for proper YAML parsing
    AWS_REGION=$(yq -r '.aws.region' "$CONFIG_FILE")
    S3_BUCKET=$(yq -r '.aws.s3.bucket_name' "$CONFIG_FILE")
    CLOUDFRONT_ID=$(yq -r '.aws.cloudfront.distribution_id' "$CONFIG_FILE")
    SOURCE_FOLDER=$(yq -r '.deployment.source_folder' "$CONFIG_FILE")
    DELETE_EXTRA=$(yq -r '.deployment.delete_extra_files' "$CONFIG_FILE")
    CACHE_AGE=$(yq -r '.deployment.cache_control_max_age' "$CONFIG_FILE")
else
    # Fallback: simple grep parsing
    echo -e "${YELLOW}Note: Install 'yq' for better YAML parsing (optional)${NC}"
    AWS_REGION=$(grep -A1 "^aws:" "$CONFIG_FILE" | grep "region:" | sed 's/.*: //')
    S3_BUCKET=$(grep -A2 "s3:" "$CONFIG_FILE" | grep "bucket_name:" | sed 's/.*: //')
    CLOUDFRONT_ID=$(grep -A2 "cloudfront:" "$CONFIG_FILE" | grep "distribution_id:" | sed 's/.*: //')
    SOURCE_FOLDER=$(grep "source_folder:" "$CONFIG_FILE" | sed 's/.*: //')
    DELETE_EXTRA=$(grep "delete_extra_files:" "$CONFIG_FILE" | sed 's/.*: //')
    CACHE_AGE=$(grep "cache_control_max_age:" "$CONFIG_FILE" | sed 's/.*: //')
fi

# Set defaults if empty
AWS_REGION=${AWS_REGION:-ap-southeast-1}
S3_BUCKET=${S3_BUCKET:-your-portfolio-site-2026}
CLOUDFRONT_ID=${CLOUDFRONT_ID:-E1ABCDE2FGHIJ}
SOURCE_FOLDER=${SOURCE_FOLDER:-src}
DELETE_EXTRA=${DELETE_EXTRA:-true}
CACHE_AGE=${CACHE_AGE:-86400}

# Build delete flag
DELETE_FLAG=""
if [ "$DELETE_EXTRA" = "true" ]; then
    DELETE_FLAG="--delete"
fi

echo -e "${GREEN}Configuration loaded from config.yaml:${NC}"
echo "  Region:         ${AWS_REGION}"
echo "  S3 Bucket:      ${S3_BUCKET}"
echo "  CloudFront ID:  ${CLOUDFRONT_ID}"
echo "  Source Folder:  ${SOURCE_FOLDER}"
echo "  Delete Extra:   ${DELETE_EXTRA}"
echo "  Cache Age:      ${CACHE_AGE} seconds"
echo ""

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    echo "Install from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo ""
    echo "Run one of these:"
    echo "  aws configure                    # Interactive setup"
    echo "  export AWS_ACCESS_KEY_ID=xxx     # Or set environment variables"
    echo "  export AWS_SECRET_ACCESS_KEY=xxx"
    echo "  export AWS_REGION=${AWS_REGION}"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS credentials verified${NC} (Account: ${AWS_ACCOUNT})"
echo ""

# Check if source folder exists
if [ ! -d "${SCRIPT_DIR}/${SOURCE_FOLDER}" ]; then
    echo -e "${RED}Error: Source folder not found: ${SCRIPT_DIR}/${SOURCE_FOLDER}${NC}"
    exit 1
fi

echo "========================================"
echo "  Step 1: Sync files to S3"
echo "========================================"
echo ""

aws s3 sync "${SCRIPT_DIR}/${SOURCE_FOLDER}/" "s3://${S3_BUCKET}/" \
    ${DELETE_FLAG} \
    --cache-control "max-age=${CACHE_AGE}" \
    --acl public-read

echo ""
echo -e "${GREEN}Files synced successfully!${NC}"
echo ""

echo "========================================"
echo "  Step 2: Invalidate CloudFront Cache"
echo "========================================"
echo ""

INVALIDATION_OUTPUT=$(aws cloudfront create-invalidation \
    --distribution-id "${CLOUDFRONT_ID}" \
    --paths "/*" \
    --output json)

INVALIDATION_ID=$(echo "$INVALIDATION_OUTPUT" | grep -o '"Id": "[^"]*"' | cut -d'"' -f4)
INVALIDATION_STATUS=$(echo "$INVALIDATION_OUTPUT" | grep -o '"Status": "[^"]*"' | cut -d'"' -f4)

echo "Invalidation ID: ${INVALIDATION_ID}"
echo "Status: ${INVALIDATION_STATUS}"
echo ""
echo -e "${GREEN}CloudFront invalidation started!${NC}"
echo "This typically takes 1-2 minutes to complete."
echo ""

# Get S3 website endpoint
S3_ENDPOINT="http://${S3_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
CLOUDFRONT_URL="https://${CLOUDFRONT_ID}.cloudfront.net"

echo "========================================"
echo "  Deployment Complete!"
echo "========================================"
echo ""
echo "  S3 Website:     ${S3_ENDPOINT}"
echo "  CloudFront URL: ${CLOUDFRONT_URL}"
echo ""
echo "Note: CloudFront cache invalidation is in progress."
echo "      Your changes will be live in 1-2 minutes."
echo ""
