# Rancher UI and controlplane

## Install the controlplane

```helm
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
helm install rancher rancher-latest/rancher --namespace cattle-system --set hostname=rd.local --set bootstrapPassword=admin --set ingress.annotations."kubernetes.io/ingress.class"="nginx" --set global.cattle.psp.enabled=false --create-namespace

```

## AzureAD integration

<https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/authentication-permissions-and-global-configuration/authentication-config/configure-azure-ad>