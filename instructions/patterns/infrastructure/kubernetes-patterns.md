# Kubernetes Patterns

Cloud-native application patterns for Kubernetes deployments.

## Deployment Patterns

### Rolling Update
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
```

### Blue-Green Deployment
```yaml
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue

---
# Green deployment (new)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green

---
# Service pointing to active deployment
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
    version: blue  # Switch to green for deployment
  ports:
  - port: 80
    targetPort: 8080
```

## Configuration Management

### ConfigMaps and Secrets
```yaml
# ConfigMap for application config
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.url: "postgres://db:5432/myapp"
  log.level: "info"
  app.properties: |
    feature.flags.newUI=true
    cache.ttl=3600

---
# Secret for sensitive data
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  database.password: cGFzc3dvcmQxMjM=  # base64 encoded
  api.key: YWJjZGVmZ2hpams=

---
# Using in Pod
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    envFrom:
    - configMapRef:
        name: app-config
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database.password
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

## Health Checks

### Liveness and Readiness Probes
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health/startup
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          failureThreshold: 30
```

## Service Mesh

### Sidecar Pattern
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
  # Main application container
  - name: app
    image: myapp:1.0.0
    ports:
    - containerPort: 8080
  
  # Sidecar proxy container
  - name: envoy-proxy
    image: envoyproxy/envoy:v1.20.0
    ports:
    - containerPort: 9901
    volumeMounts:
    - name: envoy-config
      mountPath: /etc/envoy
  
  volumes:
  - name: envoy-config
    configMap:
      name: envoy-config
```

## Autoscaling

### Horizontal Pod Autoscaler
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
```

## Job Patterns

### CronJob for Scheduled Tasks
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: backup-tool:1.0.0
            command:
            - /bin/sh
            - -c
            - |
              echo "Starting backup..."
              pg_dump $DATABASE_URL > /backup/db-$(date +%Y%m%d).sql
              aws s3 cp /backup/db-$(date +%Y%m%d).sql s3://backups/
```

### Batch Job
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-migration
spec:
  parallelism: 3
  completions: 10
  backoffLimit: 4
  activeDeadlineSeconds: 3600
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: migration:1.0.0
        command: ["./migrate.sh"]
```

## StatefulSet Pattern

### Stateful Applications
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-service
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
  volumeClaimTemplates:
  - metadata:
      name: postgres-storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

## Network Policies

### Traffic Control
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: app-network-policy
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## Init Containers

### Initialization Pattern
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
spec:
  initContainers:
  # Wait for database
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nc -z database 5432; do sleep 1; done']
  
  # Run migrations
  - name: db-migration
    image: migrate:1.0.0
    command: ['migrate', '-path', '/migrations', '-database', '$DATABASE_URL', 'up']
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: url
  
  containers:
  - name: app
    image: myapp:1.0.0
    ports:
    - containerPort: 8080
```

## Resource Management

### Resource Quotas
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: namespace-quota
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 100Gi
    limits.cpu: "200"
    limits.memory: 200Gi
    persistentvolumeclaims: "10"
    services.loadbalancers: "2"

---
# Limit Range
apiVersion: v1
kind: LimitRange
metadata:
  name: namespace-limits
spec:
  limits:
  - default:
      cpu: 200m
      memory: 256Mi
    defaultRequest:
      cpu: 100m
      memory: 128Mi
    type: Container
```

## Checklist
- [ ] Define resource limits
- [ ] Configure health checks
- [ ] Set up autoscaling
- [ ] Implement proper secrets management
- [ ] Use appropriate deployment strategy
- [ ] Configure network policies
- [ ] Set up monitoring and logging