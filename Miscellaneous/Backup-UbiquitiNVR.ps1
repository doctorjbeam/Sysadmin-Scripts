Start-Transcript "\\curric.wheelers-hill-sc.wan\IT Admin\Scripts\Backups\NVR.log";

$date = Get-Date -Format "yyyy-MM-dd hh.mm";
$dst = "\\curric.wheelers-hill-sc.wan\Backups\Servers\nvr01\Config";
$limit = (Get-Date).AddDays(-90);
$apikey = "haha no you don't"

Invoke-WebRequest -Uri "http://nvr01.whsc.vic.edu.au:7080/api/2.0/backup?apiKey=$apikey" -OutFile "$dst\backup_$date.zip";

Get-ChildItem -Path $dst -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force; 

Stop-Transcript;  