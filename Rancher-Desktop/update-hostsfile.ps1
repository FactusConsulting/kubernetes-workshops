. .\supportfunctions.ps1

function Add-RecordToHostsFile {
    param(
        $HostName,
        $IpAddress
    )
    $hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $newHostEntry = "$IpAddress $HostName"

    Write-Host "NewHostEntry is $newHostEntry"

    # Read the hosts file and remove any existing rd.local entry
    $hostsContent = Get-Content $hostsFilePath | Where-Object { $_ -notmatch $HostName }

    # Add the new rd.local entry with the IP address
    $hostsContent += $newHostEntry

    # Write the updated content back to the hosts file (requires admin privileges)
    Set-Content -Path $hostsFilePath -Value $hostsContent -Force

    # Output the added entry
    Write-Host "Added/updated entry in hosts file: $newHostEntry" -ForegroundColor Green
}

Write-TimestampedHost "Setting entries into the host file to point at rancher-desktop. These urls are used in the test ingress" -ForegroundColor Cyan
$wslOutput = wsl hostname -I

# Extract the first IP address from the output and create the record for later
$ipPattern = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'
$firstIPAddress = [regex]::match($wslOutput, $ipPattern).Value

Add-RecordToHostsFile -HostName rd.local -IpAddress $firstIPAddress
Add-RecordToHostsFile -HostName rdapi.local -IpAddress $firstIPAddress
