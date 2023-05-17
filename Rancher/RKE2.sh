# Change or update the config file
 sudo vi /etc/rancher/rke2/config.yaml



# Look at the tls cert for the api, including SANs
sudo openssl x509 -in /var/lib/rancher/rke2/server/tls/serving-kube-apiserver.crt -text -noout




https://gist.github.com/superseb/3b78f47989e0dbc1295486c186e944bf

