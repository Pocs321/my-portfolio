@echo off
REM
REM AWS CLI Deployment Script for Static Website (Windows Batch)
REM Reads configuration from config.yaml
REM
REM Usage: deploy.bat
REM
REM Prerequisites:
REM   - AWS CLI installed: https://aws.amazon.com/cli/
REM   - Run: aws configure
REM   - Or set environment variables for AWS credentials
REM

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   Static Website Deployment Script
echo ========================================
echo.

set SCRIPT_DIR=%~dp0
set CONFIG_FILE=%SCRIPT_DIR%config.yaml

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo ERROR: config.yaml not found at %CONFIG_FILE%
    exit /b 1
)

REM Parse config.yaml using findstr (simple parsing)
for /f "tokens=2 delims=: " %%a in ('findstr /r "^  region:" "%CONFIG_FILE%"') do set AWS_REGION=%%a
for /f "tokens=2 delims=: " %%a in ('findstr /r "bucket_name:" "%CONFIG_FILE%"') do set S3_BUCKET=%%a
for /f "tokens=2 delims=: " %%a in ('findstr /r "distribution_id:" "%CONFIG_FILE%"') do set CLOUDFRONT_ID=%%a
for /f "tokens=2 delims=: " %%a in ('findstr /r "source_folder:" "%CONFIG_FILE%"') do set SOURCE_FOLDER=%%a
for /f "tokens=2 delims=: " %%a in ('findstr /r "delete_extra_files:" "%CONFIG_FILE%"') do set DELETE_EXTRA=%%a
for /f "tokens=2 delims=: " %%a in ('findstr /r "cache_control_max_age:" "%CONFIG_FILE%"') do set CACHE_AGE=%%a

REM Set defaults if empty
if "%AWS_REGION%"=="" set AWS_REGION=ap-southeast-1
if "%S3_BUCKET%"=="" set S3_BUCKET=your-portfolio-site-2026
if "%CLOUDFRONT_ID%"=="" set CLOUDFRONT_ID=E1ABCDE2FGHIJ
if "%SOURCE_FOLDER%"=="" set SOURCE_FOLDER=src
if "%DELETE_EXTRA%"=="" set DELETE_EXTRA=true
if "%CACHE_AGE%"=="" set CACHE_AGE=86400

REM Build delete flag
set DELETE_FLAG=
if "%DELETE_EXTRA%"=="true" set DELETE_FLAG=--delete

echo Configuration loaded from config.yaml:
echo   Region:         %AWS_REGION%
echo   S3 Bucket:      %S3_BUCKET%
echo   CloudFront ID:  %CLOUDFRONT_ID%
echo   Source Folder:  %SOURCE_FOLDER%
echo   Delete Extra:   %DELETE_EXTRA%
echo   Cache Age:      %CACHE_AGE% seconds
echo.

REM Check AWS CLI is installed
where aws >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: AWS CLI is not installed
    echo Install from: https://aws.amazon.com/cli/
    exit /b 1
)

REM Check AWS credentials are configured
aws sts get-caller-identity >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: AWS credentials not configured
    echo.
    echo Run one of these:
    echo   aws configure                    REM Interactive setup
    echo   set AWS_ACCESS_KEY_ID=xxx        REM Or set environment variables
    echo   set AWS_SECRET_ACCESS_KEY=xxx
    echo   set AWS_REGION=%AWS_REGION%
    exit /b 1
)

for /f "tokens=*" %%a in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT=%%a
echo AWS credentials verified (Account: %AWS_ACCOUNT%)
echo.

REM Check if source folder exists
if not exist "%SCRIPT_DIR%%SOURCE_FOLDER%" (
    echo ERROR: Source folder not found: %SCRIPT_DIR%%SOURCE_FOLDER%
    exit /b 1
)

echo ========================================
echo   Step 1: Sync files to S3
echo ========================================
echo.

aws s3 sync "%SCRIPT_DIR%%SOURCE_FOLDER%/" "s3://%S3_BUCKET%/" ^
    %DELETE_FLAG% ^
    --cache-control "max-age=%CACHE_AGE%" ^
    --acl public-read

if %errorlevel% neq 0 (
    echo ERROR: Failed to sync files to S3
    exit /b 1
)

echo.
echo Files synced successfully!
echo.

echo ========================================
echo   Step 2: Invalidate CloudFront Cache
echo ========================================
echo.

for /f "delims=" %%i in ('aws cloudfront create-invalidation --distribution-id "%CLOUDFRONT_ID%" --paths "/*" --output json') do set INVALIDATION_OUTPUT=%%i

echo %INVALIDATION_OUTPUT% | findstr /r "\"Id\"" >nul
if %errorlevel% equ 0 (
    echo CloudFront invalidation started!
    echo This typically takes 1-2 minutes to complete.
) else (
    echo WARNING: Could not parse invalidation response
)

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo   S3 Website:     http://%S3_BUCKET%.s3-website-%AWS_REGION%.amazonaws.com
echo   CloudFront URL: https://%CLOUDFRONT_ID%.cloudfront.net
echo.
echo Note: CloudFront cache invalidation is in progress.
echo       Your changes will be live in 1-2 minutes.
echo.

endlocal
