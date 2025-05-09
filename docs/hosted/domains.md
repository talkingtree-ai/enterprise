---
sidebar_position: 1
---
# Domain Setup

:::caution Important
Before proceeding with domain setup, you must complete the [SSO configuration](../sso.md). The domain setup process requires your OIDC environment variables to be properly configured for authentication to work correctly.
:::

When setting up your domain for our hosted services, you have two options:

## Option 1: Managed Domain (Recommended)

We can handle the entire domain setup process for you. Simply provide us with your desired subdomain name, and we'll generate a subdomain under our domain (e.g., `your-company.talkingtree.app`). This is the simplest approach as we handle all the technical configuration.

To proceed with this option:
1. Contact our support team
2. Provide your desired subdomain name
3. Share your [OIDC environment variables](../sso.md#oidc) from the SSO setup
4. We'll set up the domain and provide you with the URL

## Option 2: Self-Managed Domain

If you prefer to use your own domain, you'll need to configure your DNS records to point to our services. Before proceeding, please contact our support team to receive the necessary IP address or domain name for your DNS configuration. You'll also need to provide your [OIDC environment variables](../sso.md#oidc) from the SSO setup.

### DNS Configuration by Provider

#### Cloudflare
1. Log into your Cloudflare dashboard
2. Select your domain
3. Go to DNS > Records
4. Add a new record:
   - Type: CNAME
   - Name: Your desired subdomain (e.g., `app` for `app.yourdomain.com`)
   - Target: The address provided by our support team
   - Proxy status: Proxied (orange cloud)

#### AWS Route 53
1. Log into AWS Console
2. Navigate to Route 53 > Hosted zones
3. Select your domain
4. Click "Create record"
5. Configure:
   - Record type: CNAME
   - Record name: Your desired subdomain
   - Value: The address provided by our support team
   - TTL: 300 (or as recommended)

#### Google Cloud DNS
1. Go to Google Cloud Console
2. Navigate to Network Services > Cloud DNS
3. Select your zone
4. Click "Add record set"
5. Configure:
   - DNS name: Your desired subdomain
   - Resource record type: CNAME
   - TTL: 300
   - Canonical name: The address provided by our support team

#### GoDaddy
1. Log into GoDaddy
2. Go to DNS Management
3. Under "Records", click "Add"
4. Select:
   - Type: CNAME
   - Host: Your desired subdomain
   - Points to: The address provided by our support team
   - TTL: 1 hour

## Important Notes

1. DNS changes can take up to 48 hours to propagate globally, though most changes take effect within a few hours.
2. Always verify your DNS configuration using tools like `dig` or `nslookup` after making changes.
3. Keep the address provided by our support team secure and only share it with authorized personnel.
4. If you need to make any changes to your domain configuration, please contact our support team first.

## Support

If you need assistance with domain setup or encounter any issues, please contact our support team. We're here to help ensure a smooth setup process.

