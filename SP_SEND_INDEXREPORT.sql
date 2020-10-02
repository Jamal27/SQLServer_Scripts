USE DBA_MONITOR
GO
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID('SP_SEND_INDEXREPORT'))
BEGIN
    DROP PROCEDURE SP_SEND_INDEXREPORT
END
GO
-----------ALTERAR LINHA 268, CONTA DO DATABASE MAIL-----------
CREATE PROCEDURE SP_SEND_INDEXREPORT 
@Indexfrag bit = 1, -- Apresenta fragmentação dos índices
@IndexfragPercent tinyint = 50, --Apenas índices com mais de 50% de fragmentação.
@IndexfragPages int = 10000, --Apenas índices com mais de 10000 páginas
@IndexLowutilization bit = 1, --Índices com baixa utilização
@IndexLowutilizationMonths tinyint = 3, --Avaliar últimos 3 meses de coleta
@IndexHighUpdates bit = 1, --Índices com bastante escrita
@IndexUtilization bit = 1, --Índices com bastante leitura
@QtdIndex bit = 1, --Quantidade de índices por banco de dados
@IndexDuplicate bit = 1, --Apresenta índices duplicados
@IndexDisabled bit = 1, --Apresenta índices desabilitados 
@IndexPkNonClustered bit = 1, --Apresenta índices PK non clustered
@IndexFillFactor bit = 1, --Apresenta fill factor dos índices
@IndexFillFactorPercent tinyint= 98, --Índices apenas com Fill factor menor que 98
@IndexCompression bit = 1 -- Apresenta índices com compressão
AS
DECLARE @EmailBody VARCHAR(MAX)

IF(@Indexfrag = 1)
BEGIN
--INDICES MAIS FRAGMENTADOS
DECLARE @Indicesfragmentados NVARCHAR(MAX) 

SET @Indicesfragmentados = N'<H1>INDICES FRAGMENTADOS > '+CAST(@IndexfragPercent AS VARCHAR(10))+'%</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX TYPE</th><th BGCOLOR="#C0C0C0" WIDTH=200>FRAGMENTATION</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FILL_FACTOR</th> <th BGCOLOR="#C0C0C0" WIDTH=200>PAGE COUNT</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_TYPE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_FRAGMENTATION_IN_PERCENT AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FILL_FACTOR AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(PAGE_COUNT  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,INDEX_TYPE,AVG_FRAGMENTATION_IN_PERCENT,FILL_FACTOR,PAGE_COUNT FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
AND AVG_FRAGMENTATION_IN_PERCENT > @IndexfragPercent  AND PAGE_COUNT > @IndexfragPages
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexLowutilization = 1)
BEGIN
--INDICES POUCO UTILIZADOS
DECLARE @Indicespoucoutilizados NVARCHAR(MAX) 

SET @Indicespoucoutilizados = N'<H1>INDICES POUCO UTILIZADOS</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FIRST_SEEK</th> <th BGCOLOR="#C0C0C0" WIDTH=200>LAST_UPDATE</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FIRST_COLLECT</th> <th BGCOLOR="#C0C0C0" WIDTH=200>LAST_COLLECT</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FIRST_SEEK AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(LAST_UPDATE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FIRST_COLLECT AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(LAST_COLLECT  AS NVARCHAR(200))   
FROM 
(
SELECT * FROM (
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,AVG(SEEKS + SCANS) AVG_READ, AVG(UPDATES) AVG_WRITE,MIN(LAST_SEEK) FIRST_SEEK,MAX(LAST_UPDATE) LAST_UPDATE,MIN(DATE_COLLECTION) FIRST_COLLECT,MAX(DATE_COLLECTION) LAST_COLLECT
FROM RESULTADO_SHOWINDEX WHERE DATE_COLLECTION > DATEADD(MONTH,-@IndexLowutilizationMonths,GETDATE())
GROUP BY DATABASE_NAME,TABLE_NAME,INDEX_NAME
) TAB WHERE DATEDIFF(DAY,FIRST_COLLECT,LAST_COLLECT) > 1 AND AVG_READ < 100 AND AVG_WRITE > 1000
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexHighUpdates = 1)
BEGIN
--INDICES MAIS ATUALIZADOS
DECLARE @Indicesatualizados NVARCHAR(MAX) 

SET @Indicesatualizados = N'<H1>TOP 10 INDICES MAIS ATUALIZADOS</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA1</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA2</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA3</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA4</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA7</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_WRITE_DIA14</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA1 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA2 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA3 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA4 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA7 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_WRITE_DIA14  AS NVARCHAR(200))   
FROM 
(
SELECT TOP 10 * FROM (
SELECT A.DATABASE_NAME,A.TABLE_NAME,A.INDEX_NAME,AVG(A.UPDATES) AVG_WRITE_DIA1,AVG(B.UPDATES) AVG_WRITE_DIA2,AVG(C.UPDATES) AVG_WRITE_DIA3,AVG(D.UPDATES) AVG_WRITE_DIA4,AVG(E.UPDATES) AVG_WRITE_DIA7,AVG(F.UPDATES) AVG_WRITE_DIA14
FROM RESULTADO_SHOWINDEX A
LEFT JOIN RESULTADO_SHOWINDEX B ON A.SERVER_NAME = B.SERVER_NAME AND A.DATABASE_NAME = B.DATABASE_NAME AND A.TABLE_NAME = B.TABLE_NAME AND A.INDEX_NAME = B.INDEX_NAME
AND B.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-1 AS int) AS DATETIME)) AND B.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE() AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX C ON A.SERVER_NAME = C.SERVER_NAME AND A.DATABASE_NAME = C.DATABASE_NAME AND A.TABLE_NAME = C.TABLE_NAME AND A.INDEX_NAME = C.INDEX_NAME
AND C.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-2 AS int) AS DATETIME)) AND C.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-1 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX D ON A.SERVER_NAME = D.SERVER_NAME AND A.DATABASE_NAME = D.DATABASE_NAME AND A.TABLE_NAME = D.TABLE_NAME AND A.INDEX_NAME = D.INDEX_NAME
AND D.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-3 AS int) AS DATETIME)) AND D.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-2 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX E ON A.SERVER_NAME = E.SERVER_NAME AND A.DATABASE_NAME = E.DATABASE_NAME AND A.TABLE_NAME = E.TABLE_NAME AND A.INDEX_NAME = E.INDEX_NAME
AND E.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-6 AS int) AS DATETIME)) AND E.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-5 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX F ON A.SERVER_NAME = F.SERVER_NAME AND A.DATABASE_NAME = F.DATABASE_NAME AND A.TABLE_NAME = F.TABLE_NAME AND A.INDEX_NAME = F.INDEX_NAME
AND F.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-13 AS int) AS DATETIME)) AND F.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-12 AS int) AS DATETIME))
WHERE CAST(A.DATE_COLLECTION AS DATE)= CAST(GETDATE() AS DATE)
GROUP BY A.DATABASE_NAME,A.TABLE_NAME,A.INDEX_NAME
) TAB WHERE  AVG_WRITE_DIA1 > 100
ORDER BY AVG_WRITE_DIA1 DESC
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexUtilization = 1)
BEGIN
--INDICES MAIS UTILIZADOS
DECLARE @Indicesutilizados NVARCHAR(MAX) 

SET @Indicesutilizados = N'<H1>TOP 10 INDICES POR LEITURA</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA1</th><th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA2</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA3</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA4</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA7</th> <th BGCOLOR="#C0C0C0" WIDTH=200>AVG_READ_DIA14</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA1 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA2 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA3 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA4 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA7 AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_READ_DIA14  AS NVARCHAR(200))   
FROM 
(
SELECT TOP 10 * FROM (
SELECT A.DATABASE_NAME,A.TABLE_NAME,A.INDEX_NAME,AVG(A.SEEKS) AVG_READ_DIA1,AVG(B.SEEKS) AVG_READ_DIA2,AVG(C.SEEKS) AVG_READ_DIA3,AVG(D.SEEKS) AVG_READ_DIA4,AVG(E.SEEKS) AVG_READ_DIA7,AVG(F.SEEKS) AVG_READ_DIA14
FROM RESULTADO_SHOWINDEX A
LEFT JOIN RESULTADO_SHOWINDEX B ON A.SERVER_NAME = B.SERVER_NAME AND A.DATABASE_NAME = B.DATABASE_NAME AND A.TABLE_NAME = B.TABLE_NAME AND A.INDEX_NAME = B.INDEX_NAME
AND B.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-1 AS int) AS DATETIME)) AND B.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE() AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX C ON A.SERVER_NAME = C.SERVER_NAME AND A.DATABASE_NAME = C.DATABASE_NAME AND A.TABLE_NAME = C.TABLE_NAME AND A.INDEX_NAME = C.INDEX_NAME
AND C.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-2 AS int) AS DATETIME)) AND C.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-1 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX D ON A.SERVER_NAME = D.SERVER_NAME AND A.DATABASE_NAME = D.DATABASE_NAME AND A.TABLE_NAME = D.TABLE_NAME AND A.INDEX_NAME = D.INDEX_NAME
AND D.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-3 AS int) AS DATETIME)) AND D.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-2 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX E ON A.SERVER_NAME = E.SERVER_NAME AND A.DATABASE_NAME = E.DATABASE_NAME AND A.TABLE_NAME = E.TABLE_NAME AND A.INDEX_NAME = E.INDEX_NAME
AND E.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-6 AS int) AS DATETIME)) AND E.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-5 AS int) AS DATETIME))
LEFT JOIN RESULTADO_SHOWINDEX F ON A.SERVER_NAME = F.SERVER_NAME AND A.DATABASE_NAME = F.DATABASE_NAME AND A.TABLE_NAME = F.TABLE_NAME AND A.INDEX_NAME = F.INDEX_NAME
AND F.DATE_COLLECTION > DATEADD(DAY,-1,CAST(CAST(GETDATE()-13 AS int) AS DATETIME)) AND F.DATE_COLLECTION < DATEADD(DAY,-1,CAST(CAST(GETDATE()-12 AS int) AS DATETIME))
WHERE CAST(A.DATE_COLLECTION AS DATE)= CAST(GETDATE() AS DATE)
GROUP BY A.DATABASE_NAME,A.TABLE_NAME,A.INDEX_NAME
) TAB WHERE  AVG_READ_DIA1 > 100
ORDER BY AVG_READ_DIA1 DESC
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@QtdIndex = 1)
BEGIN
--INDICES POR BANCO DE DADOS
DECLARE @Indicesperdb NVARCHAR(MAX) 

SET @Indicesperdb = N'<H1>INDICES POR BANCO DE DADOS</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>QTD INDICES</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
		'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(QTD_INDEX  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,COUNT(DISTINCT INDEX_NAME) QTD_INDEX FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
GROUP BY DATABASE_NAME
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexDisabled = 1)
BEGIN
--INDICES DESABILITADOS
DECLARE @Indicesdesabilitados NVARCHAR(MAX) 

SET @Indicesdesabilitados = N'<H1>INDICES DESABILITADOS</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>LAST SEEK</th><th BGCOLOR="#C0C0C0" WIDTH=200>LAST UPDATE</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(LAST_SEEK AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(LAST_UPDATE  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,LAST_SEEK,LAST_UPDATE FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
AND IS_DISABLED = 'YES'
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexDuplicate = 1)
BEGIN
--INDICES DUPLICADOS
DECLARE @Indicesdeduplicados NVARCHAR(MAX) 

SET @Indicesdeduplicados = N'<H1>TABELAS COM INDICES DUPLICADOS</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>QTD DUPLICIDADE</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(QTD  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,COUNT(COLUMNS) QTD FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
GROUP BY DATABASE_NAME,TABLE_NAME,COLUMNS HAVING COUNT(COLUMNS) > 1
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexPkNonClustered = 1)
BEGIN
--INDICES PK NONCLUSTEREDS
DECLARE @Indicespknoncluster NVARCHAR(MAX) 

SET @Indicespknoncluster = N'<H1>PRIMARY KEY NON CLUSTERED</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX TYPE</th><th BGCOLOR="#C0C0C0" WIDTH=200>FRAGMENTATION</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FILL_FACTOR</th> <th BGCOLOR="#C0C0C0" WIDTH=200>PAGE COUNT</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_TYPE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_FRAGMENTATION_IN_PERCENT AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FILL_FACTOR AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(PAGE_COUNT  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,INDEX_TYPE,AVG_FRAGMENTATION_IN_PERCENT,FILL_FACTOR,PAGE_COUNT FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
AND PRIMARY_KEY = 1 AND INDEX_TYPE = 'NONCLUSTERED'
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexFillFactor = 1)
BEGIN
--INDICES FILLFACTOR BAIXO
DECLARE @Indicesfillfactor NVARCHAR(MAX) 

SET @Indicesfillfactor = N'<H1>INDICES FILLFACTOR <> 0</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX TYPE</th><th BGCOLOR="#C0C0C0" WIDTH=200>FRAGMENTATION</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FILL_FACTOR</th> <th BGCOLOR="#C0C0C0" WIDTH=200>PAGE COUNT</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_TYPE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_FRAGMENTATION_IN_PERCENT AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FILL_FACTOR AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(PAGE_COUNT  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,INDEX_TYPE,AVG_FRAGMENTATION_IN_PERCENT,FILL_FACTOR,PAGE_COUNT FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
AND FILL_FACTOR <> 0 AND FILL_FACTOR < @IndexFillFactorPercent
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

IF(@IndexCompression = 1)
BEGIN
--INDICES COMPACTADOS
DECLARE @Indicescompactados NVARCHAR(MAX) 

SET @Indicescompactados = N'<H1>INDICES COM COMPRESSAO</H1>' + N'<table border="1">' + N'<tr><th BGCOLOR="#C0C0C0" WIDTH=200 height=42>DATABASE</th><th BGCOLOR="#C0C0C0" WIDTH=200>TABLE</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX</th><th BGCOLOR="#C0C0C0" WIDTH=200>INDEX TYPE</th><th BGCOLOR="#C0C0C0" WIDTH=200>DATA_COMPRESSION</th><th BGCOLOR="#C0C0C0" WIDTH=200>FRAGMENTATION</th> <th BGCOLOR="#C0C0C0" WIDTH=200>FILL_FACTOR</th> <th BGCOLOR="#C0C0C0" WIDTH=200>PAGE COUNT</th> </tr>' + 
CAST(
(SELECT 'center' AS 'td/@align', '#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATABASE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(TABLE_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' ,
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_NAME AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(INDEX_TYPE AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(DATA_COMPRESSION AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(AVG_FRAGMENTATION_IN_PERCENT AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(FILL_FACTOR AS NVARCHAR(200)) , ' ', 'center' AS 'td/@align' , 		
'#FFFFFF' AS 'td/@BGCOLOR', td = CAST(PAGE_COUNT  AS NVARCHAR(200))   
FROM 
(
SELECT DATABASE_NAME,TABLE_NAME,INDEX_NAME,INDEX_TYPE,DATA_COMPRESSION,AVG_FRAGMENTATION_IN_PERCENT,FILL_FACTOR,PAGE_COUNT FROM RESULTADO_SHOWINDEX WHERE CAST(DATE_COLLECTION AS DATE)  = CAST(GETDATE() AS DATE)
AND DATA_COMPRESSION <> 'NONE'
  )TAB FOR XML PATH('tr') , TYPE ) AS VARCHAR(MAX)) + N'</table>'
END

SELECT @EmailBody =
	  Isnull(@Indicesperdb,'') + Isnull(@Indicesdesabilitados,'') + ISNULL(@Indicesdeduplicados, '')
	  + ISNULL(@Indicesatualizados, '') + ISNULL(@Indicesutilizados, '')
	  + ISNULL(@Indicesfragmentados, '') + ISNULL(@Indicespoucoutilizados, '') + ISNULL(@Indicespknoncluster, '') 
	  + ISNULL(@Indicesfillfactor, '') + ISNULL(@Indicescompactados, '') 

-----------ALTERAR AQUI-----------	  
EXEC msdb.dbo.sp_send_dbmail    
@profile_name = 'DATASIDE',
@recipients = 'reginaldo.silva@dataside.com.br',  				 
@subject = 'INFORMAÇÕES INDICES' ,   
@body = @EmailBody ,    
@body_format = 'HTML' ,    
@importance='HIGH'

GO
