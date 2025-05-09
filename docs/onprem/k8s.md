---
sidebar_position: 6
---

# Kubernetes Deployment

This guide will walk you through deploying the project using Kubernetes for production environments.

## Prerequisites

1. A running Kubernetes cluster (v1.20 or later)
2. kubectl configured to communicate with your cluster
3. Access to our Docker images (see [Accessing Docker Images](./docker.md))
4. Helm v3 installed (optional, for easier deployment)

## Required Components

The following components will be deployed:
- Frontend application
- Main API
- Redaction API
- MongoDB
- Qdrant
- Nginx Ingress Controller

## Deployment Structure

The deployment is organized into the following namespaces:
- `confucius`: Main application namespace
- `ingress-nginx`: Ingress controller namespace

## Kubernetes Manifests

### Namespace

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: confucius
```

### ConfigMap

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: confucius-config
  namespace: confucius
data:
  MONGODB_URI: "mongodb://mongodb:27017/confucius"
  QDRANT_URL: "http://qdrant:6333"
  NEXT_PUBLIC_API_URL: "http://main-api:3000"
  NEXT_PUBLIC_REDACTION_API_URL: "http://redaction-api:3001"
```

### Deployments

```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: confucius
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: ${ECR_REPOSITORY_URL}/frontend:latest
        envFrom:
        - configMapRef:
            name: confucius-config
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
```

```yaml
# main-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: main-api
  namespace: confucius
spec:
  replicas: 2
  selector:
    matchLabels:
      app: main-api
  template:
    metadata:
      labels:
        app: main-api
    spec:
      containers:
      - name: main-api
        image: ${ECR_REPOSITORY_URL}/main-api:latest
        envFrom:
        - configMapRef:
            name: confucius-config
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

```yaml
# redaction-api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redaction-api
  namespace: confucius
spec:
  replicas: 2
  selector:
    matchLabels:
      app: redaction-api
  template:
    metadata:
      labels:
        app: redaction-api
    spec:
      containers:
      - name: redaction-api
        image: ${ECR_REPOSITORY_URL}/redaction-api:latest
        envFrom:
        - configMapRef:
            name: confucius-config
        ports:
        - containerPort: 3001
        resources:
          requests:
            memory: "512Mi"
            cpu: "200m"
          limits:
            memory: "1Gi"
            cpu: "500m"
```

### StatefulSets

```yaml
# mongodb-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongodb
  namespace: confucius
spec:
  serviceName: mongodb
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-data
          mountPath: /data/db
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
  volumeClaimTemplates:
  - metadata:
      name: mongodb-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

```yaml
# qdrant-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: qdrant
  namespace: confucius
spec:
  serviceName: qdrant
  replicas: 1
  selector:
    matchLabels:
      app: qdrant
  template:
    metadata:
      labels:
        app: qdrant
    spec:
      containers:
      - name: qdrant
        image: qdrant/qdrant:latest
        ports:
        - containerPort: 6333
        volumeMounts:
        - name: qdrant-data
          mountPath: /qdrant/storage
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
  volumeClaimTemplates:
  - metadata:
      name: qdrant-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
```

### Services

```yaml
# services.yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: confucius
spec:
  selector:
    app: frontend
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: main-api
  namespace: confucius
spec:
  selector:
    app: main-api
  ports:
  - port: 80
    targetPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: redaction-api
  namespace: confucius
spec:
  selector:
    app: redaction-api
  ports:
  - port: 80
    targetPort: 3001
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  namespace: confucius
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
---
apiVersion: v1
kind: Service
metadata:
  name: qdrant
  namespace: confucius
spec:
  selector:
    app: qdrant
  ports:
  - port: 6333
    targetPort: 6333
```

### Ingress

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: confucius-ingress
  namespace: confucius
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: main-api
            port:
              number: 80
      - path: /redaction
        pathType: Prefix
        backend:
          service:
            name: redaction-api
            port:
              number: 80
```

## Deploying the Stack

1. Create the namespace:
   ```bash
   kubectl apply -f namespace.yaml
   ```

2. Apply the ConfigMap:
   ```bash
   kubectl apply -f configmap.yaml
   ```

3. Deploy the applications:
   ```bash
   kubectl apply -f frontend-deployment.yaml
   kubectl apply -f main-api-deployment.yaml
   kubectl apply -f redaction-api-deployment.yaml
   ```

4. Deploy the stateful services:
   ```bash
   kubectl apply -f mongodb-statefulset.yaml
   kubectl apply -f qdrant-statefulset.yaml
   ```

5. Create the services:
   ```bash
   kubectl apply -f services.yaml
   ```

6. Deploy the ingress:
   ```bash
   kubectl apply -f ingress.yaml
   ```

## Environment Variables

For additional environment variables and customization options, see [Customization Guide](./customization.md).

## Accessing Services

- Frontend: https://your-domain.com
- Main API: https://your-domain.com/api
- Redaction API: https://your-domain.com/redaction

## Data Persistence

The setup includes two persistent volumes:
- `mongodb-data`: Stores MongoDB database files
- `qdrant-data`: Stores Qdrant vector database files

These volumes are created using PersistentVolumeClaims and persist across pod restarts.

## High Availability

The deployment is configured for high availability with:
- Multiple replicas for stateless services
- StatefulSets for stateful services
- Pod disruption budgets
- Rolling updates
- Health checks

## Security Considerations

1. Use Kubernetes secrets for sensitive data:
   ```bash
   kubectl create secret generic confucius-secrets \
     --from-literal=SECRET_KEY=your-secret-key \
     --namespace confucius
   ```

2. Implement network policies:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: confucius-network-policy
     namespace: confucius
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: ingress-nginx
     egress:
     - to:
       - podSelector:
           matchLabels:
             app: mongodb
       - podSelector:
           matchLabels:
             app: qdrant
   ```

3. Enable RBAC:
   - Create service accounts
   - Define roles and role bindings
   - Use least privilege principle

4. Regular maintenance:
   - Monitor cluster health
   - Rotate logs
   - Update Kubernetes and images
   - Backup volumes

## Monitoring

1. View pod status:
   ```bash
   kubectl get pods -n confucius
   ```

2. Check service health:
   ```bash
   kubectl describe service <service-name> -n confucius
   ```

3. View logs:
   ```bash
   kubectl logs -f <pod-name> -n confucius
   ```

## Troubleshooting

### Common Issues

1. **Pod Startup Failures**
   - Check pod events: `kubectl describe pod <pod-name> -n confucius`
   - Verify ConfigMap and Secrets
   - Check resource limits
   - Review container logs

2. **Data Persistence**
   - Verify PVC status
   - Check storage class
   - Monitor disk space

3. **Network Issues**
   - Check service endpoints
   - Verify ingress configuration
   - Test service connectivity

## Support

For additional help or to report issues:
- Email: connect@talkingtree.app
- Provide detailed error messages and steps to reproduce
