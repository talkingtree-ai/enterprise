---
sidebar_position: 3
---

# Accessing Docker Images

This guide will walk you through the process of accessing and downloading Docker images from our Amazon ECR (Elastic Container Registry) repositories.

:::tip
For convenience, we provide ready-to-use setup scripts in the [`examples`](https://github.com/talkingtree-ai/enterprise/tree/main/examples) folder. These scripts implement the authentication process described below and can be run directly after configuring your credentials.
:::

## Prerequisites

1. An AWS account
2. AWS CLI installed on your machine
3. Docker installed on your machine
4. Your AWS account ID (needed for access)

## Getting Your AWS Account ID

To find your AWS account ID:

1. Log into the AWS Management Console
2. Click on your account name in the top right corner
3. Your 12-digit account ID will be displayed in the dropdown menu
4. Alternatively, you can run this command in AWS CLI:
   ```bash
   aws sts get-caller-identity --query Account --output text
   ```

## Requesting Access

1. Send your AWS account ID to our support team
2. We will add your account to the allowed principals list
3. We will provide you with the role ARN that you'll need to assume

## Setting Up AWS CLI

1. Install AWS CLI if you haven't already:
   ```bash
   # For macOS
   brew install awscli

   # For Ubuntu/Debian
   sudo apt-get install awscli

   # For Windows
   # Download the installer from AWS website
   ```

2. Configure AWS CLI with your credentials:
   ```bash
   aws configure
   ```
   You'll be prompted to enter:
   - AWS Access Key ID
   - AWS Secret Access Key
   - Default region (use `us-east-1`)
   - Default output format (use `json`)

## Authenticating with ECR

1. First, assume the read-only role we provided:
   ```bash
   aws sts assume-role --role-arn <ROLE_ARN> --role-session-name "ECR-Access"
   ```

2. From the output, set these environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID=<AccessKeyId>
   export AWS_SECRET_ACCESS_KEY=<SecretAccessKey>
   export AWS_SESSION_TOKEN=<SessionToken>
   ```

3. Get an ECR login token:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>
   ```

## Available Images

We maintain the following Docker images:

- `redaction-api`: Redaction service API
- `frontend`: Web frontend application
- `main-api`: Main backend API
- `word-extension`: Microsoft Word extension

## Pulling Images

To pull an image, use the following command:

```bash
docker pull ${ACCOUNT_ID_VENDOR}.dkr.ecr.${AWS_REGION}.amazonaws.com/<IMAGE_NAME>:<TAG>
```

For example:
```bash
docker pull ${ACCOUNT_ID_VENDOR}.dkr.ecr.${AWS_REGION}.amazonaws.com/frontend:latest
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Ensure you've properly assumed the role with the correct EXTERNAL_ID
   - Verify your AWS CLI is configured with a valid profile
   - Check that the temporary credentials are properly exported

2. **Permission Denied**
   - Confirm you're using the correct repository URL
   - Verify you have the latest ROLE_ARN and EXTERNAL_ID
   - Check that your AWS session hasn't expired (credentials last 1 hour by default)

3. **Image Not Found**
   - Verify the image name and tag
   - Ensure you're using the correct repository URL
   - Check if the image exists in the repository

### Getting Help

If you encounter any issues:
1. Check the error message carefully
2. Verify all steps in this guide were followed
3. Contact our support team with:
   - The exact error message
   - The command you were trying to run
   - Your AWS account ID

## Security Notes

- Never share your AWS credentials
- The temporary credentials expire after 1 hour by default
- Use the read-only role only for pulling images
- Report any security concerns immediately

## Best Practices

1. Always pull specific versions rather than using `latest`
2. Keep your Docker images updated
3. Use private networks when possible
4. Implement proper access controls in your environment
5. Regularly clean up unused images to save space

## Support

For additional help or to report issues:
- Email: connect@talkingtree.app
- Please have your AWS account ID available
- Provide detailed error messages and steps to reproduce
