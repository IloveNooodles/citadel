# Pod-to-Pod Communication Demo

This directory contains two services that demonstrate pod-to-pod communication within a Kubernetes cluster.

## Architecture

```
┌─────────────┐         HTTP Request          ┌─────────────┐
│             │ ────────────────────────────> │             │
│  Frontend   │   http://backend:8080         │   Backend   │
│  (Client)   │ <──────────────────────────── │  (Server)   │
│             │         Response               │             │
└─────────────┘                                └─────────────┘
   2 replicas                                     2 replicas
```

## Services

### Backend Service
- **Image**: `hashicorp/http-echo`
- **Port**: 8080
- **Replicas**: 2
- **Function**: Simple HTTP server that responds with "Hello from Backend Service!"
- **Service Name**: `backend.pod-to-pod-communication.svc.cluster.local`

### Frontend Service
- **Image**: `curlimages/curl`
- **Replicas**: 2
- **Function**: Continuously calls the backend service every 10 seconds
- **Communication**: Uses Kubernetes DNS to resolve backend service

## How It Works

1. **Service Discovery**: Frontend uses Kubernetes DNS to find backend
   - FQDN: `backend.pod-to-pod-communication.svc.cluster.local`
   - Short name: `backend` (works within same namespace)

2. **Load Balancing**: Kubernetes Service automatically load balances requests across backend pods

3. **Network Policy**: Traffic flows through Kubernetes ClusterIP service

## Deployment

This application is managed by ArgoCD and will be automatically deployed when synced.

### Manual Deployment (if needed)
```bash
kubectl apply -k argocd/apps/pod-to-pod-communication/
```

## Verification

### Check if pods are running
```bash
kubectl get pods -n pod-to-pod-communication
```

### Check services
```bash
kubectl get svc -n pod-to-pod-communication
```

### View frontend logs (see communication)
```bash
kubectl logs -n pod-to-pod-communication -l app=frontend -f
```

Expected output:
```
=== Frontend calling Backend at Mon Dec 10 16:20:00 UTC 2025 ===
Hello from Backend Service!
Response received successfully!
```

### Test backend directly
```bash
kubectl run test-pod --rm -it --image=curlimages/curl -n pod-to-pod-communication -- \
  curl http://backend:8080
```

### Check connectivity between pods
```bash
# Get a frontend pod name
FRONTEND_POD=$(kubectl get pod -n pod-to-pod-communication -l app=frontend -o jsonpath='{.items[0].metadata.name}')

# Exec into it and test
kubectl exec -it $FRONTEND_POD -n pod-to-pod-communication -- \
  curl http://backend:8080
```

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod -n pod-to-pod-communication
```

### DNS resolution issues
```bash
kubectl run test-dns --rm -it --image=busybox -n pod-to-pod-communication -- \
  nslookup backend
```

### Network connectivity issues
```bash
# Check if backend service has endpoints
kubectl get endpoints backend -n pod-to-pod-communication

# Check network policies
kubectl get networkpolicies -n pod-to-pod-communication
```

## Clean Up

```bash
kubectl delete namespace pod-to-pod-communication
```

Or let ArgoCD handle it by removing the application.

