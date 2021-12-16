#Requires -RunAsAdministrator
<#
    Install, starts, stops, and removes Windows Service for Kibana.
#>
param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateSet('install', 'start', 'stop', 'remove')]
    $command,
    [Parameter(Mandatory = $false, Position = 2)]
    $serviceName = 'logstash',
    [Parameter(Mandatory = $false, Position = 3)]
    $configFile
)
$ErrorActionPreference = 'Stop'

# Ensure backwards compatability
$PSScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { split-path $MyInvocation.MyCommand.Path }

if ($command -eq 'install') {
    get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
    if ($?) {
        Write-Error 'Logstash service already exists. So quitting.'
    }

    if (-not($configFile)) {
        Write-error "-configFile needs to be specified for install command"
    }

    $configPath = resolve-path $configFile
    if (-not(test-path -path $configPath -pathtype leaf)) {
        Write-error "Configuration file not found: $configFile"
    }

    $logstashAppFile = "$PSScriptRoot\bin\logstash.bat"
    $dataDir = "$PSScriptRoot\data\$serviceName"

    $logsDirectory = "$PSScriptRoot\logs"
    if (-not(test-path -Path $logsDirectory -PathType Container)) { mkdir $logsDirectory | out-null }

    nssm install $serviceName $logstashAppFile "-f `"$configPath`" --path.data `"$dataDir`""
    Write-host "Setting application directory to $PSScriptRoot"
    nssm set $serviceName AppDirectory "$PSScriptRoot\bin"
    nssm set $serviceName AppStdout "$logsDirectory\$serviceName-stdout.log"
    nssm set $serviceName AppStderr "$logsDirectory\$serviceName-stderr.log"
    nssm set $serviceName AppRotateFiles 1
    nssm set $serviceName AppRotateOnline 1
    nssm set $serviceName AppRotateSeconds 86400
    nssm set $serviceName AppRotateBytes 52428800
    Write-host "Created service $serviceName. To start service, type: $(split-path $MyInvocation.MyCommand.Path -Leaf) start"
    Exit 0
}

get-service $serviceName -ErrorAction 'SilentlyContinue' | out-null
if (!$?) {
    Write-Error "Logstash service with name '$serviceName' not found. So quitting."
}

if (@('start', 'stop') -contains $command) {
    nssm $command $serviceName
    if ($command -eq 'start') {
        Write-host "Started Logstash service."
    }
    Exit 0
}

if ($command -eq 'remove') {
    nssm remove $serviceName confirm
    Exit 0
}

# You should not get here!
Write-error "Something when awry. I don't know the command $command"
