# Debug Pods in Kubernetes

## Common Debugging Commands

```bash
# Check pod status
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs --previous <pod-name> -n <namespace>

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Debug with ephemeral container
kubectl debug -it <pod-name> --image=busybox --target=<container-name>

# Port forwarding
kubectl port-forward <pod-name> 8080:80 -n <namespace>
```

## Common Issues
- ImagePullBackOff: Check image name and registry credentials
- CrashLoopBackOff: Check logs and resource limits
- Pending: Check node resources and PVC status
