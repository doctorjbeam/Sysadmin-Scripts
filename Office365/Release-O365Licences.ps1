# Remove Office 365 licences for users in our exit OUs
# @updated 8/06/2016
# @author Michael Greenhill

Start-Transcript "C:\Scripts\Office 365\Release-O365Licences.log";

function Remove-O365Licences {
	Param (
		$exitUsers
	)
	
	foreach ($User in $exitUsers) {
	
		Write-Output "-----------------------------------"; 
		
		$userName = $User.SamAccountName; 
		$mail = (Get-ADUser $User.distinguishedName -properties mail).mail
		
		# Check for an empty email address
		if ($mail -eq $null) {
			Write-Warning "!! Skipping $userName as mail attribute is empty !! "; 
			continue; 
		}
		
		# Check for an invalid email address
		if (!$mail.Contains("whsc.vic.edu.au")) {
			Write-Warning "!! Skipping $userName as mail attribute does not contain whsc.vic.edu.au !!"; 
			continue; 
		}
		
		Write-Output "Processing $userName"; 
		
		$msolUser = Get-MsolUser -UserPrincipalName $mail;
		
		foreach ($license in $msolUser.Licenses) {
			Write-Output " - Releasing license for $($license.AccountSkuId)"; 
			Set-MsolUserLicense -UserPrincipalName $mail -RemoveLicenses $license.AccountSkuId;
		}

	}
}

Write-Output "Enforcing proxy settings"; 
& netsh winhttp set proxy 10.142.204.19:8080 "<local>;wsus*;whsc-server04*;*.wan"

Write-Output "Connecting to MsolService"; 
$secpasswd = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 
$Cred = New-Object System.Management.Automation.PSCredential ("admin@wheelershillsc.onmicrosoft.com", $secpasswd);

Connect-MsolService -Credential $Cred;

$exitStaff    = Get-AdUser -Filter * -SearchBase "OU=Exit,OU=Staff,DC=curric,DC=wheelers-hill-sc,DC=wan"; 
$exitStudents = Get-AdUser -Filter * -SearchBase "OU=Exit,OU=Students,DC=curric,DC=wheelers-hill-sc,DC=wan"; 

Remove-O365Licences $exitStaff; 
Remove-O365Licences $exitStudents; 

Stop-Transcript;