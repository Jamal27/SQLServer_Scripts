#Load SMO 
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null

#Put your SQL Server instance
$SqlInstance = "DESKTOP-A7S2JPV\SQLSERVER2017"
#Choice a dbname to be created
$Sqldb = "NameIT_DB"
#Number of lines to be inserted on table tb_users
$QtdLines = 1000

#Connect and create database
$srv = new-Object Microsoft.SqlServer.Management.Smo.Server($SqlInstance)  
$db = New-Object Microsoft.SqlServer.Management.Smo.Database($srv, $Sqldb)  
$db.Create()  

#Create the Table called tb_users
$tb = new-object Microsoft.SqlServer.Management.Smo.Table($db, "tb_users")  

#Create columns to table tb_users
$col1  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "Age", [Microsoft.SqlServer.Management.Smo.DataType]::Int)  
$col2  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "street", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50)) 
$col3  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "Dateins", [Microsoft.SqlServer.Management.Smo.DataType]::Varchar(20))
$col4  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "ComputerName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100))  
$col5  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "Phone", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100)) 
$col6  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "Id", [Microsoft.SqlServer.Management.Smo.DataType]::varchar(50))   
$col7  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "capital", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(50))  
$col8  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "UserName", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(100)) 
$col9  = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "state", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(5)) 
$col10 = new-object Microsoft.SqlServer.Management.Smo.Column($tb, "zip", [Microsoft.SqlServer.Management.Smo.DataType]::VarChar(15)) 

#Add columns
$tb.Columns.Add($col1)  
$tb.Columns.Add($col2)  
$tb.Columns.Add($col3)  
$tb.Columns.Add($col4)  
$tb.Columns.Add($col5)  
$tb.Columns.Add($col6)  
$tb.Columns.Add($col7)  
$tb.Columns.Add($col8)  
$tb.Columns.Add($col9)
$tb.Columns.Add($col10)  
#Create table tb_users
$tb.Create()  

#Create a template to make easier
$template ='
        Age          =  ## 
        street       = [Address]
        Datains      = [randomdate]      
        ComputerName = Host-[state abbr]##      
        Phone        = ###-###-####
        id           = [guid]
        capital      = [state capital]
        user         = [person]
        state        = [state abbr]
        zip          = [state zip]         
        '
#Fill variable called $table and transform to datatable
$table = Invoke-Generate $Template -AsPSObject -Count $QtdLines | ConvertTo-DbaDataTable

#Use Dbatools to write lines on SQL Server database
Write-DbaDataTable -SqlInstance $SqlInstance -InputObject $table  -Database $Sqldb -Table $tb.Name 

#Refresh table and show qtd lines
$tb.Refresh() 
$tb.RowCount

#if you want can drop database
#$srv.ConnectionContext.Disconnect()
#$db.Drop()

