# Rancher UI and controlplane

## Install the controlplane

### Docker

`docker run -d --restart=unless-stopped -p 8080:80 -p 44300:443 --privileged rancher/rancher:latest`

### Helm

```helm
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo update
helm upgrade --install rancher rancher-latest/rancher --namespace cattle-system --set hostname=rd.local --set bootstrapPassword=admin --set ingress.ingressClassName=nginx --set global.cattle.psp.enabled=false --create-namespace --set ingress.annotations."cert-manager\.io/cluster-issuer"="ca-issuer" --set ingress.labels."cert-manager\.io/cluster-issuer"="true" --set ingress.labels."cert-manager\.io/inject-ca-from"="ca-issuer"  --set certmanager.create=false


helm uninstall rancher -n cattle-system

```

### Vagrant

<https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/vagrant>

`git clone https://github.com/rancher/quickstart`

Use this configuration instead of default one

```yaml
admin_password: adminPassword
rancher_version: v2.7.3
ROS_version: 1.5.1
# Empty defaults to latest non-experimental available
k8s_version: "v1.23.16-rancher2-1"
server:
  cpus: 4
  memory: 6000
node:
  count: 1
  cpus: 4
  memory: 4500
  open-iscsi: disabled
ip:
  master: 192.168.56.100
  server: 192.168.56.101
  node: 192.168.56.111
linked_clones: true
net:
  private_nic_type: 82545EM
  network_type: private_network
```

## AzureAD integration

<https://ranchermanager.docs.rancher.com/how-to-guides/new-user-guides/authentication-permissions-and-global-configuration/authentication-config/configure-azure-ad>


## Adopting a vagrant cluster from vagrantk8s

Edit the deployment to add

hostAliases:
  - ip: "172.23.4.7"
    hostnames:
    - "rd.local"

sudo /var/lib/rancher/rke2/bin/kubectl edit deployment cattle-cluster-agent -n cattle-system --kubeconfig /etc/rancher/rke2/rke2.yaml


