#navigate to folder that you save files
####### ALTER HERE #######
Set-Location C:\temp\

#Load function Get-SQLBuildVersion to memory of this powershell session
. .\Get-SQLBuildVersion.ps1

#Import your email credential, you can export using this command: Get-Credential | Export-Clixml C:\Temp\credemail.xml, put yours credentials on the pop-up and save it.
####### ALTER HERE #######
$cred = Import-Clixml C:\Temp\credemail.xml 

#Call function with your parameters
####### ALTER HERE #######
Get-SQLBuildVersion -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016","DESKTOP-A7S2JPV\SQLSERVER2014" -SmtpServer "smtp.gmail.com" -EmailFrom "reginaldo.silva27@gmail.com" -EmailTo "reginaldo.silva27@gmail.com" -CredentialEmail $cred 