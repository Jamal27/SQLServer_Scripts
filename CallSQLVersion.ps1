#Load SMO
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")  

#navigate to folder
Set-Location C:\temp\

#Load function Get-SQLBuildVersion to memory of this session
. .\Get-SQLBuildVersion.ps1

#Import your email credential
$cred = Import-Clixml C:\Temp\cred.xml 

#Call function with your parameters
Get-SQLBuildVersion -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016","DESKTOP-A7S2JPV\SQLSERVER2014" -SmtpServer "smtp.office365.com" -EmailFrom "reginaldo.silva@dataside.com.br" -EmailTo "reginaldo.silva@dataside.com.br" -CredentialEmail $cred 

