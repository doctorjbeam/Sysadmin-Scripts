Start-Transcript "C:\Scripts\Password Expiry Warning\transcript.log"; 

."C:\Scripts\Password Expiry Warning\PasswordChangeNotification.ps1" -smtpServer smtp.blah.com -expireInDays 21 -from "IT Support <it@blah.com>" -Logging -LogPath "C:\Scripts\Password Expiry Warning\Log" -status #-testing -testrecipient "you@blah.com"; 

Stop-Transcript;