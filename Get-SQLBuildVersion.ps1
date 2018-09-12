function Get-SQLBuildVersion{
    <# 
        .SYNOPSIS 
            Check if your SQL Server version is updated. 

        .DESCRIPTION
            This command get a table with the latest version of your SQL Server Instance, based on https://buildnumbers.wordpress.com/sqlserver/
            Based on your build number, invoke a method to get a blog page and extract a table with most recent updates.
            
        .PARAMETER SqlInstance
            Receive a array with SQL instances that you want check.

        .PARAMETER CredentialEmail
            Credential object used to connect to your SMTP server.

        .PARAMETER SmtpServer
            Server to response your smpt requests like smtp.office365.com.
        
        .PARAMETER EmailTo
            Recipient of the email.
        
        .PARAMETER EmailFrom
            Account that send the e-mail.
        
        .NOTES
            Get more about author in https://blogdojamal.wordpress.com/

        .LINK
            https://github.com/Jamal27/SQLServer_Scripts/
        
        .EXAMPLE
            Get-SQLBuildVersion -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016"
            Get the latest version of your instance, in this example called SQLSERVER2016 and write output in console.
        
        .EXAMPLE
            $cred = Import-Clixml C:\Temp\cred.xml 
            Get-SQLBuildVersion -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016","DESKTOP-A7S2JPV\SQLSERVER2014" -SmtpServer "smtp.office365.com" -EmailFrom "reginaldo.silva27@gmail.com" -EmailTo "reginaldo.silva27@gmail.com" -CredentialEmail $cred 
        
            Get the latest version of yours instances, in this example called SQLSERVER2016, SQLSERVER2014 and send a e-mail report for each one.

   #>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]    
    [string[]]$SqlInstance,
    [PSCredential]$CredentialEmail,
    [string] $SmtpServer,
    [string] $EmailTo,
    [string] $EmailFrom
)

   #load page to a variable $data_page
   $data_page = Invoke-WebRequest "https://buildnumbers.wordpress.com/sqlserver/" -Verbose:$false
   
   #Get all tables on the page and put in a dataset, like a C# dataset.
   $data_tables = @($data_page.ParsedHtml.getElementsByTagName("TABLE"))
   
   #----------------------------------begin loop------------------------------------#   
   foreach ($instance in $SqlInstance) {
  
   #Load only first table
   $first_table = $data_tables[0]
   
   #Create array to header info
   $headers = @()
   
   #load all lines on variable $data_rows
   $data_rows = @($first_table.Rows)
   
   #control variable to stop the loop
   $return = $false

   $server = New-Object Microsoft.SqlServer.Management.Smo.Server $instance
   
          #Loop to find the version
          foreach($r in $data_rows)   
          {
              #Get cells of actual line 
              $cell = @($r.Cells)
          
              #add headers like C1, c2, c3...
              if(-not $headers)
              {
                  $headers = @(1..($cell.Count + 2) | % { "C$_" })
              }
          
              #Change headers name:
              for ($i = 0; $i -lt $headers.Count; $i++)
              {
                  $headers[$i] = $headers[$i].ToString().Replace("C1","Version").ToString().Replace("C2","RTM").ToString().Replace("C3","SP1").ToString().Replace("C4","SP2").ToString().Replace("C5","SP3").ToString().Replace("C6","SP4").ToString().Replace("C7","Latest")
              }
          
              $resultObject = [Ordered] @{}
          
              for($i = 0; $i -lt $cell.Count; $i++)
              {
                  $title = $headers[$i]
          
                  if(-not $title) { continue }       
          
                  $resultObject[$title] = ("" + $cell[$i].InnerText).Trim()
              }
          
              #if build was found, set variable $return
              foreach ($obj in $resultObject.Values)
              {
                  if($obj.Contains($server.VersionString.Substring(0,5)))
                  {
                      $return =$true
                  }
              }
          
              #stop internal loop
              if($return)
              {
                  $resultObject = [PSCustomObject] $resultObject
                  break
              }
          }#Endinternalloop

          if($SmtpServer -ne "" -and $EmailTo -ne "" -and $EmailFrom -ne "")
          {
                
              $ResultTestHtml = ""
              
              $count = 0
              
              #prepare HTML to send a e-mail
              ForEach($obj in $resultObject)
              {   
                  if($count.Equals(0))##Add a Header
                  {   
                      $ResultTestHtml +=  ConvertTo-Html -InputObject $obj -As List -Head '<h1 style="color:blue;">SQL SERVER VERSION:</h1><H3>UPDATED VERSION TABLE <H5><a href="https://buildnumbers.wordpress.com/sqlserver/">buildnumbers.wordpress.com</a></H5></H3>' 
                  }
                  else
                  {     
                      $ResultTestHtml +=  ConvertTo-Html -InputObject $obj -As List 
                  }    
                  $count +=1
              }
              
              $ResultTestHtml +=  '<br></br><H3>YOUR SQL SERVER VERSION</H3>'
              $ResultTestHtml +=  '<H5>'+"ProductLevel: " + [string]$server.ProductLevel+'</H5>'
              $ResultTestHtml +=  '<H5>'+"Version     : " + [string]$server.VersionString+'</H5>'
              $ResultTestHtml +=  '<H5>'+"Edition     : " + [string]$server.Edition+'</H5>'

              #check if your sql server version is updated
              if($resultObject.Latest.Substring(0,8) -ne $server.VersionString.Substring(0,8))
              {
                  $ResultTestHtml +=  '<H2 style="color:red;">HOUSTON WE HAVE A PROBLEM WITH YOUR SQL SERVER VERSION...</H2>'
              }
              else
              {
                  $ResultTestHtml +=  '<H2 style="color:blue;">KEEP CALM AND DRINK BEER! WE ARE UPDATED!!</H2>'
              }
                         
              #Subject of e-mail
              $Subject = "Check SQL Server Version - " + $server.Name
              
              #Send e-mail
              Send-MailMessage -Credential $CredentialEmail -SmtpServer $SmtpServer -To $EmailTo -From $EmailFrom -Subject $Subject -UseSsl -Body $ResultTestHtml -BodyAsHtml -Priority High
          }
          else
          {
            #Outpu for console
            $Version = "YOUR SQL VERSION:`n`nProductLevel : " + $server.ProductLevel
            $Version += "`nBuild        : " + $server.VersionString
            $Version += "`nEdition      : " + $server.Edition + "`n`n"

            "#### " + $server.Name + " ####"
            "`nUPDATED VERSION TABLE:"
            $resultObject
            $Version
          }
          
    }#endloopsqlinstance
}

