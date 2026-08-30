# Ecommerce GitOps

## Bootstrap (première installation)

```bash
# 1. Installer ArgoCD sur le cluster
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 3. Appliquer le root-app (App of Apps) — ArgoCD prendra le relais ensuite
kubectl apply -f argocd/root-app.yaml

# 4. Créer le ClusterIssuer cert-manager (une fois cert-manager synchronisé)
kubectl apply -f apps/cert-manager/clusterissuer.yaml
```

## DNS

Pointer un enregistrement A de `monsite.com` vers l'IP externe du service
`ingress-nginx-controller` (`kubectl get svc -n ingress-nginx`).

## Ordre logique de synchronisation ArgoCD

1. ingress-nginx (fournit l'IP publique)
2. cert-manager (puis appliquer le ClusterIssuer manuellement, une seule fois)
3. postgres
4. ecommerce (site) — l'Ingress ne délivrera un certificat valide qu'une fois le DNS pointé
5. airflow

## À adapter avant de pousser en prod

- Remplacer tous les `CHANGE_ME` et `<TON_USER>` / `monsite.com`
- Remplacer les Secrets en clair par Sealed Secrets ou un vault externe (ne jamais committer de vrais secrets)
- Créer la base `warehouse` et la table `fact_orders` (script SQL à ajouter, non inclus ici)
- Configurer un registre d'images (GHCR, Docker Hub) et le pipeline CI de `ecommerce-app`


tTPMHLfiOBcX9krl


minikube start
  492  minikube kubectl -- get pods -A
  493  minikube kubectl namespaces
  494  kubectl get namespaces
  495   kubectl apply --server-side -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  496  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  497  kubectl apply -f ecommerce-gitops/argocd/root-app.yaml
  498  kubectl apply -f argocd/root-app.yaml
  499  argocd app list
  500  kubectl get svc -n ingress-nginx ingress-nginx-controller
  501  minikube addons enable ingress
  502  minikube addons enable storage-provisioner
  503  kubectl port-forward svc/argocd-server -n argocd 8080:443
  504  kubectl port-forward svc/argocd-server -n argocd 8080:443
  505  history