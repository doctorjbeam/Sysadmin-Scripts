<#
	Build images via MDT, import into WDS
	Selects images created in the last seven days, imports into WDS, imports from WDS into MDT, and updates the task sequences with the new images
#>

function Test-FileLock {
	param ([parameter(Mandatory=$true)][string]$Path)

	$oFile = New-Object System.IO.FileInfo $Path

	if ((Test-Path -Path $Path) -eq $false) {
		return $false
	}

	try {
		$oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
		if ($oStream) {
			$oStream.Close()
		}
		return $false
	} catch {
		# file is locked by a process.
		return $true
	}
}

Start-Transcript "$(Get-Location)\Build.log";
cls;

Import-Module WDS
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Set some variables
$newImageCutoff = (Get-Date).AddDays(-7);
$WdsClientImageGroup = "eduSTAR v6";
$WdsServerImageGroup = "Windows Server 2012 R2";
$WdsServer = "whscwds";
$MdtServer = "whscwds"
$ClientTaskSequenceId = "EDUSTAR-6-1511"
$ServerTaskSequenceId = "WHSC-2012R2"
$ClientImageRegex = "WHSC Classroom Gold Master [0-9]{4}-[0-9]{2}-[0-9]{2}"
$ServerImageRegex = "Windows Server 2012 R2 [0-9]{4}-[0-9]{2}-[0-9]{2}"

New-PSDrive -Name "DS002" -PSProvider MDTProvider -Root "\\$MdtServer\deploymentshare$" | Out-Null;

$knownClientImages = Get-WdsInstallImage -ImageGroup $WdsClientImageGroup | Where-Object FileName -like "WHSC Classroom Gold Master*"
$knownServerImages = Get-WdsInstallImage -ImageGroup $WdsServerImageGroup | Where-Object FileName -like "Windows Server 2012 R2*"
$availableClientImages = Get-ChildItem -Path "\\curric.wheelers-hill-sc.wan\deployment\Images\WDS\WHSC Classroom Gold Master*" | Where-Object CreationTime -gt $newImageCutoff | Where-Object Name -match "[0-9]{4}-[0-9]{2}-[0-9]{2}"
$availableServerImages = Get-ChildItem -Path "\\curric.wheelers-hill-sc.wan\deployment\Images\WDS\Windows Server*" | Where-Object CreationTime -gt $newImageCutoff | Where-Object Name -match "[0-9]{4}-[0-9]{2}-[0-9]{2}"

Write-Output "Known client images:"
$knownClientImages.FileName | ft;

Write-Output "`nKnown server images:"
$knownServerImages.FileName | ft;

Write-Output "`nClient images created since $($newImageCutoff.toString('yyyy-MM-dd')):"
$availableClientImages.Name | ft;

Write-Output "`nServer images created since $($newImageCutoff.toString('yyyy-MM-dd')):"
$availableServerImages.Name | ft;

Write-Output "`nProcessing client images"

Foreach ($image in $availableClientImages) {

	$clientImageDate = $image.CreationTime.toString("yyyy-MM-dd")
	
	if ($knownClientImages.FileName -Contains $image.Name) {
		continue; 
	}
	
	Write-Output "New image found: $($image.Name). Importing..."
	
	if (Test-FileLock $image.FullName) {
		Write-Warning "Not importing $($image.FullName) as it appears to be locked - possibly being written by MDT!"
		continue;
	}
	
	$imageName = [io.path]::GetFileNameWithoutExtension($image.FullName); 
	
	$WimInfo = (Get-WindowsImage -ImagePath $image.FullName -Index 1)
	
	#Import-WdsInstallImage -Path $image.FullName -ImageName $WimInfo.ImageName -ImageGroup $WdsImageGroup -NewImageName $imageName
	& WDSUtil /Add-Image /ImageFile:"$($image.FullName)" /Server:WHSCWDS /ImageType:Install /ImageGroup:$WdsClientImageGroup /SingleImage:"$($WimInfo.ImageName)" /Name:$imageName
	
	Write-Output "Image imported into WDS!"
}

Write-Output "`nProcessing server images"

Foreach ($image in $availableServerImages) {

	$serverImageDate = $image.CreationTime.toString("yyyy-MM-dd")
	
	if ($knownServerImages.FileName -Contains $image.Name) {
		continue; 
	}
	
	Write-Output "New image found: $($image.Name). Importing..."
	
	if (Test-FileLock $image.FullName) {
		Write-Warning "Not importing $($image.FullName) as it appears to be locked - possibly being written by MDT!"
		continue;
	}
	
	$imageName = [io.path]::GetFileNameWithoutExtension($image.FullName); 
	
	$WimInfo = (Get-WindowsImage -ImagePath $image.FullName -Index 1)
	
	#Import-WdsInstallImage -Path $image.FullName -ImageName $WimInfo.ImageName -ImageGroup $WdsClientImageGroup -NewImageName $imageName
	& WDSUtil /Add-Image /ImageFile:"$($image.FullName)" /Server:WHSCWDS /ImageType:Install /ImageGroup:$WdsServerImageGroup /SingleImage:"$($WimInfo.ImageName)" /Name:$imageName
	
	Write-Output "Image imported into WDS!"
}

Write-Output "Importing image(s) into MDT from WDS..."

Import-MdtOperatingSystem -Path "DS002:\Operating Systems" -WDSServer $WdsServer

Write-Output "Image(s) imported into MDT!"

Write-Output "`n------------------------------------------------`n"

Write-Output "Attempting to update task sequences with the most recent image"

$MdtOsXmlFile = "\\$MdtServer\DeploymentShare$\Control\OperatingSystems.xml"
[xml]$MdtOsXml = Get-Content $MdtOsXmlFile;

$NewestClientOs = ($MdtOsXml.oss.os | Where-Object Name -match $ClientImageRegex | Sort-Object -Property CreatedTime -Descending)

$MdtOsXmlFile = "\\$MdtServer\DeploymentShare$\Control\OperatingSystems.xml"
[xml]$MdtOsXml = Get-Content $MdtOsXmlFile;

$NewestServerOs = ($MdtOsXml.oss.os | Where-Object Name -match $ServerImageRegex | Sort-Object -Property CreatedTime -Descending)

$AllTaskSequencesFile = "\\$MdtServer\DeploymentShare$\Control\TaskSequences.xml"
[xml]$AllTaskSequences = Get-Content $AllTaskSequencesFile; 

if ($NewestClientOs.Count -gt 1) {
	Write-Output "Found $($NewestClientOs.Count) client operating system image(s) in MDT"
	
	$NewestClientOs | fl;
	
	# Manually sort the images, because using Sort-Object does shit all
	$selectedImage = $null; 
	
	$NewestClientOs | Foreach-Object {
		if ($selectedImage -eq $null) {
			$selectedImage = $_; 
			Write-Output " - Sorting client images"
			return; 
		}
		
		if ([DateTime]$_.CreatedTime -gt [DateTime]$selectedImage.CreatedTime) {
			Write-Output " - Found newer client image"
			$selectedImage = $_; 
			$clientImageDate = ([DateTime]$selectedImage.CreatedTime).toString("yyyy-MM-dd");
		}
	}
	
	$NewestClientOs = $selectedImage;
	
	Write-Output "Using newest (GUID $($NewestClientOs.GUID))"
}

if ($NewestServerOs.Count -gt 1) {
	Write-Output "Found $($NewestServerOs.Count) server operating system image(s) in MDT"
	
	$NewestServerOs | fl;
	
	# Manually sort the images, because using Sort-Object does shit all
	$selectedImage = $null; 
	
	$NewestServerOs | Foreach-Object {
		if ($selectedImage -eq $null) {
			$selectedImage = $_; 
			Write-Output " - Sorting client images"
			return; 
		}
		
		if ([DateTime]$_.CreatedTime -gt [DateTime]$selectedImage.CreatedTime) {
			Write-Output " - Found newer client image"
			$selectedImage = $_; 
	
			$serverImageDate = ([DateTime]$selectedImage.CreatedTime).toString("yyyy-MM-dd");
		}
	}
	
	$NewestServerOs = $selectedImage;
	
	Write-Output "Using newest (GUID $($NewestServerOs.GUID))"
}

if ($NewestClientOs -ne $null) {
	Write-Output "`nUpdating client task sequence..."
	$tsfile = "\\$MdtServer\DeploymentShare$\Control\$ClientTaskSequenceId\ts.xml";
	
	Write-Output "`nClient OS image details:"
	$NewestClientOs | fl;
	
	Write-Output " - using file $tsfile"
	[xml]$MdtClientXml = Get-Content $tsfile

	$MdtClientXml.sequence.globalVarList | Select-Object -ExpandProperty variable | Where-Object name -eq "OSGUID" | Foreach-Object { $_."#text" = [string]$NewestClientOs.guid }
	(($MdtClientXml.sequence.group | Where-Object name -eq "Install").step | Where-Object type -eq "BDD_InstallOS").DefaultVarList | Select-Object -ExpandProperty variable | Where-Object name -eq "OSGUID" | Foreach-Object { $_."#text" = [string]$NewestClientOs.guid }
	
	Write-Output " - Saving task sequence file"
	$MdtClientXml.Save($tsfile)
	
	Write-Output " - Setting version to $clientImageDate"
	$AllTaskSequences.tss.ts | Where-Object ID -eq $ClientTaskSequenceId | Foreach-Object { $_.Version = [string]$clientImageDate }
	$AllTaskSequences.Save($AllTaskSequencesFile)
}

if ($NewestServerOs -ne $null) {
	Write-Output "`nUpdating server task sequence..."
	$tsfile = "\\$MdtServer\DeploymentShare$\Control\$ServerTaskSequenceId\ts.xml";
	
	Write-Output "`nServer OS image details:"
	$NewestServerOs | fl;
	
	Write-Output " - using file $tsfile"
	[xml]$MdtServerXml = Get-Content $tsfile

	$MdtServerXml.sequence.globalVarList | Select-Object -ExpandProperty variable | Where-Object name -eq "OSGUID" | Foreach-Object { $_."#text" = [string]$NewestServerOs.guid }
	(($MdtServerXml.sequence.group | Where-Object name -eq "Install").step | Where-Object type -eq "BDD_InstallOS").DefaultVarList | Select-Object -ExpandProperty variable | Where-Object name -eq "OSGUID" | Foreach-Object { $_."#text" = [string]$NewestServerOs.guid }

	Write-Output " - Saving task sequence file"
	$MdtServerXml.Save($tsfile)
	
	Write-Output " - Setting version to $serverImageDate"
	$AllTaskSequences.tss.ts | Where-Object ID -eq $ServerTaskSequenceId | Foreach-Object { $_.Version = [string]$serverImageDate }
	$AllTaskSequences.Save($AllTaskSequencesFile)

}

Stop-Transcript; 
