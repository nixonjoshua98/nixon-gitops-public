# Install-Module powershell-yaml

param(
    [switch]$deploy
)

#
#
# Common functions
#
#

function Get-ConfigFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Config file not found: $Path"
    }

    $rawConfig = Get-Content -Path $Path -Raw | ConvertFrom-Yaml

    $controlPlanes = @($rawConfig.controlplanes)
    $bootstrapIp = $rawConfig.bootstrapIp
    $hasBootstrapNode = ([string]::IsNullOrWhiteSpace($bootstrapIp) -eq $false)
    $clusterEndpointIp = $bootstrapIp

    if ([string]::IsNullOrWhiteSpace($clusterEndpointIp)) {
        $clusterEndpointIp = $controlPlanes[0]
    }

    return [pscustomobject]@{
        BootstrapIp          = $bootstrapIp
        ClusterEndpointIp    = $clusterEndpointIp
        HasBootstrapNode     = $hasBootstrapNode
        K3sVersion           = $rawConfig.k3sVersion
        Agents               = @($rawConfig.agents)
        ControlPlanes        = $controlPlanes
        ClusterUrl           = "https://${clusterEndpointIp}:6443"
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [string]$Value = "",
        [int]$LabelWidth = 18
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Value = "-"
    }

    $formatted = "{0,-$LabelWidth} : {1}" -f $Label, $Value
    Write-Host $formatted
}


function Create-StringHash($string) {
    $stream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($string))

    return (Get-FileHash -InputStream $stream -Algorithm SHA256).Hash
}

function Get-RemoteScpTarget([string]$target) {
    return "root@$target"
}

function Get-K3sInstallerScriptPath {
    return Join-Path ([System.IO.Path]::GetTempPath()) "get.k3s.io"
}

function Get-CacheDirectory {
    return Join-Path $PSScriptRoot "../.tmp"
}

function Get-K3sBinaryPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    return Join-Path (Get-CacheDirectory) "k3s-$Version"
}

function Get-K3sBinaryUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $arch = "amd64"
    $assetName = if ($arch -eq "amd64") { "k3s" } else { "k3s-$arch" }
    return "https://github.com/k3s-io/k3s/releases/download/$Version/$assetName"
}

function Download-K3sInstallerScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    Invoke-WebRequest `
        -Uri "https://get.k3s.io" `
        -OutFile $OutputPath `
        -ErrorAction Stop | Out-Null

    return $OutputPath
}

function Download-K3sBinary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $outputDirectory = Split-Path -Parent $OutputPath

    if (-not (Test-Path -Path $outputDirectory)) {
        [System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }

    $binaryUrl = Get-K3sBinaryUrl -Version $Version

    Invoke-WebRequest `
        -Uri $binaryUrl `
        -OutFile $OutputPath `
        -ErrorAction Stop | Out-Null

    return $OutputPath
}

#
#
# SSH functions
#
#

function Invoke-SshCommand($target, $command, [switch]$void) {
    if ($void) {
        & ssh -i $sshKeyPath -o StrictHostKeyChecking=no -q -n "root@$target" "$command" | Out-Null
    } else {
        $output = & ssh -i $sshKeyPath -o StrictHostKeyChecking=no -q "root@$target" "$command "
    }

    if ($LASTEXITCODE -ne 0) {
        throw "SSH command ('$command') failed for host '$target'"
    }

    if ($null -ne $output) {
        return ($output | Out-String).Trim()
    }
}

function Copy-InstallerScriptToTarget($target, $installerScriptPath) {
    $remoteTarget = Get-RemoteScpTarget -target $target

    & scp -i $sshKeyPath -o StrictHostKeyChecking=no $installerScriptPath "$($remoteTarget):/tmp/get.k3s.io"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy K3s installer script to host '$target'"
    }

    Invoke-SshCommand -target $target -command "chmod +x /tmp/get.k3s.io" -void

    Write-Log -Label "K3S script" -Value "OK"
}

function Copy-K3sBinaryToTarget($target, $binaryPath) {
    $remoteTarget = Get-RemoteScpTarget -target $target

    & scp -i $sshKeyPath -o StrictHostKeyChecking=no $binaryPath "$($remoteTarget):/usr/local/bin/k3s"

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy K3s binary to host '$target'"
    }

    Invoke-SshCommand -target $target -command "chmod 755 /usr/local/bin/k3s" -void

    Write-Log -Label "K3S binary" -Value "OK"
}

function Get-Kubeconfig($target, $serverIp, $outputPath) {
    $kubeconfig = Invoke-SshCommand `
        -target $target `
        -command "cat /etc/rancher/k3s/k3s.yaml"

    $kubeconfig = $kubeconfig -replace '127\.0\.0\.1', $serverIp
    
    Set-Content -Path $outputPath -Value $kubeconfig -Encoding utf8

    Write-Log -label "Kubeconfig" -value $outputPath
}

function Get-ServerToken($target) {
    return Invoke-SshCommand `
        -target $target `
        -command "cat /var/lib/rancher/k3s/server/node-token"
}

function Wait-CommandOutput($target, $command, $expected, $retryIntervalSeconds = 1, $timeoutSeconds = 60) {   
    $start = Get-Date

    while ($true) {
        $status = Invoke-SshCommand -target $target -command $command
        
        if ($status -eq $expected) {
            return
        }

        Start-Sleep -Seconds $retryIntervalSeconds
    }
}

function Wait-ActiveSystemService([string]$target, [string]$service) {   
    Wait-CommandOutput `
        -Target $target `
        -Command "systemctl is-active $service" `
        -Expected "active"
}

function Get-InstallHash($target) {
    return Invoke-SshCommand `
        -target $target `
        -command "if [ -f $installHashFile ]; then cat $installHashFile; else echo ''; fi"
}

function Set-InstallHash($target, $hash) {
    Invoke-SshCommand `
        -target $target `
        -command "echo '$hash' > $installHashFile"
}

#
#
# K3S commands
#
#

function New-AgentCommand($clusterUrl, $token, $agentIp) {
    $extraArgs = @(
        "--node-external-ip $agentIp"
    ) + $staticInstallArgs

    $extraArgs = $extraArgs -join ' '

    return "INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=""$k3sVersion"" K3S_URL=""$clusterUrl"" K3S_TOKEN=""$token"" INSTALL_K3S_EXEC=""$extraArgs"" sh /tmp/get.k3s.io"
}

function New-ClusterInitCommand($serverIp) {
    $extraArgs = @(
        "--cluster-init"
        "--tls-san $serverIp"
        "--node-external-ip $serverIp"
    ) + $staticControlPlaneInstallArgs

    $extraArgs = $extraArgs -join ' '

    return "INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=""$k3sVersion"" INSTALL_K3S_EXEC=""$extraArgs"" sh /tmp/get.k3s.io"
}

function New-ControlPlaneCommand($clusterUrl, $token, $serverIp) {
    $extraArgs = @(
        "--tls-san $serverIp"
        "--node-external-ip $serverIp"
    ) + $staticControlPlaneInstallArgs

    $extraArgs = $extraArgs -join ' '

    return "INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_VERSION=""$k3sVersion"" K3S_URL=""$clusterUrl"" K3S_TOKEN=""$token"" INSTALL_K3S_EXEC=""$extraArgs"" sh /tmp/get.k3s.io"
}

#
#
# Install process
#
#

function Run-InstallProcess($target, $command, $service, $installerScriptPath) {
    $existingHash   = Get-InstallHash -target $target
    $installHash    = Create-StringHash -string $command
    $needsUpdating  = $existingHash -ne $installHash

    Write-Log -label "Needs updating" -value $needsUpdating

    if ($installHash -eq $existingHash) {
        return
    }

    if ($deploy -ne $true) {
        return
    }

    Copy-InstallerScriptToTarget -target $target -installerScriptPath $installerScriptPath
    
    Copy-K3sBinaryToTarget -target $target -binaryPath $k3sBinaryPath

    Invoke-SshCommand -target $target -command $command -void

    Write-Log -label "Waiting..."

    Wait-ActiveSystemService -target $target -service $service

    Write-Log -label "Updating hash..."

    Set-InstallHash -target $target -hash $installHash
}

#
#
# Configuration 
#
#

$clusterNetworkInterface = "enp7s0"
$installHashFile         = "/var/lib/rancher/k3s/install-command-hash"
$clusterYamlFilePath     = Join-Path $PSScriptRoot "cluster.yaml"
$kubeconfigFilePath      = Join-Path $PSScriptRoot "kubeconfig.yaml"
$sshKeyPath              = Join-Path $PSScriptRoot "../.ssh/ssh_key"
$clusterConfig           = Get-ConfigFile -Path $clusterYamlFilePath
$clusterBootstrapIp      = $clusterConfig.BootstrapIp
$clusterEndpointIp       = $clusterConfig.ClusterEndpointIp
$hasBootstrapNode        = $clusterConfig.HasBootstrapNode
$k3sVersion              = $clusterConfig.K3sVersion
$agents                  = @($clusterConfig.Agents)
$controlplanes           = @($clusterConfig.ControlPlanes)
$clusterKubeUrl          = $clusterConfig.ClusterUrl
$k3sInstallerScriptPath  = Get-K3sInstallerScriptPath
$k3sBinaryPath           = Get-K3sBinaryPath -Version $k3sVersion

#
#
# K3S install arguments
#
#

$staticInstallArgs = @(
    "--flannel-iface=$($clusterNetworkInterface)"
    "--kubelet-arg=max-pods=20"
    "--kubelet-arg=kube-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
    "--kubelet-arg=system-reserved=cpu=100m,memory=200Mi,ephemeral-storage=3Gi"
)

$staticControlPlaneInstallArgs = @(
    "--disable-cloud-controller"
    "--disable traefik"
    "--disable metrics-server"
    "--write-kubeconfig-mode 644"
    "--kubelet-arg=cloud-provider=external"
    "--node-taint=node-role.kubernetes.io/control-plane=:PreferNoSchedule"
) + $staticInstallArgs

#
#
# Validation 
#
#

if ($hasBootstrapNode -eq $true -and ($controlplanes -notcontains $clusterBootstrapIp)) {
    Write-Log -label "Error" -value "Bootstrap IP must be present in the control planes when explicitly set."
    exit 1
}

#
#
# Summary 
#
#

Write-Log -label "Cluster URL"          -Value $clusterKubeUrl
Write-Log -label "Endpoint IP"          -Value $clusterEndpointIp
Write-Log -label "Control planes"       -Value ($controlplanes -join ", ")
Write-Log -label "Agents"               -Value ($agents -join ", ")
Write-Log -label "K3s version"          -Value $k3sVersion
Write-Log -label "Deploying"            -Value $deploy
Write-Log -label "----------"

#
#
# Pre-deploy checks
#
#

$clusterExistingHash = Get-InstallHash -target $clusterEndpointIp

if ($deploy -ne $true -and [string]::IsNullOrWhiteSpace($clusterExistingHash)) {
    Write-Log -label "Dry run only" -value "Re-run with -deploy to bootstrap and join nodes."
    exit 0
}

if (-not (Test-Path -Path $k3sBinaryPath)) {
    Download-K3sBinary -Version $k3sVersion -OutputPath $k3sBinaryPath | Out-Null
}

if ($deploy -eq $true) {
    Download-K3sInstallerScript -OutputPath $k3sInstallerScriptPath | Out-Null
}

#
#
# Bootstrap node
#
#

if ($hasBootstrapNode) {
    Write-Log -label "Control plane (B)" -value $clusterEndpointIp

    $clusterInitCommand = New-ClusterInitCommand `
        -serverIp $clusterEndpointIp

    Run-InstallProcess `
        -target $clusterEndpointIp `
        -command $clusterInitCommand `
        -service "k3s" `
        -installerScriptPath $k3sInstallerScriptPath

    Write-Log -Label "----------"
}

#
#
# Load server token
#
#

$serverToken = Get-ServerToken -target $clusterEndpointIp

Write-Log -label "Server token" -value $serverToken
Write-Log -label "----------"

#
#
# Download kubeconfig
#
#

if ($deploy -eq $true) {
    Get-Kubeconfig `
        -target $clusterEndpointIp `
        -serverIp $clusterEndpointIp `
        -outputPath $kubeconfigFilePath
}

#
#
# Control planes
#
#

foreach ($controlplane in $controlplanes) {
    if ($controlplane -eq $clusterBootstrapIp) {
        continue
    }

    $installCommand = New-ControlPlaneCommand `
        -clusterUrl $clusterKubeUrl `
        -token $serverToken `
        -serverIp $controlplane

    Write-Log -Label "Control plane" -Value $controlplane

    Run-InstallProcess `
        -Target $controlplane `
        -Command $installCommand `
        -Service "k3s" `
        -installerScriptPath $k3sInstallerScriptPath

    Write-Log -Label "----------"
}

#
#
# Agents
#
#

foreach ($agent in $agents) {
    $installCommand = New-AgentCommand `
        -clusterUrl $clusterKubeUrl `
        -token $serverToken `
        -agentIp $agent

    Write-Log -Label "Agent" -Value $agent

    Run-InstallProcess `
        -Target $agent `
        -Command $installCommand `
        -Service "k3s-agent" `
        -installerScriptPath $k3sInstallerScriptPath

    Write-Log -Label "----------"
}
