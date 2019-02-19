# Utilizando a função do Dbatools para capturar a lista de todos os Jobs de um servidor específico
$JobList = Get-DbaAgentJob -SqlInstance "DESKTOP-A7S2JPV\SQLSERVER2016"
#Caminho onde será gerado os scripts
$Pathbase = "C:\temp\BackupJobs\"
$Path = ""
 ForEach ($Job in $JobList)
 {
  #Corrige nome do arquivo em jobs com caracter especial no nome
  $Path = $Pathbase + $Job.Name.Replace("/"," ").Replace("\"," ").Replace(":"," ") + ".sql"

  #Inclui algumas opções no script, como cabeçalho do Job
  $options = New-DbaScriptingOption
  $options.ScriptSchema = $true
  $options.IncludeDatabaseContext  = $true
  $options.IncludeHeaders = $true
  $options.ScriptBatchTerminator = $true
  $options.AnsiFile = $true

  #Exportar Job por Job para o caminho especificado
  $Job | Export-DbaScript -Path $Path -ScriptingOptionsObject $options  
 } 