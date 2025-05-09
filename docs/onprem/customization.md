---
sidebar_position: 7
---

# Customization Guide

This guide provides details about the environment variables and configuration options available for customizing your deployment.

## Environment Variables

### Frontend Application

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NEXT_PUBLIC_API_URL` | URL of the main API | `http://main-api:3000` | Yes |
| `NEXT_PUBLIC_REDACTION_API_URL` | URL of the redaction API | `http://redaction-api:3001` | Yes |
| `NEXT_PUBLIC_APP_NAME` | Name of the application | `Confucius` | No |
| `NEXT_PUBLIC_APP_DESCRIPTION` | Description of the application | `AI-Powered Document Analysis` | No |
| `NEXT_PUBLIC_APP_VERSION` | Version of the application | `1.0.0` | No |

### Main API

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MONGODB_URI` | MongoDB connection string | `mongodb://mongodb:27017/confucius` | Yes |
| `QDRANT_URL` | Qdrant connection URL | `http://qdrant:6333` | Yes |
| `API_PORT` | Port to run the API on | `3000` | No |
| `NODE_ENV` | Node environment | `production` | No |
| `LOG_LEVEL` | Logging level | `info` | No |
| `CORS_ORIGIN` | CORS allowed origins | `*` | No |
| `JWT_SECRET` | JWT signing secret | - | Yes |
| `JWT_EXPIRY` | JWT token expiry | `24h` | No |
| `RATE_LIMIT_WINDOW` | Rate limit window in ms | `900000` | No |
| `RATE_LIMIT_MAX` | Maximum requests per window | `100` | No |

### Redaction API

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MONGODB_URI` | MongoDB connection string | `mongodb://mongodb:27017/confucius` | Yes |
| `API_PORT` | Port to run the API on | `3001` | No |
| `NODE_ENV` | Node environment | `production` | No |
| `LOG_LEVEL` | Logging level | `info` | No |
| `CORS_ORIGIN` | CORS allowed origins | `*` | No |
| `JWT_SECRET` | JWT signing secret | - | Yes |
| `JWT_EXPIRY` | JWT token expiry | `24h` | No |
| `RATE_LIMIT_WINDOW` | Rate limit window in ms | `900000` | No |
| `RATE_LIMIT_MAX` | Maximum requests per window | `100` | No |

### MongoDB

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `MONGO_INITDB_ROOT_USERNAME` | Root username | - | Yes |
| `MONGO_INITDB_ROOT_PASSWORD` | Root password | - | Yes |
| `MONGO_INITDB_DATABASE` | Initial database name | `confucius` | No |

### Qdrant

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `QDRANT_STORAGE_PATH` | Storage path | `/qdrant/storage` | No |
| `QDRANT_HTTP_PORT` | HTTP port | `6333` | No |
| `QDRANT_GRPC_PORT` | gRPC port | `6334` | No |

### Nginx

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NGINX_HOST` | Hostname | `localhost` | No |
| `NGINX_PORT` | Port | `80` | No |
| `NGINX_SSL_PORT` | SSL port | `443` | No |
| `NGINX_SSL_CERT` | SSL certificate path | - | Yes (for HTTPS) |
| `NGINX_SSL_KEY` | SSL key path | - | Yes (for HTTPS) |

## Configuration Files

### Nginx Configuration

Create a custom `nginx.conf` file to configure the reverse proxy:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }

    upstream main-api {
        server main-api:3000;
    }

    upstream redaction-api {
        server redaction-api:3001;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /api {
            proxy_pass http://main-api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location /redaction {
            proxy_pass http://redaction-api;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
```

### MongoDB Configuration

Create a custom `mongod.conf` file to configure MongoDB:

```yaml
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true

storage:
  dbPath: /data/db
  journal:
    enabled: true

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled
```

### Qdrant Configuration

Create a custom `config.yaml` file to configure Qdrant:

```yaml
storage:
  storage_path: /qdrant/storage

service:
  host: 0.0.0.0
  http_port: 6333
  grpc_port: 6334

cluster:
  enabled: false
```

## Resource Requirements

### Minimum Requirements

| Service | CPU | Memory | Storage |
|---------|-----|--------|---------|
| Frontend | 100m | 256Mi | - |
| Main API | 200m | 512Mi | - |
| Redaction API | 200m | 512Mi | - |
| MongoDB | 500m | 1Gi | 10Gi |
| Qdrant | 500m | 1Gi | 10Gi |
| Nginx | 100m | 128Mi | - |

### Recommended Requirements

| Service | CPU | Memory | Storage |
|---------|-----|--------|---------|
| Frontend | 200m | 512Mi | - |
| Main API | 500m | 1Gi | - |
| Redaction API | 500m | 1Gi | - |
| MongoDB | 1000m | 2Gi | 20Gi |
| Qdrant | 1000m | 2Gi | 20Gi |
| Nginx | 200m | 256Mi | - |

## Security Considerations

1. **Secrets Management**
   - Use Kubernetes secrets or Docker secrets
   - Rotate secrets regularly
   - Never commit secrets to version control

2. **Network Security**
   - Use internal networks for service communication
   - Configure firewall rules
   - Enable TLS for external access

3. **Authentication**
   - Use strong passwords
   - Enable MongoDB authentication
   - Configure JWT secrets
   - Implement rate limiting

4. **Data Security**
   - Enable MongoDB encryption
   - Configure backup strategies
   - Implement access controls
   - Monitor access logs

## Backup and Recovery

### MongoDB Backup

1. Create a backup:
   ```bash
   mongodump --uri="mongodb://username:password@localhost:27017/confucius" --out=/backup
   ```

2. Restore from backup:
   ```bash
   mongorestore --uri="mongodb://username:password@localhost:27017/confucius" /backup
   ```

### Qdrant Backup

1. Create a backup:
   ```bash
   cp -r /qdrant/storage /backup/qdrant
   ```

2. Restore from backup:
   ```bash
   cp -r /backup/qdrant/* /qdrant/storage/
   ```

## Monitoring and Logging

### Logging Configuration

1. Configure log rotation:
   ```bash
   /var/log/mongodb/*.log {
       daily
       rotate 7
       compress
       delaycompress
       missingok
       notifempty
       create 640 mongodb mongodb
   }
   ```

2. Set up log aggregation:
   - Use ELK stack
   - Configure log forwarding
   - Set up log retention policies

### Monitoring Setup

1. Configure Prometheus metrics:
   - Enable metrics endpoints
   - Set up Prometheus scraping
   - Configure alerting rules

2. Set up Grafana dashboards:
   - Create service dashboards
   - Configure alerts
   - Set up notifications

## Support

For additional help or to report issues:
- Email: connect@talkingtree.app
- Provide detailed error messages and steps to reproduce 