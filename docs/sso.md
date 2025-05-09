---
sidebar_position: 2
---

# SSO Setup

All of our enterprise options require you to have existing SSO infrastructure. Here's how you can get started. 

## OIDC

### Microsoft
To set up Microsoft Azure AD authentication, you'll need to:

1. Go to the Azure Portal (https://portal.azure.com)
2. Navigate to Azure Active Directory > App registrations
3. Click "New registration"
4. Enter a name for your application
5. Select "Accounts in this organizational directory only"
6. Click "Register"

After registration, you'll need the following environment variables:

- `OIDC_BASE_URL`: This will be `https://login.microsoftonline.com/{tenant-id}/v2.0`
- `OIDC_ISSUER`: This will be `https://login.microsoftonline.com/{tenant-id}/v2.0`
- `OIDC_CLIENT_ID`: This is your Application (client) ID from the app registration overview page

To get these values:
1. From your app registration, copy the Application (client) ID for `OIDC_CLIENT_ID`
2. For `OIDC_BASE_URL` and `OIDC_ISSUER`, replace `{tenant-id}` with your Azure AD tenant ID (found in the app registration overview page)

### Keycloak
To set up Keycloak authentication:

1. Log into your Keycloak admin console
2. Create a new realm or use an existing one
3. Go to Clients > Create client
4. Set Client ID and Client Protocol (OIDC)
5. Enable "Client authentication" and "Authorization"
6. Save the configuration

You'll need the following environment variables:

- `OIDC_BASE_URL`: This will be your Keycloak server URL (e.g., `https://your-keycloak-server/auth`)
- `OIDC_ISSUER`: This will be your Keycloak server URL + `/realms/{realm-name}` (e.g., `https://your-keycloak-server/auth/realms/your-realm`)
- `OIDC_CLIENT_ID`: This is the Client ID you set during client creation

To get these values:
1. From your client settings, copy the Client ID for `OIDC_CLIENT_ID`
2. For `OIDC_BASE_URL`, use your Keycloak server's base URL
3. For `OIDC_ISSUER`, append `/realms/{realm-name}` to your base URL, replacing `{realm-name}` with your realm name

### Other
For any generic OIDC provider, you'll need to configure the following environment variables:

- `OIDC_BASE_URL`: The base URL of your OIDC provider (e.g., `https://your-oidc-provider.com`)
- `OIDC_ISSUER`: The issuer URL of your OIDC provider (e.g., `https://your-oidc-provider.com/oauth2/default`)
- `OIDC_CLIENT_ID`: The client ID provided by your OIDC provider

To get these values:
1. Register your application with your OIDC provider
2. Look for the following in your provider's documentation or dashboard:
   - The base URL of your OIDC provider
   - The issuer URL (sometimes called the "issuer" or "authorization server")
   - The client ID assigned to your application

Common OIDC providers include:
- Okta
- Google Workspace
- OneLogin
- Ping Identity

Each provider will have their own specific setup process, but they all require these three environment variables to be configured correctly.

## SAML
SAML support is currently not supported, but it is in active development.

