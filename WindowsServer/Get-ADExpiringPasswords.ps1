Start-Transcript C:\Scripts\Get-ADExpiringPassword.log; 

Import-Module ActiveDirectory;

$expireInDays    = 14;
$start    	     = [datetime]::Now;
$midnight 	     = $start.Date.AddDays(1);
$timeToMidnight  = New-TimeSpan -Start $start -end $midnight.Date;
$midnight2       = $start.Date.AddDays(2);
$timeToMidnight2 = New-TimeSpan -Start $start -end $midnight2.Date;
$textEncoding    = [System.Text.Encoding]::UTF8;
$today           = $start;

# Get Users From AD who are Enabled, Passwords Expire and are not currently expired
$users = Get-AdUser -Filter {(Enabled -eq $true) -and (PasswordNeverExpires -eq $false)} -Properties Name,PasswordNeverExpires,PasswordExpired,PasswordLastSet,EmailAddress;

# Count Users
$usersCount = ($users | Measure-Object).Count;
Write-Output "Found $usersCount User Objects";

# Collect Domain Password Policy Information
$defaultMaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy -ErrorAction Stop).MaxPasswordAge.Days;
Write-Output "Domain Default Password Age: $defaultMaxPasswordAge";

# Collect Users
$colUsers = @();

# Process Each User for Password Expiry
Write-Output "Loop through found users to find expiring passwords";

foreach ($user in $users) {
	#Write-Output "`n`n-----`n`n";
	
    $pwdLastSet = $user.PasswordLastSet;
	
    # Check for Fine Grained Password
    $maxPasswordAge = $defaultMaxPasswordAge;
    $PasswordPol    = Get-AduserResultantPasswordPolicy $user; 
	
    if ($PasswordPol -ne $null) {
        $maxPasswordAge = $PasswordPol.MaxPasswordAge.Days;
    }
	
	if (($maxPasswordAge -eq 0) -or ($maxPasswordAge -eq $null)) {
		# Skip this user
		continue; 
	}
    
	# Create User Object
    $userObj = New-Object System.Object;
    $expireson = $pwdLastSet.AddDays($maxPasswordAge);
    $daysToExpire = New-TimeSpan -Start $today -End $Expireson;
	
	if (((Get-Date) - $user.PasswordLastSet).Days -gt $maxPasswordAge) {
		$daysToExpire = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddHours(6);
		Write-Warning "The password for $($user.SamAccountName) was last changed $(((Get-Date) - $user.PasswordLastSet).Days) days ago"
	}
    
	# Round Up or Down
    if (($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -le $timeToMidnight.TotalHours)) {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "today.";
    } 
	
	if (($daysToExpire.Days -eq "0") -and ($daysToExpire.TotalHours -gt $timeToMidnight.TotalHours) -or ($daysToExpire.Days -eq "1") -and ($daysToExpire.TotalHours -le $timeToMidnight2.TotalHours)) {
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "tomorrow.";
    }
	
    if (($daysToExpire.Days -ge "1") -and ($daysToExpire.TotalHours -gt $timeToMidnight2.TotalHours)) {
        $days = $daysToExpire.TotalDays;
        $days = [math]::Round($days);
        $userObj | Add-Member -Type NoteProperty -Name UserMessage -Value "in $days days.";
    }
	
    $daysToExpire = [math]::Round($daysToExpire.TotalDays)
	
	if ($daysToExpire -gt $expireInDays) { 
		continue; 
	}
	
    $userObj | Add-Member -Type NoteProperty -Name UserName -Value $user.SamAccountName;
    $userObj | Add-Member -Type NoteProperty -Name GivenName -Value $user.GivenName;
    $userObj | Add-Member -Type NoteProperty -Name EmailAddress -Value $user.EmailAddress;
    $userObj | Add-Member -Type NoteProperty -Name PasswordSet -Value $pwdLastSet;
    $userObj | Add-Member -Type NoteProperty -Name DaysToExpire -Value $daysToExpire;
    $userObj | Add-Member -Type NoteProperty -Name ExpiresOn -Value $expiresOn;
    $userObj | Add-Member -Type NoteProperty -Name MaxPasswordAge -Value $maxPasswordAge;
    $colUsers += $userObj;
}

$colUsers | ft; 

$colUsers | Export-CSV "C:\Temp\ExpiringSoon.csv"; 

Stop-Transcript; 