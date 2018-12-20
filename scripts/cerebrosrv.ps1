#Requires -RunAsAdministrator
<#
    Install, starts, stops, and removes Windows Service for Cerebro.
#>
param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet('install', 'start', 'stop', 'remove')]
    $command,
    [Parameter(Mandatory = $false, Position = 2)]
    $serviceName = 'cerebro'
)
$ErrorActionPreference = 'Stop'

# Ensure backwards compatability
$PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { split-path $MyInvocation.MyCommand.Path }

if ($command -eq 'install') {
    get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
    if ($?) {
        Write-Error "$serviceName service already exists. So quitting."
    }

    $cerebroAppFile = "$PSScriptRoot\bin\cerebro.bat"

    $logsDirectory = "$PSScriptRoot\logs"
    if (-not(test-path -Path $logsDirectory -PathType Container)) { mkdir $logsDirectory | out-null }

    nssm install $serviceName $cerebroAppFile
    Write-host "Setting application directory to $PSScriptRoot"
    nssm set $serviceName AppDirectory "$PSScriptRoot\bin"
    nssm set $serviceName AppStdout "$logsDirectory\stdout.log"
    nssm set $serviceName AppStderr "$logsDirectory\stderr.log"
    nssm set $serviceName AppRotateFiles 1
    nssm set $serviceName AppRotateOnline 1
    nssm set $serviceName AppRotateSeconds 86400
    nssm set $serviceName AppRotateBytes 1048576
    Write-host "Created service $serviceName. To start service, type: $(split-path $MyInvocation.MyCommand.Path -Leaf) start"
    Exit 0
}

get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
if (!$?) {
    Write-Error "Service with name '$serviceName' not found. So quitting."
}

if (@('start', 'stop') -contains $command) {
    nssm $command $serviceName
    if ($command -eq 'start') {
        Write-host "Started $serviceName. Visit UI at http://localhost:9000"
    }
    Exit 0
}

if ($command -eq 'remove') {
    nssm remove $serviceName confirm
    Exit 0
}

# You should not get here!
Write-error "Something when awry. I don't know the command $command"
