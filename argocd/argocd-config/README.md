# Argocd Proects

This is a repository to manage all of the argocd config


## Installing Argocd

### Automatic
You can use command in the Taskfile to install it in root directory

```sh
task setup-argocd 
```

### Manually

1. This will add namespace and install argocd into the argocd namespace
```sh
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
2. Get the ArgoCD initial password
```
PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode) && echo "ArgoCD password: $PASSWORD" > pass
```

3. Port Forward the ArgoCD applications to access the UI
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

4. Login using the credentials
```
username: admin
password: <The password you got from no 2>
```

5. 
