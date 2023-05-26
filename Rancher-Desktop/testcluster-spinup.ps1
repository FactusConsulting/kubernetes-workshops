param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('RancherDesktop', 'Kind', 'K3d')]
    [string]$ClusterType
)

. .\supportfunctions.ps1

### Common Variables
$fluxGitUrl = "ssh://git@github.com/Larswa/flux-home.git"   # Git repo with the flux infrastructure
$sshFilePath = "$HOME\.ssh\id_rsa_06-2022"                   # an SSH with read access to the git repo
$fluxBranchName = "main"                                        # flux git branch
$CANamespace = "cert-manager"                                # used for looking for the PLKI CA
$CASecretName = "ca-secret"

switch ($ClusterType) {
    'RancherDesktop' {
        Write-TimestampedHost "Spinning up a RancherDesktop cluster" -ForegroundColor Cyan

        $fluxClusterPath = "./clusters/rancherdesktop"           # The path to the cluster in the flux git repo
        $testUrl = "https://rd.local/foo/hostname"      # Used for testing if the cluster is available
        $contextName = "rancher-desktop"                     # Kubernetes kontext used for finding out when the API/Node is up.
        $kubernetesVersion = "1.25.8"                              # Kubernetes version we want

        Reset-RancherCluster -KubernetesVersion $kubernetesVersion -ContextName $contextName
        Run-Elevated "./update-hostsfile.ps1"
    }

    'Kind' {
        Write-TimestampedHost "Spinning up a Kind cluster" -ForegroundColor Cyan

        $fluxClusterPath = "./clusters/kind"                   # The path to the cluster in the flux git repo
        $testUrl = "https://localhost/foo/hostname"            # Used for testing if the cluster is available
        $ContextName = "kind-kind"                             # Kubernetes kontext used for finding out when the API/Node is up.
        $kubernetesVersion = "1.25.8"                          # Kubernetes version we want

        kind delete cluster
        kind create cluster --config=kindconfig.yaml
    }
    'K3d' {
        Write-TimestampedHost "Spinning up a K3D cluster" -ForegroundColor Cyan
        ### Cluster specific
        $fluxClusterPath = "./clusters/k3d"                 # The path to the cluster in the flux git repo
        $testUrl = "https://localhost/foo/hostname"         # used for testing if the cluster is available
        $ContextName = "k3d"                                # Kubernetes kontext used for finding out when the API/Node is up.
        $kubernetesVersion = "1.25.8"                       # K3d version we want
    }
}

$fluxBootstrapOptions = "git --url=$fluxGitUrl  --private-key-file=$sshFilePath --branch=$fluxBranchName --path=$fluxClusterPath"
Bootstrap-FluxCD -FluxBootstrapOptions $fluxBootstrapOptions
Test-IsPKIReady -TestSecretName $CASecretName -TestNamespace $CANamespace

Write-TimestampedHost "Now we import the newly created CA from the PKI just created on the cluster. Executing $( $scriptFile.FullName )" -ForegroundColor Cyan
Run-Elevated "./import-clusterrootca.ps1 -CASecretName $CASecretName"
Write-TimestampedHost "CA imported into `"Local Computer\Root`" store" -ForegroundColor Green

Test-IsClusterReady -TestUrl $testUrl
