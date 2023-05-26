# Security and scanning tools

## Kubescape

```shell
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
export PATH=$PATH:/home/lars/.kubescape/bin
kubescape scan --enable-host-scan
```

## OPA

<https://www.openpolicyagent.org/>
OPA engine running Rego ... its own declarative language


## Kubewarden

<https://docs.kubewarden.io/tasks>

Policy examples: Validation of incoming API requests,  mutation (automatically add labels), any custom logic in any language (WASM)

## Falco

eBPF rules
