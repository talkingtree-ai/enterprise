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
    image: ${ECR_REPOSITORY_URL}/frontend:latest
    environment:
      - NEXT_PUBLIC_API_URL=http://main-api:3000
      - NEXT_PUBLIC_REDACTION_API_URL=http://redaction-api:3001
    depends_on:
      - main-api
      - redaction-api

  main-api:
    image: ${ECR_REPOSITORY_URL}/main-api:latest
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/confucius
      - QDRANT_URL=http://qdrant:6333
    depends_on:
      - mongodb
      - qdrant

  redaction-api:
    image: ${ECR_REPOSITORY_URL}/redaction-api:latest
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/confucius
    depends_on:
      - mongodb

  mongodb:
    image: mongo:6.0
    volumes:
      - mongodb_data:/data/db

  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_data:/qdrant/storage

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - frontend
      - main-api
      - redaction-api

volumes:
  mongodb_data:
  qdrant_data:
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
