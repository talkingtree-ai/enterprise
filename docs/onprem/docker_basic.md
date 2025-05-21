---
sidebar_position: 4
---

# Basic Docker Setup

This guide will walk you through setting up the project using Docker Compose for local development or small-scale deployments.

## Prerequisites

1. Docker installed on your machine
2. Docker Compose installed on your machine
3. Access to our Docker images (see [Accessing Docker Images](./docker.md))

## Required Containers

The following containers are required to run the project:

- Frontend application
- Main API
- Redaction API
- MongoDB
- Qdrant
- Nginx (reverse proxy)

## Docker Compose Setup

Create a `docker-compose.yml` file with the following configuration:

```yaml
version: '3.8'

services:
  frontend:
    image: <ECR-URL>/frontend:latest
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=development
      - API_BASE_URL=http://main-api:8000
      - REDACT_BASE_URL=http://redaction-api:6161
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AWS_REGION=${AWS_REGION}
      - NEXT_PUBLIC_AWS_BUCKET_NAME=${NEXT_PUBLIC_AWS_BUCKET_NAME}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - DB_MONGO_HOST=mongodb
      - DB_MONGO_USER=${DB_MONGO_USER}
      - DB_MONGO_PASSWORD=${DB_MONGO_PASSWORD}
      - DB_MONGO_COUNSEL_DB=${DB_MONGO_COUNSEL_DB}
      - DB_MONGO_DATABASE=${DB_MONGO_DATABASE}
      - DB_MONGO_DOCGEN=${DB_MONGO_DOCGEN}
      - DB_MONGO_LIMIT=${DB_MONGO_LIMIT}
      - DB_MONGO_CHATBOT=${DB_MONGO_CHATBOT}
      - SESSION_SECRET=${SESSION_SECRET}
      - SSO_MODE=oidc
      - OIDC_BASE_URL=${OIDC_BASE_URL}
      - OIDC_ISSUER=${OIDC_ISSUER}
      - OIDC_CLIENT_ID=${OIDC_CLIENT_ID}
      - OIDC_ADMIN=${OIDC_ADMIN}
      - NEXT_PUBLIC_BRAND_IMG=${NEXT_PUBLIC_BRAND_IMG}
      - NEXT_PUBLIC_TITLE=${NEXT_PUBLIC_TITLE}
      - NEXT_PUBLIC_CONTACT=${NEXT_PUBLIC_CONTACT}
      - NEXT_PUBLIC_HIDE_COPYRIGHT=${NEXT_PUBLIC_HIDE_COPYRIGHT}
      - WHISPER_PROVIDER=${WHISPER_PROVIDER}
      - AZURE_OPENAI_API_VERSION=${AZURE_OPENAI_API_VERSION}
      - AZURE_OPENAI_DEPLOYMENT=${AZURE_OPENAI_DEPLOYMENT}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
    depends_on:
      - main-api
      - redaction-api

  main-api:
    image: <ECR-URL>/main-api:latest
    environment:
      - NODE_ENV=development
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AZURE_API_KEY=${AZURE_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
      - DB_MONGO_HOST=mongodb
      - DB_MONGO_PORT=27017
      - DB_MONGO_DATABASE=${DB_MONGO_DATABASE}
      - DB_MONGO_USER=${DB_MONGO_USER}
      - DB_MONGO_PASSWORD=${DB_MONGO_PASSWORD}
      - QDRANT_URL=http://qdrant:6333
    depends_on:
      - mongodb
      - qdrant

  redaction-api:
    image: <ECR-URL>/redaction-api:latest
    environment:
      - NODE_ENV=development
      - DB_MONGO_DATABASE=${DB_MONGO_DATABASE}
      - DB_MONGO_HOST=mongodb
      - DB_MONGO_USER=${DB_MONGO_USER}
      - DB_MONGO_PASSWORD=${DB_MONGO_PASSWORD}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - AZURE_API_KEY=${AZURE_API_KEY}
      - AZURE_ENDPOINT=${AZURE_ENDPOINT}
      - AZURE_API_VERSION=${AZURE_API_VERSION}
      - AZURE_DEPLOYMENT_NAME=${AZURE_DEPLOYMENT_NAME}
      - API_TYPE=${API_TYPE}
    depends_on:
      - mongodb
      - qdrant

  # word-extension:
  #   image: <ECR-URL>/word-extension:latest
  #   ports:
  #     - "3001:3001"
  #   environment:
  #     - NODE_ENV=development
  #     - API_URL=http://main-api:8000
  #   depends_on:
  #     - main-api
  #     - redaction-api

  mongodb:
    image: mongo:6.0
    volumes:
      - mongodb_data:/data/db
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${DB_MONGO_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${DB_MONGO_PASSWORD}
    command: mongod --auth

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      - QDRANT_ALLOW_CORS=true

volumes:
  mongodb_data:
  qdrant_data:

networks:
  default:
    name: talkingtree-network

```

## Environment Variables

Create a `.env` file in the same directory as your `docker-compose.yml`:

```bash
ECR_REPOSITORY_URL=<your-ecr-repository-url>
```

For additional environment variables and customization options, see [Customization Guide](./customization.md).

## Running the Stack

1. Start all services:
   ```bash
   docker-compose up -d
   ```

2. Check service status:
   ```bash
   docker-compose ps
   ```

3. View logs:
   ```bash
   docker-compose logs -f
   ```

4. Stop all services:
   ```bash
   docker-compose down
   ```

## Accessing Services

- Frontend: http://localhost
- Main API: http://localhost/api
- Redaction API: http://localhost/redaction

## Data Persistence

The setup includes two persistent volumes:
- `mongodb_data`: Stores MongoDB database files
- `qdrant_data`: Stores Qdrant vector database files

These volumes persist even when containers are removed, ensuring your data remains intact.

## Security Considerations

1. This setup is suitable for development and small-scale deployments
2. For production use, consider:
   - Setting up proper SSL/TLS certificates
   - Implementing network security
   - Using secrets management
   - Setting up proper authentication
   - Configuring backup strategies

## Troubleshooting

### Common Issues

1. **Container Startup Failures**
   - Check container logs: `docker-compose logs <service-name>`
   - Verify environment variables
   - Ensure all required ports are available

2. **Connection Issues**
   - Verify network connectivity between containers
   - Check service dependencies
   - Ensure MongoDB and Qdrant are running

3. **Data Persistence**
   - Verify volume mounts
   - Check permissions on mounted volumes
   - Ensure sufficient disk space

## Support

For additional help or to report issues:
- Email: connect@talkingtree.app
- Provide detailed error messages and steps to reproduce
