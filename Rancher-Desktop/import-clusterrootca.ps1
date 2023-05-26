param (
    $CASecretName = "ca-secret"
)

. ./supportfunctions.ps1

Write-TimestampedHost "Now we import the newly created CA from the PKI just created on the cluster. Executing $( $scriptFile.FullName )" -ForegroundColor Cyan
$namespace = "cert-manager"
$secretName = $CASecretName

# Retrieve the Kubernetes Secret containing the certificate
$secret = kubectl get secret $secretName -n $namespace -o json | ConvertFrom-Json

# Decode the certificate
$decodedCertificate = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($secret.data.'tls.crt'))

# Save the certificate to a temporary file
$tempCertFile = New-TemporaryFile
$tempCertFile = $tempCertFile.FullName + ".crt"
Set-Content -Path $tempCertFile -Value $decodedCertificate

# Load the certificate from the temporary file
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $tempCertFile

# Import the certificate into the Root store

try {
    $importedCert = Import-Certificate -FilePath $tempCertFile -CertStoreLocation Cert:\LocalMachine\Root
}
catch {
        Write-Error "Import of ca failed"
}

# Remove the temporary file
Remove-Item -Path $tempCertFile

Write-TimestampedHost "CA imported into local machione Root store" -ForegroundColor Green