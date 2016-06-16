# Create folders for new staff and assign permissions
# Last updated 20/5/2013
# @author Michael Greenhill

cls

Start-Transcript "Q:\New Staff.log";

Write-Host "Looking through CURRIC\All Staff group";
Write-Host "";

$Users = Get-ADGroupMember -Identity "All Staff" -Recursive

foreach ($User in $Users) {
	$UserName = $User.sAMAccountName
	$directory = "\\curric.wheelers-hill-sc.wan\Users\Staff\$UserName"
	
	Write-Host "Checking $UserName"
	
	if (!(Test-Path -path $directory)) {
		Write-Host "$directory does not exist - creating";
		
		New-Item $directory -type directory | Out-Null
		
		if ($acct = New-Object System.Security.Principal.NTAccount("CURRIC", $UserName)) {
			Write-Host " - Setting permissions for $UserName";
			
			icacls.exe $directory /grant "CURRIC\${UserName}:(OI)(CI)(M)" | Out-Null
			icacls.exe $directory /deny "CURRIC\${UserName}:(OI)(CI)(WDAC)" | Out-Null
			icacls.exe $directory /deny "CURRIC\${UserName}:(NP)(DE)" | Out-Null
			
			Get-Acl $directory | Format-List
		}
		
		Write-Host "";
	}
}

Write-Host "Finished!";

Stop-Transcript;