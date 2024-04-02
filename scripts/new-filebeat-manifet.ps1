param (
	[Parameter(Mandatory = $true)]
	[string]
	$OldManifestPath,
	[Parameter(Mandatory = $true)]
	[string]
	$OldVersion,
	[Parameter(Mandatory = $true)]
	[string]
	$NewManifestPath,
	[Parameter(Mandatory = $true)]
	[string]
	$NewVersion
)


$TemplateContent = Get-Content $OldManifestPath


function Get-Sha512 {
	param (
		[string]
		$Version
	)
	$Response = Invoke-WebRequest -Uri "https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-$Version-windows-x86_64.zip.sha512" 
	$Sha512 = [Text.Encoding]::UTF8.GetString($Response.Content).Split(' ')[0]
	return $Sha512
}

$OldSha512 = Get-Sha512 -Version $OldVersion
$NewSha512 = Get-Sha512 -Version $NewVersion

$ManifestContent = $TemplateContent `
	-replace $OldVersion, $NewVersion `
	-replace $OldSha512, $NewSha512

$ManifestContent | Set-Content -Path $NewManifestPath