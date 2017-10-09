<#
	
	Find eduSTAR certs that need to be renewed/replaced
	
	@author Michael Greenhill
	@updated 12/09/2016
	
#>

$t = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
add-type -name win -member $t -namespace native
[native.win]::ShowWindow(([System.Diagnostics.Process]::GetCurrentProcess() | Get-Process).MainWindowHandle, 0)

Start-Transcript "C:\Setup\CertImport.log"

Write-Output "Attempting to renew eduSTAR.NET wireless certificate"

$machineCerts = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Issuer -like "*services-CERTS-CA*" }
$rootCerts = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Issuer -like "*DEET*" }
$intermediateCerts = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { $_.Issuer -like "*DEET*" }
$certFileRootPath = "C:\Setup\WirelessCert"
$certPassword = ConvertTo-SecureString -String "SOOPERSECURlolzx" -Force –AsPlainText

if (!(Test-Path "$certFileRootPath\*" -include *.pfx)) {
	Write-Warning "$certFileRootPath cannot be reached or has no valid PFX files; exiting"
	break; 
}

Foreach ($cert in Get-ChildItem "$certFileRootPath\*.pfx") {

	$certName = ($cert | Select-Object -Property @{label='CertName';expression={$_.Name -replace '.pfx'}}).CertName;
	
	$certPath = "$certFileRootPath\$certName.pfx";
	
	Write-Output "Processing $certName";
	
	if (!(Test-Path -Path $certPath)) {
		Write-Warning "!! Renewal PFX file $certPath does not exist or is inaccessible !!"
		continue; 
	}
	
	try {
		Import-PfxCertificate -FilePath "$certPath" -Password $certPassword
		Write-Output "$certName has been renewed";
	} catch {
		Write-Warning "$certName was not replaced"
	}
}

Stop-Transcript; 