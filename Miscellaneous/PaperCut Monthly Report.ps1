<#
	@author Michael Greenhill
	@updated 10/10/2017
#>

Start-Transcript "C:\Scripts\PaperCut Monthly Report.log";

# CSV file settings
$file = "C:\Program Files\PaperCut MF\server\data\scheduled-reports\AccountSummary.csv";
$modTime = (Get-Item $file).LastWriteTime; 
$dstFileName = (Get-Date).AddMonths(-1) | Get-Date -Format "yyyy-MM MMMMM";
$dstPath = "C:\Program Files\PaperCut MF\server\data\scheduled-reports\$dstFileName.csv"; 

# Email settings
$msgSubject = "PaperCut Account summary $dstFileName";

# Start summarising
$csvData = Get-Content -Path $file | Select-Object -Skip 2 | Out-String | ConvertFrom-Csv

$parentAccounts = @(); 

foreach ($row in $csvData) {

	$account = $parentAccounts | Where Account -eq $row.'Shared Account Parent Name';
	
	if ($account -eq $null) {
		$account = New-Object System.Object; 
		$account | Add-Member -Type NoteProperty -Name Account -Value $row.'Shared Account Parent Name';
		$account | Add-Member -Type NoteProperty -Name Charges -Value $row.Cost;
		$account | Add-Member -Type NoteProperty -Name Pages -Value $row.'Total Printed Pages';
		$account | Add-Member -Type NoteProperty -Name Jobs -Value $row.'Jobs';
		
		$parentAccounts += $account; 
		continue; 
	}
	
	[float]$account.Charges += [float]($row.Cost);
	[float]$account.Pages += [float]$row.'Total Printed Pages';
	[float]$account.Jobs += [float]$row.Jobs; 
}

# Temporarily save the file
$parentAccounts | Export-CSV -NoType $dstPath;

# Send the email
$att = New-Object Net.Mail.Attachment($dstPath);
$msg = New-Object Net.Mail.MailMessage; 
$smtp = New-Object Net.Mail.SmtpClient($smtpServer); 

$msg.Subject = $msgSubject; 
$msg.From = $msgFromAddress; 
$msg.To.Add($msgToAddress);
$msg.Attachments.Add($att); 
$msg.Body = @"
Hi there,

Please see the attached print summary for $dstFileName. This was based on the PaperCut MF automated report found on WHSCPRINTSRV01 at $file, generated on $modTime. 

A copy of this file will be saved to $networkSavePath. 

Regards,
The ghost of Michael Greenhill. 
"@

$smtp.Send($msg); 
$att.Dispose(); 

# Move the CSV to a network location
If (!(Test-Path $networkSavePath)) {
	mkdir $networkSavePath; 
}

Move-Item $dstPath $networkSavePath -Force;

Stop-Transcript; 
