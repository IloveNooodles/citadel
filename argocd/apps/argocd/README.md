# Argocd Proects

This is a repository to manage all of the argocd config

## Installing Argocd

### Automatic

You can use command in the Taskfile to install it in root directory

```bash
task setup-argocd 
```

### Manually

1. This will add namespace and install argocd into the argocd namespace

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Get the ArgoCD initial password

```bash
PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode) && echo "ArgoCD password: $PASSWORD" > pass
```

3. Port Forward the ArgoCD applications to access the UI

```sh
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

4. Login using the credentials

```yaml
username: admin
password: <The password you got from no 2>
```

5. Create this yaml and apply it to configure the repository if you're using private repository

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-https
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/IloveNooodles/citadel
  username: IloveNooodles
  password: <github_token>
```

6. Create applications, we use app of apps pattern to use

```sh
kubectl apply -f app-of-apps.yaml
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/IloveNooodles/citadel.git
    path: argocd/apps
    targetRevision: main
    directory:
      recurse: true
      jsonnet: {}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
