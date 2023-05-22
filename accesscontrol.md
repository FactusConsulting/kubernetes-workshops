# Access control for clusters

## oidc and Azure Ad

Install krew
https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/
https://krew.sigs.k8s.io/docs/user-guide/custom-indexes/

remember to ....

git config --global --add safe.directory C:/Users/foo/.krew/index/default

Then k krew update krew
k krew install oidc-login


OIDC

https://kubernetes.io/docs/reference/access-authn-authz/authentication/

https://blog.microfast.ch/kubernetes-openid-connect-3883043f0e94

https://github.com/int128/kubelogin

