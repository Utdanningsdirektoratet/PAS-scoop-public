#Requires -RunAsAdministrator
<#
    Install, starts, stops, and removes Windows Service for telegraf.
#>
param(
	[Parameter(Mandatory=$true,Position=1)]
	[ValidateSet('install','start','stop','remove')]
	$command,
	[Parameter(Mandatory=$false,Position=2)]
	$serviceName = 'telegraf',
    [Parameter(Mandatory=$false,Position=3)]
    $configFile
)
$ErrorActionPreference = 'Stop'

# Ensure backwards compatability
$PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { split-path $MyInvocation.MyCommand.Path }

if ($command -eq 'install') {
	get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
    if ($?) {
        Write-Error '$serviceName service already exists. So quitting.'
    }

    $configPath = resolve-path $configFile
    if (-not(test-path -path $configPath -pathtype leaf)) {
        Write-error "Configuration file not found: $configFile"
    }

    $telegrafAppFile = "$PSScriptRoot\telegraf.exe"

    $logsDirectory = "$PSScriptRoot\logs"
    if (-not(test-path -Path $logsDirectory -PathType Container)) { mkdir $logsDirectory | out-null }

    nssm install $serviceName $telegrafAppFile "--config `"$configPath`""
    Write-host "Setting application directory to $PSScriptRoot"
    nssm set $serviceName AppDirectory "$PSScriptRoot\bin" 2>&1 | out-null
    nssm set $serviceName AppStdout "$logsDirectory\stdout.log" 2>&1 | out-null
    nssm set $serviceName AppStderr "$logsDirectory\stderr.log" 2>&1 | out-null
    Write-host "Created service $serviceName. To start service, type: $(split-path $MyInvocation.MyCommand.Path -Leaf) start"
	Exit 0
}

get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
if (!$?) {
    Write-Error "Service with name '$serviceName' not found. So quitting."
}

if (@('start','stop') -contains $command) {
    nssm $command $serviceName
    Exit 0
}

if ($command -eq 'remove') {
    nssm remove $serviceName confirm
    Exit 0
}

# You should not get here!
Write-error "Something when awry. I don't know the command $command"
