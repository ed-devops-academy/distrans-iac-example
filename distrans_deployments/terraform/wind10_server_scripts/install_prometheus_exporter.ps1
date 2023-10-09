[CmdletBinding()]


Param(
    # [string]$FirewallIP = "192.168.10.120",
    [string]$ServerName,
    [string]$InstallerPath = "https://github.com/prometheus-community/windows_exporter/releases/download/v0.24.0/windows_exporter-0.24.0-amd64.msi", 
    [string]$Collectors = "cpu,cs,logical_disk,net,os,service,system,textfile,memory,iis,mssql,exchange"
    
)
# Get installer filename from path
$InstallerFilename = Split-Path -Path $InstallerPath -Leaf;

Invoke-Command -ComputerName $ServerName -ScriptBlock {
    If ( -not (Test-Path -Path "C:\Temp")){   
        New-Item -Path "C:\" -Name "Temp" -ItemType "directory";
    }
    # Download installer to c:\temp folder
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    Invoke-WebRequest -Uri $using:InstallerPath -OutFile "c:\Temp\$using:InstallerFilename"

    # Run msiexec as Admin (UAC) to install exporter service
    $ArgStmt = "/i ""c:\Temp\$using:InstallerFilename"" ENABLED_COLLECTORS=""$using:Collectors""";
    Start-Process -FilePath msiexec.exe -ArgumentList $ArgStmt -Verb RunAs -Wait;

    # Remove installer 
    Remove-Item -Path "c:\Temp\$using:InstallerFilename" -Force;

    # Scope exporter firewall rule to Prometheus server IP
    # Get-NetFirewallRule -DisplayName 'windows_exporter (HTTP )' | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $using:FirewallIP;
    
    # Modify exporter service to reset fail count after 1 day and restart service after 5 minutes to allow for server patching reboots
    Start-Process -FilePath sc.exe -ArgumentList "\\$using:ServerName failure windows_exporter reset=86400 actions=restart/300000" -Verb RunAs -Wait;
}