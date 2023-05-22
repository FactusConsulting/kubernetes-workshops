# Access control for clusters

## oidc and Azure Ad

Setup Azure Ad: <https://blog.microfast.ch/kubernetes-openid-connect-3883043f0e94>
<https://kubernetes.io/docs/reference/access-authn-authz/authentication/>

### Install krew

`choco install krew -y`

<https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/>
<https://krew.sigs.k8s.io/docs/user-guide/custom-indexes/>

remember to ....

git config --global --add safe.directory C:/Users/foo/.krew/index/default

Then k krew update krew

## Install kubelogin

<https://github.com/int128/kubelogin>

kubectl krew install oidc-login

## use oidc-login to issue a jwt

`kubectl-oidc_login get-token  --oidc-issuer-url https://sts.windows.net/05e4a2de-0000000/   --oidc-client-id=081dc774-00000000 --oidc-client-secret=<SOMESECRET> --oidc-extra-scope="email groups"`

Tokens are stored in C:\Users\USER\.kube\cache\oidc-login\

## Set oidc user as a new user in the kube context

`kubectl config set-credentials oidc --exec-api-version=client.authentication.k8s.io/v1beta1 --exec-command=kubectl --exec-arg=oidc-login --exec-arg=get-token         --exec-arg=--oidc-issuer-url=https://sts.windows.net/05e4a2de-000000/    --exec-arg=--oidc-client-id=081dc774-00000  --exec-arg=--oidc-client-secret=<somesecret>`

## Apply the oidc settings to the api-server

RKE2 ... the config.yaml file

## apply a clusterrole, or MAYBE a role, and a rolebinding

`kubectl apply -f role.yaml`

## Test the access

`kubectl --user=oidc get nodes`
