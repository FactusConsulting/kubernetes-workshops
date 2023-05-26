########
##  Support functions needed for the testcluster-spinup.ps1 script.
##  Moved here to keep the main script cleaner and more readable
########


function Write-TimestampedHost {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Message,
        [switch]$NoNewLine,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )
    process {
        foreach ($line in $Message) {
            $timestamp = Get-Date -Format "HH:mm:ss"
            if ($NoNewLine) {
                Write-Host -NoNewline -ForegroundColor $ForegroundColor "[$timestamp] $line"
            }
            else {
                Write-Host -ForegroundColor $ForegroundColor "[$timestamp] $line"
            }
        }
    }
}

function Test-IsUserElevated {
    $CurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsIdentity)
    $runningElevated = $CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($runningElevated) {
        Write-TimestampedHostHost "Running elevated" -ForegroundColor Gray
        return $true
    }
    else {
        Write-TimestampedHost "Script is not running as elevated user. Will run aspects that require elevated rights in another process" -ForegroundColor Gray
        return $false
    }
}

#Function for running something elevated. Used later for importing certificates
function RunElevated ([string]$parameters) {
    $process = Start-Process -FilePath pwsh  -Verb runAs  -ArgumentList "-nop -c $parameters" -PassThru
    while (!$process.HasExited) {}
}
Set-Alias -Name Run-Elevated -Value runElevated -Description "Run a command elevated with admin privileges and wait untill it completes"

function Invoke-ElevatedCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ScriptBlock]$ScriptBlock,
        [Parameter(Mandatory = $false, Position = 1)]
        [Array]$Array = @()
    )

    # Check if the current session is already elevated
    if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole] "Administrator")) {
        # Convert the script block to a base64 encoded string
        $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptBlock.ToString()))

        # Convert the array to a string using a comma as the delimiter
        $arrayString = $Array -join ','

        # Start a new elevated PowerShell instance with the script block and array string as arguments and wait for it to exit
        $process = Start-Process -FilePath "pwsh.exe" -ArgumentList @('-Command', "iex([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedScript'))) -arrayString '$arrayString'") -Verb RunAs -PassThru
        $process.WaitForExit()
    }
    else {
        Write-Warning "The script is already running with elevated privileges."
        Invoke-Command -ScriptBlock $ScriptBlock
    }
}


function Test-K8sNodeIsAvailable {
    param(
        $ContextName
    )
    try {
        $nodeReady = kubectl get nodes --context $ContextName --no-headers  2>&1 | Where-Object { $_ -match "Ready" }
        if ($nodeReady) { return $true }
        return $false
    }
    catch { return $false }
}

function Reset-RancherCluster {
    param(
        $KubernetesVersion,
        $contextName
    )
    Write-TimestampedHost "Shutting down and resetting any existing Rancher-Desktop kubernetes instances" -ForegroundColor Cyan
    rdctl shutdown
    rdctl factory-reset
    Write-TimestampedHost "Rancher-Desktop shut down and reset" -ForegroundColor Green
    Write-TimestampedHost "Starting a new instance of Rancher-Desktop" -ForegroundColor Cyan
    rdctl start --container-engine.name=moby  --kubernetes.enabled=true  --kubernetes.version=$KubernetesVersion --kubernetes.options.traefik=false --application.telemetry.enabled=false --application.start-in-background=true
    Write-TimestampedHost "Waiting for the rancher-desktop node to become available. Takes about a minute depending on your hardware" -ForegroundColor White

    while ($true) {
        if (Test-K8sNodeIsAvailable -ContextName $ContextName) {
            Write-TimestampedHost "Rancher Desktop K8s cluster is now available" -ForegroundColor Green
            kubectx rancher-desktop
            kubectl config set-context rancher-desktop --user=rancher-desktop
            break
        }
        Write-TimestampedHost "Rancher Cluster not yet available. Waiting 10 seconds and trying again" -ForegroundColor Gray
        Start-Sleep -seconds 10
    }
}

function Bootstrap-FluxCD {
    param(
        $FluxBootstrapOptions
    )
    Write-TimestampedHost " Now we want to bootstrap FluxCD into the newly created cluster" -ForegroundColor Cyan
    $here = Get-Location
    Set-Location c:\  # Go to C drive to run the flux bootstrap command

    # Load System.Windows.Forms assembly    All this crap because we have to press yes.
    Add-Type -AssemblyName System.Windows.Forms
    $bootstrapProcess = Start-Process -FilePath "flux"  -ArgumentList "bootstrap $fluxBootstrapOptions" -PassThru
    # Wait for the new PowerShell window to appear
    Start-Sleep -Milliseconds 3000
    # Send 'y' followed by Enter to the active window
    [System.Windows.Forms.SendKeys]::SendWait("y{ENTER}")

    #Waiting untill flux bootstrap window closes
    while (!$bootstrapProcess.HasExited) {}
    Write-TimestampedHost "$(Get-Date -Format hh:mm:ss) Flux bootstrap has been completed. Now we wait for all the cluster infrastructure to be installed `n" -ForegroundColor Green
    Set-Location $here
}

function Test-IsPKIReady {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        $TestSecretName,
        [Parameter(Mandatory = $true, Position = 1)]
        $TestNamespace
    )

    Write-TimestampedHost "Looking for ingress-test namespace and secret. Then the CLuster Root CA is ready. This will take about 3 minutes" -ForegroundColor Cyan
    ## First we listen for the secret needed for TLS on ingress. It will fail on namespace a number of times untill it has been deployed
    while ($true) {
        try {
            $secret = kubectl get secret $TestSecretName -n $TestNamespace -o jsonpath='{.metadata.name}' 2> $null
            if ($secret -eq $testSecretName) {
                Write-TimestampedHost "Secret $TestSecretName is now available in the $TestNamespace namespace" -ForegroundColor Green
                break
            }
            else {
                Write-TimestampedHost "Secret $TestSecretName not found. Trying again in 30 seconds" -ForegroundColor Gray
                Start-Sleep -Seconds 30
            }
        }
        catch {
            Write-Error "Error occurred while checking for the secret. Look at what the cluster is doing and if FLux is throwing any errors. Use 'flux log -f' in another terminal" -ForegroundColor Red
        }
    }
}


function Test-Ingress {
    param(
        [uri]$TestUrl = "https://rd.local/foo/hostname"
    )
    try {
        $response = Invoke-WebRequest -Uri "$TestUrl" -Method Get
        if ($response.StatusCode -eq 200 -and $response.Content -eq "foo-app") {
            return $true
        }
        return $false
    }
    catch { return $false }
}


function Test-IsClusterReady {
    param(
        [uri]$TestUrl
    )
    if (-not $TestUrl) {
        Write-Error "TestURL is missing"
        exit
    }
    Write-TimestampedHost "Testing to see if the testservice has spun up. Usually only takes a couple of seconds from here. " -ForegroundColor Cyan
    while ($true) {
        if (Test-Ingress -TestUrl $TestUrl) {
            Write-TimestampedHost "Received 'foo-app' and HTTP 200. Kubernetes is now available for use. Ingress and TLS is working" -ForegroundColor Green
            break
        }
        Start-Sleep -Seconds 1
    }
}

