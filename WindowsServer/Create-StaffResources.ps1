$dstFolder = "Q:\Staff Resources\2016"

If (!(Test-Path -path $dstFolder)) {
	New-Item $dstFolder -Type Directory
}

# These folders will be assigned special permissions to prevent staff from adding folders to the root
$protectedFolders = @(
	"$dstFolder",
	"$dstFolder\Photos\Student ID Photos",
	"$dstFolder\Learning Areas"
);

# Reset ACL to inherited
icacls.exe $dstFolder /reset /T
#icacls.exe $dstFolder /deny "CURRIC\Teachers:(NP)(WD,AD,DC,D)"

cd $dstFolder

# Create the following folders
New-Item "_Applications for Installation Only" -Type Directory;
New-Item "_Student Course Selections" -Type Directory;
New-Item "1stclass" -Type Directory;
New-Item "ADMIN-OFFICE" -Type Directory;
New-Item "ADMIN-OFFICE\PSD" -Type Directory;
New-Item "Art Show" -Type Directory;
New-Item "Careers" -Type Directory;
New-Item "Curriculum" -Type Directory;
New-Item "E&E Data" -Type Directory;
New-Item "Learning Areas" -Type Directory;
New-Item "Library" -Type Directory;
New-Item "Minutes of Meetings" -Type Directory;
New-Item "Photos" -Type Directory;
New-Item "Presentation Ball" -Type Directory;
New-Item "Presentations" -Type Directory;
New-Item "Production" -Type Directory;
New-Item "Professional Development" -Type Directory;
New-Item "Report Resources" -Type Directory;
New-Item "Ultranet" -Type Directory;
New-Item "VASS" -Type Directory;
New-Item "Videos" -Type Directory;
New-Item "XEROX-SCANS" -Type Directory;
New-Item "Youth Commitment" -Type Directory;

New-Item "Sub Schools" -Type Directory;

New-Item "Teaching and Learning\Administration" -Type Directory;
New-Item "Teaching and Learning\Domains" -Type Directory;
New-Item "Teaching and Learning\Professional Readings" -Type Directory;

New-Item "Photos\Student ID Photos\Year 07" -Type Directory;
New-Item "Photos\Student ID Photos\Year 08" -Type Directory;
New-Item "Photos\Student ID Photos\Year 09" -Type Directory;
New-Item "Photos\Student ID Photos\Year 10" -Type Directory;
New-Item "Photos\Student ID Photos\Year 11" -Type Directory;
New-Item "Photos\Student ID Photos\Year 12" -Type Directory;


New-Item "Learning Areas\Curriculum" -Type Directory;
New-Item "Learning Areas\English" -Type Directory;
New-Item "Learning Areas\Health & PE" -Type Directory;
New-Item "Learning Areas\Humanities" -Type Directory;
New-Item "Learning Areas\LOTE" -Type Directory;
New-Item "Learning Areas\Mathematics" -Type Directory;
New-Item "Learning Areas\Science" -Type Directory;
New-Item "Learning Areas\Sport" -Type Directory;
New-Item "Learning Areas\Technology" -Type Directory;
New-Item "Learning Areas\The Arts" -Type Directory;
New-Item "Learning Areas\Urban" -Type Directory;

# Set permissions
icacls.exe "$dstFolder\1stclass" /grant "CURRIC\First Class:(OI)(CI)(M)"

icacls.exe "$dstFolder\_Student Course Selections" /grant "CURRIC\First Class:(OI)(CI)(M)"

icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /inheritance:d
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /grant "CURRIC\Domain Admins:(OI)(CI)(M)"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /grant "CURRIC\Administrators:(OI)(CI)(M)"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /grant "CURRIC\PSD:(OI)(CI)(M)"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /remove "CURRIC\Teachers"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /remove "CURRIC\Support Staff"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /remove "CURRIC\Admin Office"
icacls.exe "$dstFolder\ADMIN-OFFICE\PSD" /remove "Users"

icacls.exe "Teaching and Learning\Administration" /inheritance:d
icacls.exe "Teaching and Learning\Administration" /grant "CURRIC\Domain Admins:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Administration" /grant "CURRIC\Administrators:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Administration" /grant "CURRIC\Teaching & Learning:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Administration" /grant "CURRIC\Principals:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Administration" /remove "CURRIC\Teachers"
icacls.exe "Teaching and Learning\Administration" /remove "CURRIC\Support Staff"
icacls.exe "Teaching and Learning\Administration" /remove "CURRIC\Admin Office"
icacls.exe "Teaching and Learning\Administration" /remove "Users"
icacls.exe "Teaching and Learning" /deny "CURRIC\Teachers:(NP)(AD)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Support Staff:(NP)(AD)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Admin Office:(NP)(AD)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Teachers:(NP)(DC)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Support Staff:(NP)(DC)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Admin Office:(NP)(DC)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Teachers:(NP)(DE)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Support Staff:(NP)(DE)"
icacls.exe "Teaching and Learning" /deny "CURRIC\Admin Office:(NP)(DE)"
icacls.exe "Teaching and Learning\Professional Readings" /inheritance:d
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Domain Admins:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Administrators:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Teaching & Learning:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Principals:(OI)(CI)(M)"
icacls.exe "Teaching and Learning\Professional Readings" /remove "CURRIC\Teachers"
icacls.exe "Teaching and Learning\Professional Readings" /remove "CURRIC\Support Staff"
icacls.exe "Teaching and Learning\Professional Readings" /remove "CURRIC\Admin Office"
icacls.exe "Teaching and Learning\Professional Readings" /remove "Users"
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Teachers:(OI)(CI)(R)"
icacls.exe "Teaching and Learning\Professional Readings" /grant "CURRIC\Support Staff:(OI)(CI)(R)"

# Stop staff from buggering with these "protected" folders
foreach ($item in $protectedFolders) {
	icacls.exe "$item" /deny "CURRIC\Teachers:(NP)(D,WDAC,WO,WD,AD,DC)"
	icacls.exe "$item" /deny "CURRIC\Support Staff:(NP)(DE)"
	icacls.exe "$item" /deny "CURRIC\Admin Office:(NP)(DE)"

	#icacls.exe "$item" /deny "CURRIC\Teachers:(NP)(AD)"
	icacls.exe "$item" /deny "CURRIC\Support Staff:(NP)(AD)"
	icacls.exe "$item" /deny "CURRIC\Admin Office:(NP)(AD)"

	#icacls.exe "$item" /deny "CURRIC\Teachers:(NP)(DC)"
	icacls.exe "$item" /deny "CURRIC\Support Staff:(NP)(DC)"
	icacls.exe "$item" /deny "CURRIC\Admin Office:(NP)(DC)"

	$SubFolders = Get-ChildItem -Path $item;

	foreach ($FirstLevel in $SubFolders) {
		icacls.exe $FirstLevel.FullName /deny "CURRIC\Teachers:(NP)(DE)"
		icacls.exe $FirstLevel.FullName /deny "CURRIC\Support Staff:(NP)(DE)"
		icacls.exe $FirstLevel.FullName /deny "CURRIC\Admin Office:(NP)(DE)"
	}
}