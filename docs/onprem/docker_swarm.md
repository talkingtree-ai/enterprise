---
sidebar_position: 5
---

# Docker Swarm Deployment

This guide will walk you through deploying the project using Docker Swarm for production environments.

## Prerequisites

1. Docker installed on all nodes
2. Docker Swarm initialized
3. Access to our Docker images (see [Accessing Docker Images](./docker.md))
4. At least one manager node and one worker node

## Initializing Docker Swarm

1. On the manager node:
   ```bash
   docker swarm init --advertise-addr <MANAGER-IP>
   ```

2. On worker nodes:
   ```bash
   docker swarm join --token <WORKER-TOKEN> <MANAGER-IP>:2377
   ```

## Required Containers

The following services will be deployed:
- Frontend application
- Main API
- Redaction API
- MongoDB
- Qdrant
- Nginx (reverse proxy)

## Stack Deployment

Create a `docker-stack.yml` file:

```yaml
version: '3.8'

services:
  frontend:
    image: ${ECR_REPOSITORY_URL}/frontend:latest
    environment:
      - NEXT_PUBLIC_API_URL=http://main-api:3000
      - NEXT_PUBLIC_REDACTION_API_URL=http://redaction-api:3001
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - app-network

  main-api:
    image: ${ECR_REPOSITORY_URL}/main-api:latest
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/confucius
      - QDRANT_URL=http://qdrant:6333
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - app-network

  redaction-api:
    image: ${ECR_REPOSITORY_URL}/redaction-api:latest
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/confucius
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - app-network

  mongodb:
    image: mongo:6.0
    volumes:
      - mongodb_data:/data/db
    deploy:
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
    networks:
      - app-network

  qdrant:
    image: qdrant/qdrant:latest
    volumes:
      - qdrant_data:/qdrant/storage
    deploy:
      placement:
        constraints: [node.role == manager]
      restart_policy:
        condition: on-failure
    networks:
      - app-network

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure
    networks:
      - app-network

networks:
  app-network:
    driver: overlay

volumes:
  mongodb_data:
    driver: local
  qdrant_data:
    driver: local
```

## Environment Variables

Create a `.env` file in the same directory as your `docker-stack.yml`:

```bash
ECR_REPOSITORY_URL=<your-ecr-repository-url>
```

For additional environment variables and customization options, see [Customization Guide](./customization.md).

## Deploying the Stack

1. Deploy the stack:
   ```bash
   docker stack deploy -c docker-stack.yml confucius
   ```

2. Check service status:
   ```bash
   docker service ls
   ```

3. View service logs:
   ```bash
   docker service logs confucius_<service-name>
   ```

4. Scale a service:
   ```bash
   docker service scale confucius_<service-name>=<number-of-replicas>
   ```

5. Remove the stack:
   ```bash
   docker stack rm confucius
   ```

## Accessing Services

- Frontend: http://\&lt;any-node-ip\&gt;
- Main API: http://\&lt;any-node-ip\&gt;/api
- Redaction API: http://\&lt;any-node-ip\&gt;/redaction

## Data Persistence

The setup includes two persistent volumes:
- `mongodb_data`: Stores MongoDB database files
- `qdrant_data`: Stores Qdrant vector database files

These volumes are created on the manager node and persist across stack updates.

## High Availability

The stack is configured for high availability with:
- Multiple replicas for stateless services
- Placement constraints for stateful services
- Automatic service recovery
- Rolling updates

## Security Considerations

1. Enable Swarm mode encryption:
   ```bash
   docker swarm init --advertise-addr <MANAGER-IP> --secret
   ```

2. Use Docker secrets for sensitive data:
   ```bash
   echo "mysecret" | docker secret create my_secret -
   ```

3. Implement proper network security:
   - Use overlay networks
   - Configure firewall rules
   - Enable TLS for node communication

4. Regular maintenance:
   - Monitor node health
   - Rotate logs
   - Update Docker and images
   - Backup volumes

## Monitoring

1. View node status:
   ```bash
   docker node ls
   ```

2. Check service health:
   ```bash
   docker service ps confucius_<service-name>
   ```

3. Monitor resource usage:
   ```bash
   docker stats
   ```

## Troubleshooting

### Common Issues

1. **Service Deployment Failures**
   - Check node resources
   - Verify network connectivity
   - Review service logs
   - Check placement constraints

2. **Data Persistence**
   - Verify volume mounts
   - Check node storage
   - Monitor disk space

3. **Network Issues**
   - Check overlay network
   - Verify DNS resolution
   - Test service connectivity

## Support

For additional help or to report issues:
- Email: connect@talkingtree.app
- Provide detailed error messages and steps to reproduce
