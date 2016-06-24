# Set Office 365 licenses and ServicePlan availability based on AD group membership
# @updated 8/06/2016
# @author Michael Greenhill

Start-Transcript "C:\Scripts\Office 365\Set-O365Licences.log";

function Set-O365LicensesForGroup {
	Param (
		[parameter(Mandatory=$true)][string] $adGroupName,
		[parameter(Mandatory=$true)][string] $o365Product,
		$disabledPlans = @() 
	)
	
	Write-Output "`n`nProcessing group ""$adGroupName"" for SKU ""$o365Product"""; 
	Write-Output "Disabled ServicePlans: ";
	$disabledPlans | ft
	Write-Output "`n"; 
	
	# Get the list of group members to iterate over
	$GroupMembers = Get-ADGroupMember -Identity $adGroupName -Recursive;
	
	foreach ($User in $GroupMembers) {
		
		Write-Output "-----------------------------------"; 
		
		$userName = $User.SamAccountName; 
		$mail = (Get-ADUser $User.distinguishedName -properties mail).mail
		$enabled = (Get-ADUser $User.distinguishedName -properties enabled).enabled; 
		
		if ($enabled -eq $false) {
			Write-Warning "!! $userName is disabled - skipping !!"; 
			continue; 
		}
		
		$userDisabledPlans = $disabledPlans; 
		
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
		
		# Determine products to enable
		
		[System.Collections.ArrayList]$ArrayList = $userDisabledPlans; 
		
		# Check if the user is in the Yammer group
		$hasYammer = (isUserInGroup "O365-Staff-Yammer" $User.SamAccountName) -or (isUserInGroup "O365-Student-Yammer" $User.SamAccountName); 
		
		if ($hasYammer) {
			$ArrayList.Remove("YAMMER_EDU"); 
		}
		
		# Check if the user is in the Lync group
		$hasLync = (isUserInGroup "O365-Staff-Lync" $User.SamAccountName) -or (isUserInGroup "O365-Student-Lync" $User.SamAccountName); 
		
		if ($hasLync) {
			$ArrayList.Remove("MCOSTANDARD"); 
		}
		
		# Check if the user is in the Exchange Online group
		$hasExchangeOnline = (isUserInGroup "O365-Staff-ExchangeOnline" $User.SamAccountName) -or (isUserInGroup "O365-Student-ExchangeOnline" $User.SamAccountName); 
		
		if ($hasExchangeOnline) {
			# Remove ExchangeOnline from the list of plans to disable from the user's license
			# i.e. keep it!
			$ArrayList.Remove("EXCHANGE_S_STANDARD"); 
		}
		
		$userDisabledPlans = $ArrayList; 
		
		if ($userDisabledPlans.Count -eq 0) {
			Write-Host "Enabling all ServicePlans"; 
		} else {
			Write-Host "ServicePlans to disable: ";
			$userDisabledPlans | ft; 
		}
		
		#continue; 
		
		# Set our license options
		$ProductOptions = New-MsolLicenseOptions -AccountSkuId $o365Product -DisabledPlans $userDisabledPlans; 
		
		# Find licenes assigned to this user
		$msolUser = Get-MsolUser -UserPrincipalName $mail;
		
		$hasLicense = $false; 
		
		# Set the user's usage location (ie country)
		Write-Output " - Setting UsageLocation"; 
		Set-MsolUser -UserPrincipalName $mail -UsageLocation "AU";
		
		# Check if this has already been assigned this license, and update if they have
		foreach ($license in $msolUser.Licenses) {
			if ($license.AccountSkuId -eq $o365Product) {
				$hasLicense = $true; 
				Write-Output " - Updating existing license";
				Set-MsolUserLicense -UserPrincipalName $mail -LicenseOptions $ProductOptions; 
				break; 
			}
		}
		
		# Get out if we've updated
		if ($hasLicense) {
			continue; 
		}
		
		# Assign a new license
		Write-Output " - Assigning license for SKU with product options"; 
		Set-MsolUserLicense -UserPrincipalName $mail -AddLicenses $o365Product -LicenseOptions $ProductOptions; 
		
		
	}
}

function isUserInGroup {
	Param (
		[parameter(Mandatory=$true)][string] $adGroupName,
		[parameter(Mandatory=$true)][string] $SamAccountName
	)
	
	$GroupMembers = Get-ADGroupMember -Identity $adGroupName -Recursive;
	
	foreach ($User in $GroupMembers) {
		if ($User.SamAccountName -eq $SamAccountName) {
			Write-Host "$samAccountName is a member of $adGroupName"; 
			return $true; 
		}
	}
	
	return $false; 
}

Write-Output "Enforcing proxy settings"; 
& netsh winhttp set proxy 10.142.204.19:8080 "<local>;wsus*;whsc-server04*;*.wan"

Write-Output "Connecting to MsolService"; 
$secpasswd = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 
$Cred = New-Object System.Management.Automation.PSCredential ("admin@wheelershillsc.onmicrosoft.com", $secpasswd);

Connect-MsolService -Credential $Cred;

# Office 365 Education Plus for Faculty
Set-O365LicensesForGroup "O365-Staff" "wheelershillsc:STANDARDWOFFPACK_IW_FACULTY" @("YAMMER_EDU", "MCOSTANDARD", "EXCHANGE_S_STANDARD"); 

# Set the timezone and language for all users
Write-Output "Setting the timezone and langauge for all users";

Write-Output "Creating Exchange Online session and importing";
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection;
Import-PSSession $Session -AllowClobber;

Get-Mailbox -Filter {RecipientTypeDetails -eq 'UserMailbox'} | Set-MailboxRegionalConfiguration -Timezone "AUS Eastern Standard Time" -Language 3081

Remove-PSSession $Session; 

Stop-Transcript; 