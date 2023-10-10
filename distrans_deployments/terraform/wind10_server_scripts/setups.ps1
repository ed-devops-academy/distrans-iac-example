[CmdletBinding()]

param 
( 
    [Parameter(ValuefromPipeline=$true,Mandatory=$true)] [string]$RepoPAT,
    [string]$FirewallIP = "192.168.10.120",
    [string]$ServerName,
    [string]$InstallerPath = "https://github.com/prometheus-community/windows_exporter/releases/download/v0.24.0/windows_exporter-0.24.0-amd64.msi", 
    [string]$Collectors = "cpu,cs,logical_disk,net,os,service,system,textfile,memory,iis,mssql,exchange"
)

# clean params
# $PatFormatted = $RepoPAT.Trim("}")
# $CollectorsFormatted = $Collectors.

#################################################################################
##################### Azure agent installation and setup ########################
#################################################################################
Write-Host "Starting installation and setup of azure agent"

Install-WindowsFeature -Name Web-Server -IncludeAllSubFeature -IncludeManagementTools

$ErrorActionPreference="Stop"
If(-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] "Administrator")){ 
    throw "Run command in an administrator PowerShell prompt"
}

If($PSVersionTable.PSVersion -lt (New-Object System.Version("3.0"))){ 
    throw "The minimum version of Windows PowerShell that is required by the script (3.0) does not match the currently running version of Windows PowerShell." 
}
If(-NOT (Test-Path $env:SystemDrive\'azagent')){
    mkdir $env:SystemDrive\'azagent'
}

cd $env:SystemDrive\'azagent'

for($i=1; $i -lt 100; $i++){
    $destFolder="A"+$i.ToString()
    if(-NOT (Test-Path ($destFolder))){
        mkdir $destFolder
        cd $destFolder
        break
    }
}

$agentZip="$PWD\agent.zip"
$DefaultProxy=[System.Net.WebRequest]::DefaultWebProxy
$securityProtocol=@()
$securityProtocol+=[Net.ServicePointManager]::SecurityProtocol
$securityProtocol+=[Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol=$securityProtocol
$WebClient=New-Object Net.WebClient
$Uri='https://vstsagentpackage.azureedge.net/agent/3.220.0/vsts-agent-win-x64-3.220.0.zip'

if($DefaultProxy -and (-not $DefaultProxy.IsBypassed($Uri))){
    $WebClient.Proxy= New-Object Net.WebProxy($DefaultProxy.GetProxy($Uri).OriginalString, $True)
}

$WebClient.DownloadFile($Uri, $agentZip)
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory( $agentZip, "$PWD")
[System.Environment]::SetEnvironmentVariable('VSTS_AGENT_INPUT_TOKEN',"$RepoPAT")
.\config.cmd --deploymentgroup --deploymentgroupname "Production" --agent $env:COMPUTERNAME --runasservice --work '_work' --url 'https://dev.azure.com/musalaDevOpsAcademy/' --unattended --projectname 'SuperCheap Application' --replace --auth PAT --token $RepoPAT
Remove-Item $agentZip

Write-Host "Finnished installation and setup of azure agent"

#################################################################################
############## Installation and setup of prometheus exporter ####################
#################################################################################
Write-Host "Starting installation and setup of prometheus exporter"

$env:HostIP = (
    Get-NetIPConfiguration |
    Where-Object {
        $_.IPv4DefaultGateway -ne $null -and
        $_.NetAdapter.Status -ne "Disconnected"
    }
).IPv4Address.IPAddress

# Get installer filename from path
$InstallerFilename = Split-Path -Path $InstallerPath -Leaf;


If ( -not (Test-Path -Path "C:\Temp")){   
    New-Item -Path "C:\" -Name "Temp" -ItemType "directory";
}
# Download installer to c:\temp folder
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
Invoke-WebRequest -Uri $InstallerPath -OutFile "c:\Temp\$InstallerFilename"

# Run msiexec as Admin (UAC) to install exporter service
$ArgStmt = "/i ""c:\Temp\$InstallerFilename"" ENABLED_COLLECTORS=""$Collectors""";
Start-Process -FilePath msiexec.exe -ArgumentList $ArgStmt -Verb RunAs -Wait;

# Remove installer 
Remove-Item -Path "c:\Temp\$InstallerFilename" -Force;

# Scope exporter firewall rule to Prometheus server IP
Get-NetFirewallRule -DisplayName 'windows_exporter (HTTP )' | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress Any;
    
# Modify exporter service to reset fail count after 1 day and restart service after 5 minutes to allow for server patching reboots
Start-Process -FilePath sc.exe -ArgumentList "\\$ServerName failure windows_exporter reset=86400 actions=restart/300000" -Verb RunAs -Wait;


Write-Host "Finnished installation and setup of prometheus exporter"