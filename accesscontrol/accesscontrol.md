# Access control for clusters

## oidc and Azure Ad

Setup Azure Ad: <https://blog.microfast.ch/kubernetes-openid-connect-3883043f0e94>
<https://kubernetes.io/docs/reference/access-authn-authz/authentication/>

Remember .. Group claims are ids. Not group names.

### Install krew

`choco install krew -y`

<https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/>
<https://krew.sigs.k8s.io/docs/user-guide/custom-indexes/>

remember to ....

git config --global --add safe.directory C:/Users/foo/.krew/index/default

Then k krew update krew

### Install kubelogin

<https://github.com/int128/kubelogin>

kubectl krew install oidc-login

### use oidc-login to issue a jwt

`kubectl-oidc_login get-token  --oidc-issuer-url https://sts.windows.net/05e4a2de-0000000/   --oidc-client-id=081dc774-00000000 --oidc-client-secret=<SOMESECRET> --oidc-extra-scope="email groups"`

Tokens are stored in C:\Users\USER\.kube\cache\oidc-login\

### Set oidc user as a new user in the kube context

`kubectl config set-credentials oidc --exec-api-version=client.authentication.k8s.io/v1beta1 --exec-command=kubectl --exec-arg=oidc-login --exec-arg=get-token         --exec-arg=--oidc-issuer-url=https://sts.windows.net/05e4a2de-000000/    --exec-arg=--oidc-client-id=081dc774-00000  --exec-arg=--oidc-client-secret=<somesecret>`

### Apply the oidc settings to the api-server

RKE2 ... the config.yaml file

### apply a clusterrole, or MAYBE a role, and a rolebinding

`kubectl apply -f role.yaml`

### Test the access

`kubectl --user=oidc get nodes`

`kubectl config set-context somecontext --user=oidc`

## Alternatives to Azure AD

Looks REALLY interesting:  <https://pinniped.dev/>

Hosted in the cluster ... username and passwords ... <https://www.keycloak.org/getting-started/getting-started-kube>

OLD SCHOOL LDAP FTW: <https://learnk8s.io/kubernetes-custom-authentication>

OIDC tokens issued in the cluster instead of in kubectl? Seems a little half baked but promising.  <https://artifacthub.io/packages/helm/devopstales/kube-openid-connect>  <https://github.com/devopstales/kube-openid-connect>

Teleport is the full external access to any resource. Including K8s
<https://edidiongasikpo.com/how-to-give-developers-secure-access-to-kubernetes-clusters>

## Quality of life for RBAC

RBAC-Manager and RBAC inspection

<https://github.com/FairwindsOps/rbac-manager>
<https://rbac-manager.docs.fairwinds.com/introduction/#dynamic-namespaces-and-labels>

`helm repo add fairwinds-stable https://charts.fairwinds.com/stable`
`helm install rbac-manager fairwinds-stable/rbac-manager --namespace rbac-manager --create-namespace`
