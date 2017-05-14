

IF(OBJECT_ID('SP_SENDEMAIL_HTML')) IS NOT NULL
	DROP PROC SP_SENDEMAIL_HTML

GO

CREATE PROCEDURE SP_SENDEMAIL_HTML 
@QUERY VARCHAR(MAX) = '',
@PROFILE_NAME VARCHAR(50) = '',
@RECIPIENTS VARCHAR(8000) = '',
@SUBJECT VARCHAR(1000) = '',
@BODY VARCHAR(1000) = 'INFORMA��ES',
@IMPORTANCE VARCHAR(20) ='HIGH',
@HELP BIT = 0
AS

SET NOCOUNT ON


IF(@HELP <> 0)
BEGIN
PRINT 
'
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
															SP_SENDEMAIL_HTML
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
Nome Procedure: SP_SENDEMAIL_HTML
Projeto.......: SCRIPTS
Vers�o........: 1.0.0.1
---------------------------------------------------------------------------------------------------------------------------------------------

SQL Server edi��es testadas: SQL Server 2008 e superiores.

---------------------------------------------------------------------------------------------------------------------------------------------
Id		Autor                      Vers�o	      Data                            Descri��o
---------------------------------------------------------------------------------------------------------------------------------------------

1		Reginaldo da cruz Silva   1.0.0.0		19/02/2017						Cria��o da procedure.
2		Reginaldo da cruz Silva   1.0.0.1		19/02/2017						Valida��o dos parametros de entrada.
3		Reginaldo da cruz Silva   1.0.0.1		19/02/2017						Valida��o se existem campos do tipo binary ou varbinary.

	
---------------------------------------------------------------------------------------------------------------------------------------------

Revis�o:
Reginaldo da Cruz Silva - 02/19/2017 17:00

Duvidas e sugest�es:
Blog: https://blogdojamal.wordpress.com/
Email: Reginaldo.silva27@gmail.com


>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
												PAR�METROS
>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

 PARAMETRO									DESCRI��O 
 
@QUERY				- OPERA��O DE SELECT QUE DESEJA TRANSFORMAR NO FORMATO HTML E ENVIAR POR EMAIL
@PROFILE_NAME		- NOME DO PERFIL CONFIGURADO NO DATABASEMAIL
@RECIPIENTS			- DESTINAT�RIOS QUE IRAM RECEBER O EMAIL
@SUBJECT			- ASSUNTO DO EMAIL
@BODY				- TEXTO QUE IR� SER EXIBIDO ANTES DA TABELA HTML
@IMPORTANCE			- N�VEL DE IMPORT�NCIA DO EMAIL PODENDO SER LOW, NORMAL E HIGH, DEFAULT � HIGH
@HELP				- MOSTRA DESCRI��O DOS PAR�METROS E CABE�ALHO.

>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

'

RETURN
END


IF(@QUERY = '')
BEGIN
	PRINT 'INFORME A QUERY.'
	RETURN
END

IF(@PROFILE_NAME = '')
BEGIN
	PRINT 'INFORME O PROFILE_NAME.'
	RETURN
END

IF(@RECIPIENTS = '')
BEGIN
	PRINT 'INFORME OS RECIPIENTS.'
	RETURN
END



DECLARE @QUERY_TEMP VARCHAR(MAX),@QUERY_FROM VARCHAR(MAX),@QUERY_SELECT VARCHAR(MAX), @MARK INT
DECLARE @TABLEHTML VARCHAR(MAX),@HEADERTABLE VARCHAR(MAX)

SET @HEADERTABLE = N'<H1>'+CAST(@BODY AS VARCHAR(MAX))+'</H1>' + N'<table border="1">' + N'<tr>'
SET @MARK = CHARINDEX('FROM',@QUERY,0)

IF(OBJECT_ID('TEMP_COLUMNS')) IS NOT NULL
	DROP TABLE TEMP_COLUMNS

SET @QUERY_FROM = SUBSTRING(@QUERY,@MARK,LEN(@QUERY))
SET @QUERY_SELECT = SUBSTRING(@QUERY,0,@MARK)
SET @QUERY_TEMP =  @QUERY_SELECT + ' INTO TEMP_COLUMNS ' +  @QUERY_FROM
EXEC('SET ROWCOUNT 1'  + @QUERY_TEMP)

IF(SELECT COUNT(*) FROM SYSOBJECTS O INNER JOIN SYSCOLUMNS C ON O.ID = C.ID INNER JOIN SYS.TYPES T ON C.XUSERTYPE = T.USER_TYPE_ID
WHERE O.NAME = 'TEMP_COLUMNS' AND T.NAME LIKE '%BINARY%') > 0
BEGIN
	SELECT 'EXISTEM COLUNAS COM O DATATYPE DO TIPO BINARY OU VARBINARY, N�O SER� POSSIVEL ENVIAR O E-MAIL.'
	SELECT C.NAME COLUMN_NAME,T.NAME TYPE_COLUMN FROM SYSOBJECTS O INNER JOIN SYSCOLUMNS C ON O.ID = C.ID INNER JOIN SYS.TYPES T ON C.XUSERTYPE = T.USER_TYPE_ID
	WHERE O.NAME = 'TEMP_COLUMNS' AND T.NAME LIKE '%BINARY%'
	RETURN
END

DECLARE @COLUMNSCOMMAND VARCHAR(MAX) = 'SELECT CAST((SELECT '
DECLARE @CONT INT = 0,@QTDLINE INT
DECLARE @COLUMN_NAME VARCHAR(500)

SET @QTDLINE = (SELECT COUNT(C.NAME) FROM SYSOBJECTS O INNER JOIN SYSCOLUMNS C ON O.ID = C.ID WHERE O.NAME = 'TEMP_COLUMNS')

DECLARE CURSOR_COLUMNS CURSOR FOR 
SELECT C.NAME FROM SYSOBJECTS O INNER JOIN SYSCOLUMNS C ON O.ID = C.ID WHERE O.NAME = 'TEMP_COLUMNS' ORDER BY C.COLID
OPEN CURSOR_COLUMNS
FETCH NEXT FROM CURSOR_COLUMNS INTO @COLUMN_NAME
WHILE @@FETCH_STATUS = 0 
BEGIN

SET @HEADERTABLE = @HEADERTABLE + N'<th BGCOLOR="#C0C0C0" WIDTH=200 height=42>'+CAST(@COLUMN_NAME AS VARCHAR(MAX))+'</th>'

IF((@CONT+1) = @QTDLINE)
	SET @COLUMNSCOMMAND = @COLUMNSCOMMAND + ',td = CAST('+@COLUMN_NAME+' AS NVARCHAR(200)) , '' '''
ELSE IF(@CONT = 0)
	SET @COLUMNSCOMMAND = @COLUMNSCOMMAND + '''center'' AS ''td/@align'', td = CAST('+@COLUMN_NAME+' AS NVARCHAR(200)) , '' '', ''center'' AS ''td/@align'' '
ELSE
	SET @COLUMNSCOMMAND = @COLUMNSCOMMAND + ',td = CAST('+@COLUMN_NAME+' AS NVARCHAR(200)) , '' '', ''center'' AS ''td/@align'' '

SET @CONT =  @CONT  + 1
FETCH NEXT FROM CURSOR_COLUMNS INTO @COLUMN_NAME
END
CLOSE CURSOR_COLUMNS
DEALLOCATE CURSOR_COLUMNS

SET @COLUMNSCOMMAND =  @COLUMNSCOMMAND  + ' from ('+ @QUERY_SELECT + @QUERY_FROM+ ') TAB FOR XML PATH(''tr'') , TYPE ) AS VARCHAR(MAX))' 
SET @HEADERTABLE = @HEADERTABLE + N'</tr>'

DECLARE @COLUMNS_TABLE TABLE (COMMAND VARCHAR(MAX))
DECLARE @COLUMNS_RESULT VARCHAR(MAX)

INSERT INTO @COLUMNS_TABLE
EXEC (@COLUMNSCOMMAND)

SELECT @COLUMNS_RESULT = CAST(COMMAND AS VARCHAR(MAX)) FROM @COLUMNS_TABLE
SET @HEADERTABLE  = CAST(@HEADERTABLE AS VARCHAR(MAX))  + CAST(@COLUMNS_RESULT  AS VARCHAR(MAX)) + CAST('</table>'  AS VARCHAR(MAX))
SET @TABLEHTML = @HEADERTABLE 

 EXEC msdb.dbo.sp_send_dbmail    
	 @profile_name = @PROFILE_NAME,
	 @recipients = @RECIPIENTS,  			
	 @subject = @SUBJECT,   
	 @body = @TABLEHTML ,    
	 @body_format = 'HTML',    
	 @importance='high'

EXEC ('
IF(OBJECT_ID(''TEMP_COLUMNS'')) IS NOT NULL
	DROP TABLE TEMP_COLUMNS
')



