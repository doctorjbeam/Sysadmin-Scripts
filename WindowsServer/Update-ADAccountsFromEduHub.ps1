# Loop through data extracted from eduHub and create/move student accounts as required
# Last updated 20/06/2017
# Author Michael Greenhill

# Path to the eduHub data
$eduHubData = "C:\temp";

Start-Transcript "$eduHubData\AccountSetup.log";

# School number
$schoolNumber = 8474;

# Get the year (eg 2015)
$year = Get-Date -Format yyyy

# Build the CSV path
$csvPath = $eduHubData + "\ST_" + $schoolNumber + ".csv";

Write-Output $csvPath;

$dataSource = Import-CSV $csvPath | Where-Object {$_.STATUS -eq "ACTV"}

Foreach ($dataRecord in $dataSource) {
	#Write-Output $dataRecord.HOME_GROUP; 
	$yearLevel = [regex]::match($dataRecord.HOME_GROUP, "([0-9]{2})").Groups[1].Value;
	
	$dstOU = "OU=Year " + $yearLevel +",OU=$year,OU=Students,DC=curric,DC=wheelers-hill-sc,DC=wan";
	$username = $dataRecord.STKEY;
	
	Write-Output "Username: $username";
	Write-Output "$dstOU";
	
	# Look for an existing user, and move them if we need to
	try {
		$User = Get-ADUser -Identity $username;
		
		try {
			Write-Output "Checking if this user is in the correct OU..."
			
			# Check if this user is not in the correct OU
			if ($User.DistinguishedName -NotMatch $dstOU) {
				
				Write-Output "Updating group membership";
				
				# Loop through user's group memberships
				Foreach ($Group in (Get-ADUser -Identity $username -Properties MemberOf | Select-Object MemberOf).MemberOf | Get-ADGroup) {
					
					# If group name matches Students - Year xx remove them from the group
					if ($Group.Name -Match "Students - Year") {
						Write-Output " - Removing user from"$Group.Name;
						Remove-ADGroupMember -Identity $Group -Members $User -Confirm:$false;
					}
				}
				
				Write-Output " - Adding student to Students - Year $yearLevel";
				
				# Add to LDAP group (eg Students - Year 08)
				Add-ADGroupMember -Identity "Students - Year $yearLevel" -Members $User -Confirm:$false;
				
				# Move the user to the correct OU at the end to stop "Directory object not found" errors
				Write-Output "Moving $username into $dstOU";
				Move-AdObject -Identity $User -TargetPath $dstOU;
			} else {
				Write-Output "User is in the correct OU"
			}
		} catch {
			Write-Output $Error[0].Exception;
		}

		
	} catch {
		# User not found - create them
		Write-Output "$username not found in AD: creating user";
		
		try {
			# Connect to LDAP
			$objOU=[ADSI]"LDAP://$dstOU"
			
			$dob = $dataRecord.BIRTHDATE;
			$dob = $dob.Substring(0, $dob.IndexOf(" ")).Replace("/", "").PadLeft(8, "0"); 
			$email = $username.ToLower() + "@whsc.vic.edu.au";
			
			
			# Create a new user
			$objUser = $objOU.Create("user", "CN="+$dataRecord.PREF_NAME+" "+$dataRecord.SURNAME)
			$objUser.Put("sAMAccountName", $username)
			$objUser.Put("userPrincipalName", "$username@whsc.vic.edu.au")
			$objUser.Put("displayName", $dataRecord.PREF_NAME+" "+$dataRecord.SURNAME)
			$objUser.Put("givenName", $dataRecord.PREF_NAME)
			$objUser.Put("sn", $dataRecord.SURNAME)
			$objUser.SetInfo(); 
			$objUser.SetPassword($dob)
			$objUser.psbase.InvokeSet("AccountDisabled", $false); 
			$objUser.SetInfo();
			
			# Change password at logon, set email address
			Set-ADUser -Identity $username -ChangePasswordAtLogon:$true -Email $email
			
			Write-Output " - Adding student to Students - Year"$yearLevel;
			
			# Add to LDAP group (eg Students - Year 08)
			Add-ADGroupMember -Identity "Students - Year $yearLevel" -Members $username -Confirm:$false;
		} catch {
			Write-Output $Error[0].Exception;
		}
	}
	
	Write-Output "`n--------------------------------------------------------------------------`n";
}

Stop-Transcript;