<#
	Update stored domain credentials
	@author Michael Greenhill
	@updated 14/06/2017
#>


if ((Get-Module CredentialManager) -eq $null) {
	Install-Module CredentialManager -force
}

$hasValidCred = $false;

# Keep prompting for credentials until domain name equals "CURRIC"

While ($hasValidCred -eq $false) {
	$cred = Get-Credential -Message "Enter your domain username and password"; 
	
	if ($cred.GetNetworkCredential().Domain -eq "CURRIC") { 
		$hasValidCred = $true; 
	}
}

$username = $cred.GetNetworkCredential().Username; 

Write-Output "Updating stored credentials for domain user $username"; 

$storedCreds = Get-StoredCredential -AsCredentialObject; 

$storedCreds | Where UserName -like "*$($cred.GetNetworkCredential().Domain)\$($cred.GetNetworkCredential().Username)*" | Foreach { 
	
	if ($_.TargetName -notlike "Domain:target=*") {
		Write-Warning "$($_.TargetName) is not a domain target - skipping"; 
		continue; 
	}
	
	Write-Output "Updating stored credential for $($_.TargetName)"; 
	
	New-StoredCredential -Target $_.TargetName -Credential $cred -Persist Enterprise -Type DomainPassword | Out-Null; 
}