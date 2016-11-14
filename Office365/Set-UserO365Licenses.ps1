<#
	Set Office 365 licenses and ServicePlan availability based on AD group membership
	@updated 15/11/2016
	@author Michael Greenhill
	
	Lines to customise: 
		30 - ADFS tenant
		36 - ADFS admin username
		42 - ADFS admin password
		91 - Email address domain
	
#>

Start-Transcript "C:\Scripts\Office 365\Set-O365Licences.log";

<#
	This is your Office 365 SKU namespace. 
	To find your tenant, first connect to the MSOL service
	
	Connect-MsolService
	
	Then, run Get-MsolAccountSku
	
	Your available SKUs will be prefixed with (probably) your .onmicrosoft.com address - eg
	wheelershillsc:CLASSDASH_PREVIEW
	
	This command will show all the SKUs available to you. To resolve an SKU name to an actual product, run 
#>

$Office365Tenant = "wheelershillsc";

<#
	O365 admin username. This cannot be a federated user. Typically admin@tenant.onmicrosoft.com
#>

$adminUsername = "admin@$Office365Tenant.onmicrosoft.com"

<#
	O365 admin password
#>

$adminPassword = Get-Content "C:\Scripts\Office 365\Credential.txt" | ConvertTo-SecureString; 

<#
	O365 admin password - optional cleartext password example
	
	$cleartextPassword = "SuperSecretPasswordShhh"
	$adminPassword = Convertto-SecureString –String $cleartextPassword –AsPlainText –force
	
#>

function Set-O365LicensesForGroup {
	Param (
		[parameter(Mandatory=$true)][string] $adGroupName, # AD security group which contains members to assign licenses to 
		[parameter(Mandatory=$true)][string] $o365Product, # The Office 365 product SKU we're assigning to the above users 
		$disabledPlans = @() # A list of SKU features which are disabled for all users. These can be overridden based on AD group membership below
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
		
		# If the AD user is disabled then there's no point in processing them. This might change at a future date to release licenses from this user
		if ($enabled -eq $false) {
			Write-Warning "!! $userName is disabled - skipping !!"; 
			continue; 
		}
		
		# Alias $disabledPlans (disabled SKU features) for this user 
		$userDisabledPlans = $disabledPlans; 
		
		# Check for an empty email address - if it's empty we can assume they're not an Office 365 user
		if ($mail -eq $null) {
			Write-Warning "!! Skipping $userName as mail attribute is empty !! "; 
			continue; 
		}
		
		# Check for an invalid email address - if it doesn't match our domain then we can assume they're not an O365 user
		if (!$mail.Contains("whsc.vic.edu.au")) {
			Write-Warning "!! Skipping $userName as mail attribute does not contain whsc.vic.edu.au !!"; 
			continue; 
		}
		
		Write-Output "Processing $userName"; 
		
		# Determine products to enable
		
		[System.Collections.ArrayList]$ArrayList = $userDisabledPlans; 
		
		# Check if the user is in the Yammer group
		$hasYammer = (isUserInGroup "O365-Staff-Yammer" $User.SamAccountName) -or (isUserInGroup "O365-Student-Yammer" $User.SamAccountName); 
		
		# If they're in the Yammer group, remove Yammer from the list of disabled SKU features
		if ($hasYammer) {
			$ArrayList.Remove("YAMMER_EDU"); 
		}
		
		# Check if the user is in the Lync group
		$hasLync = (isUserInGroup "O365-Staff-Lync" $User.SamAccountName) -or (isUserInGroup "O365-Student-Lync" $User.SamAccountName); 
		
		# If they're in the Lync group, remove Lync from the list of disabled SKU features
		if ($hasLync) {
			$ArrayList.Remove("MCOSTANDARD"); 
		}
		
		# Check if the user is in the Exchange Online group
		$hasExchangeOnline = (isUserInGroup "O365-Staff-ExchangeOnline" $User.SamAccountName) -or (isUserInGroup "O365-Student-ExchangeOnline" $User.SamAccountName); 
		
		# If they're in the ExchangeOnline group, remove ExchangeOnline from the list of disabled SKU features
		if ($hasExchangeOnline) {
			$ArrayList.Remove("EXCHANGE_S_STANDARD"); 
		}
		
		$userDisabledPlans = $ArrayList; 
		
		if ($userDisabledPlans.Count -eq 0) {
			Write-Host "Enabling all ServicePlans"; 
		} else {
			Write-Host "ServicePlans to disable: ";
			$userDisabledPlans | ft; 
		}
		
		# Create a new license option which we'll apply to this user
		$ProductOptions = New-MsolLicenseOptions -AccountSkuId $o365Product -DisabledPlans $userDisabledPlans; 
		
		# Find licenes assigned to this user - we're trying to only apply the difference between the above new license and the current license
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

# Check if a user is in an AD security group
function isUserInGroup {
	Param (
		[parameter(Mandatory=$true)][string] $adGroupName, # AD security group name
		[parameter(Mandatory=$true)][string] $SamAccountName # AD user samAccountName
	)
	
	# Get all group members
	$GroupMembers = Get-ADGroupMember -Identity $adGroupName -Recursive;
	
	foreach ($User in $GroupMembers) {
		if ($User.SamAccountName -eq $SamAccountName) {
			Write-Host "$samAccountName is a member of $adGroupName"; 
			return $true; 
		}
	}
	
	return $false; 
}

# Connect to the MSOL service using the credentials defined at the top of this script
Write-Output "Connecting to MsolService"; 
$Cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword);

Connect-MsolService -Credential $Cred;

# Set Office 365 licenses for staff
Set-O365LicensesForGroup "O365-Staff" "$Office365Tenant:STANDARDWOFFPACK_IW_FACULTY" @("YAMMER_EDU", "MCOSTANDARD", "EXCHANGE_S_STANDARD"); 

# Set Office 365 licenses for students 
Set-O365LicensesForGroup "O365-Student" "$Office365Tenant:STANDARDWOFFPACK_IW_STUDENT" @("YAMMER_EDU", "MCOSTANDARD", "EXCHANGE_S_STANDARD"); 

# Set the timezone and language for all users
Write-Output "Setting the timezone and langauge for all users";

Write-Output "Creating Exchange Online session and importing";
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell -Credential $Cred -Authentication Basic -AllowRedirection;
Import-PSSession $Session -AllowClobber;

# Set the timezone and langauge on all ExchangeOnline mailboxes to avoid the first logon prompt. This takes a long time! 
Get-Mailbox -Filter {RecipientTypeDetails -eq 'UserMailbox'} | Set-MailboxRegionalConfiguration -Timezone "AUS Eastern Standard Time" -Language 3081

Remove-PSSession $Session; 

Stop-Transcript; 