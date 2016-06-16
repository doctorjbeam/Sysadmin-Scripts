# Backup files from local desktop to network storage
# Last updated: 14/07/2014
# Author: Michael Greenhill

$backup_root = "\\curric.wheelers-hill-sc.wan\Users\Storage\Staff\" + $env:USERNAME;
$backup_dir = $backup_root + "\Desktop";

$folders = (
	"Documents",
	"Pictures",
	"Desktop"
);

# Create the backup user root directory if it doesn't exist, and set the appropriate permissions
if (!(Test-Path -PathType Container -Path $backup_root)) {
	New-Item -Path $backup_root -ItemType Container;
	
	$Acl = Get-Acl $backup_root;
	$Ar = New-Object system.security.accesscontrol.filesystemaccessrule($env:USERNAME, "FullControl", "Allow");
	$Acl.SetAccessRule($Ar);
	Set-Acl $backup_root $Acl;
}

Foreach ($item in $folders) {
	$Source = $env:USERPROFILE + "\" + $item;
	$Destination = $backup_dir + "\" + $item;
	
	& robocopy.exe $Source $Destination /MIR /DCOPY:T /COPY:DATS /R:3 /W:5 /MT:2;
}
