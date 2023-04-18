/*



This audit solution was compiled and revised by David Speight at www.lovethesql.com based mostly on code originally written by and posted by the following sources:

SQL Saturday workshop in Orlando, Florida
PASS Summit worksop in Seattle, Washington
K. Brian Kelley : www.mssqltips.com/sqlservertip/2741/how-to-audit-login-changes-on-a-sql-server/
Jason Brimhall : jasonbrimhall.info/2015/03/11/audit-schema-change-report/



*/
USE [Audit]
GO
/****** Object:  UserDefinedFunction [Analysis].[NegToZero]    Script Date: 4/18/2023 8:52:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		David Speight
-- =============================================
CREATE FUNCTION [Analysis].[NegToZero]
(
@inNumber FLOAT
)
RETURNS FLOAT 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @outNumber FLOAT 

	SELECT @outNumber = (CASE WHEN @inNumber < 0 THEN 0 ELSE @inNumber END);
	-- Return the result of the function
	RETURN @outNumber

END

GO
/****** Object:  UserDefinedFunction [dbo].[LoginIsSysAdmin]    Script Date: 4/18/2023 8:52:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		David Speight
-- =============================================
CREATE FUNCTION [dbo].[LoginIsSysAdmin]
(
@LoginName NVARCHAR(150)
)
RETURNS BIT 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @outIsAdmin bit = 0;

	SELECT   @outIsAdmin = IS_SRVROLEMEMBER('sysadmin',name)
	FROM     master.sys.server_principals 
	WHERE    name = @LoginName;
	   	 
	RETURN @outIsAdmin

END

GO
/****** Object:  UserDefinedFunction [dbo].[SplitString]    Script Date: 4/18/2023 8:52:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[SplitString](@str NVARCHAR(MAX),@sep NVARCHAR(MAX))
RETURNS @tbl TABLE(value NVARCHAR(MAX))
AS
BEGIN
	DECLARE @idx1 INT;
	DECLARE @idx2 INT;
	SET @idx1=0;
	WHILE @idx1 >-1
	BEGIN;
		SELECT @idx2 =  CHARINDEX(@sep,@str,@idx1);
		IF @idx2 > 0
		BEGIN;
			INSERT INTO @tbl(value)
			SELECT SUBSTRING(@str,@idx1,@idx2-@idx1)
			SET @idx1 = @idx2+1;
		END;
		ELSE
		BEGIN;
			INSERT INTO @tbl(value)
			SELECT SUBSTRING(@str,@idx1,LEN(@str)+1-@idx1)
			SET @idx1 = -1;
		END;
	END;
	RETURN;
END;

GO
/****** Object:  Table [dbo].[Server]    Script Date: 4/18/2023 8:52:27 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Server](
	[ServerID] [int] IDENTITY(1,1) NOT NULL,
	[ServerNm] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[RAMmb] [int] NULL,
	[connString] [varbinary](2000) NULL,
	[ServerResolvedName] [varchar](50) NULL,
	[ServerGroupID] [int] NULL,
	[ServerGroupName] [varchar](150) NULL,
	[IsCurrent] [bit] NULL,
 CONSTRAINT [PK_Server] PRIMARY KEY CLUSTERED 
(
	[ServerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [policy].[pfn_ServerGroupInstances]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  Table [dbo].[AuditScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditScan](
	[AuditScanID] [int] IDENTITY(1,1) NOT NULL,
	[ScanStartDate] [datetime] NOT NULL,
	[ScanEndDate] [datetime] NULL,
 CONSTRAINT [PK_AuditScan] PRIMARY KEY CLUSTERED 
(
	[AuditScanID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CurrentLoginScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CurrentLoginScan](
	[sid] [varbinary](85) NOT NULL,
	[name] [sysname] NOT NULL,
	[type] [char](1) NOT NULL,
	[create_date] [datetime] NULL,
	[modify_date] [datetime] NULL,
	[AuditScanID] [int] NOT NULL,
 CONSTRAINT [PK_CurrentLoginScan] PRIMARY KEY CLUSTERED 
(
	[sid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoginAudit]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoginAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](50) NULL,
	[UserName] [varchar](100) NULL,
	[LoginType] [varchar](50) NULL,
	[IsDisabled] [bit] NULL,
	[IsServiceAccount] [bit] NULL,
	[IsSysAdmin] [bit] NULL,
	[IsProductionServer] [bit] NULL,
	[CreatedDate] [datetime] NULL,
	[LastModified] [datetime] NULL,
	[AuditDate] [datetime] NULL,
 CONSTRAINT [PK_LoginAudit] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoginCount]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoginCount](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerInstanceName] [nvarchar](150) NULL,
	[PrincipalName] [nvarchar](150) NULL,
	[dDate] [date] NULL,
	[Success] [bit] NULL,
	[Count] [int] NULL,
 CONSTRAINT [PK_LoginCount] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoginFailure]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoginFailure](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServerInstanceName] [nvarchar](150) NULL,
	[PrincipalName] [nvarchar](150) NULL,
	[dtDate] [datetime] NULL,
	[StatementIssued] [nvarchar](max) NULL,
 CONSTRAINT [PK_LoginFailure] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoginScanRecord]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoginScanRecord](
	[ScanLogID] [int] IDENTITY(1,1) NOT NULL,
	[AuditScanID] [int] NOT NULL,
	[sid] [varbinary](85) NOT NULL,
	[name] [sysname] NOT NULL,
	[type] [char](1) NOT NULL,
	[create_date] [datetime] NOT NULL,
	[modify_date] [datetime] NOT NULL,
	[AuditDtBegin] [datetime] NULL,
	[AuditDtEnd] [datetime] NULL,
	[AuditAction] [varchar](50) NULL,
	[ServerInstanceName]  AS (CONVERT([varchar](150),@@servername)),
 CONSTRAINT [PK_LoginSCanRecord] PRIMARY KEY CLUSTERED 
(
	[ScanLogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SchemaChange]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SchemaChange](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditScanID] [int] NULL,
	[ChangeDate] [datetime] NULL,
	[ServerName] [nvarchar](150) NULL,
	[DatabaseName] [nvarchar](150) NULL,
	[ObjectName] [nvarchar](250) NULL,
	[ObjectType] [nvarchar](50) NULL,
	[DDLOperation] [nvarchar](50) NULL,
	[LoginName] [nvarchar](250) NULL,
	[NTUserName] [nvarchar](250) NULL,
	[ApplicationName] [nvarchar](250) NULL,
 CONSTRAINT [PK_SchemaChange] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserPermissionScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserPermissionScan](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditScanID] [int] NULL,
	[ServerName] [nvarchar](150) NULL,
	[Database] [nvarchar](150) NULL,
	[User] [nvarchar](128) NULL,
	[Permission] [nvarchar](50) NULL,
	[Action] [nvarchar](50) NULL,
	[Securable] [nvarchar](500) NULL,
	[AuditDtBegin] [datetime] NULL,
	[AuditDtEnd] [datetime] NULL,
	[AuditAction] [nvarchar](50) NULL,
	[CheckSumDigi]  AS (checksum([ServerName],[Database],[User],[Permission],[Action],[Securable])),
 CONSTRAINT [PK_UserPermissionScan] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 95, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CurrentLoginScan]  WITH CHECK ADD  CONSTRAINT [FK_CurrentLoginScan_AuditScan] FOREIGN KEY([AuditScanID])
REFERENCES [dbo].[AuditScan] ([AuditScanID])
GO
ALTER TABLE [dbo].[CurrentLoginScan] CHECK CONSTRAINT [FK_CurrentLoginScan_AuditScan]
GO
ALTER TABLE [dbo].[LoginScanRecord]  WITH CHECK ADD  CONSTRAINT [FK_LoginScanRecord_AuditScan] FOREIGN KEY([AuditScanID])
REFERENCES [dbo].[AuditScan] ([AuditScanID])
GO
ALTER TABLE [dbo].[LoginScanRecord] CHECK CONSTRAINT [FK_LoginScanRecord_AuditScan]
GO
/****** Object:  StoredProcedure [dbo].[E_Report_AuditDaily]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- Create date: 20201104
-- Updated:		20230418   added InstanceName
-- Example use: EXEC dbo.E_Report_AuditDaily 'MySQLmailProfile','me@mycompany.com','Orlando';
-- =============================================
CREATE PROCEDURE [dbo].[E_Report_AuditDaily] 
@E_profile_name nvarchar(250),
@E_recipients nvarchar(2000),
@InstanceName nvarchar(150),  -- Note: This is used as a "location" or "environment" name in the email only.
@ServerName NVARCHAR(2000)=NULL,
@StartDate DATETIME=NULL,
@EndDate DATETIME=NULL
AS
BEGIN
	-- This will email the Daily Audit Report
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

		declare @body1 nvarchar(max);
		declare @body2 nvarchar(max);
		declare @body3 nvarchar(max);
		declare @body4 nvarchar(max);
		declare @body5 nvarchar(max);
		declare @bodyFIN nvarchar(max);
		DECLARE @StyleSheet VARCHAR(1000);
		DECLARE @Header VARCHAR(400);
		DECLARE @GreenTitle VARCHAR(250);
		DECLARE @ServerResolvedName VARCHAR(250);

		SELECT TOP(1) @ServerResolvedName = ServerResolvedName
		FROM dbo.Server
		WHERE IsActive = 1;

		SELECT @StyleSheet = 
'<style><!--
@font-face
	{font-family:"Microsoft Sans Serif";
	panose-1:2 11 6 4 2 2 2 2 2 4;}
p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin:0in;
	font-size:11.0pt;
	font-family:"Calibri",sans-serif;}
--></style>',
				@Header = CONCAT('<p class="MsoNormal" style="background:white"><span style="font-size:18pt;color:#8B404B;letter-spacing:-1.0pt">MyCompany</span><span style="font-size:18pt;color:#0C2340">Name</span></p><BR /><span style="font-size:16pt;color:#0C2340"><p><span style="font-size:16pt;color:#0C2340">DAILY AUDIT LOG FOR ',UPPER(@InstanceName),':',UPPER(@ServerResolvedName),' ON ',CONVERT(varchar(12),getdate()),' </span></p>'),
				@GreenTitle = '<p class="MsoNormal" style="background:white"><span style="font-size:16.0pt;font-family:&amp;quot;color:#8B404B;letter-spacing:-1.0pt">'


		SELECT	@StartDate = CONVERT(Date,DATEADD(d,-1,getdate())),
				@EndDate = CONVERT(Date,DATEADD(d,0,getdate()));

				-- LOGIN COUNTS
		SELECT @body1 = cast( (
		select td = CONCAT(d.ServerInstanceName,'</td><td>',d.PrincipalName,'</td><td>',CONVERT(varchar(50),d.dDate),'</td><td>',(Case d.Success when 1 then 'Yes' Else 'No' END),'</td><td>',convert(varchar(50),d.Total) )
		from (
				SELECT  
					UPPER(ISNULL(S.ServerResolvedName,L.ServerInstanceName))  AS ServerInstanceName, 
					ISNULL(PrincipalName,'') AS PrincipalName, 
					@EndDate AS dDate, 
					0 AS Success, 
					COUNT(*) AS Total
				FROM .[dbo].[LoginFailure] AS L
				LEFT JOIN dbo.Server AS S ON L.ServerInstanceName = S.ServerNm
				WHERE	(@ServerName IS NULL OR ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
					AND (dtDate BETWEEN CONVERT(DATE,@StartDate) AND CONVERT(DATE,@EndDate)) 
				GROUP BY ISNULL(S.ServerResolvedName,L.ServerInstanceName), PrincipalName	
				) as d
		for xml path( 'tr' ), type ) as varchar(max) )
		SELECT @body1 = (CASE WHEN len(@body1) IS NULL THEN '' ELSE		
						(CONCAT('<table cellpadding="2" cellspacing="2" border="0"><tr><th style="background:#DBCFD0">Instance</th><th style="background:#DBCFD0">Name</th><th style="background:#DBCFD0">Date</th><th style="background:#DBCFD0">Success</th><th style="background:#DBCFD0">Total</th></tr>'
					, replace( replace( @body1, '&lt;', '<' ), '&gt;', '>' )
					, '</table>')) END);
		SELECT @body1 = LEFT(@body1,40000) -- Limit to 40 of the 64k

		----- LOGIN FAILURES
		SELECT @body2 = cast( (
		select td = CONCAT(d.ServerInstanceName,'</td><td>',d.PrincipalName,'</td><td>',CONVERT(varchar(50),d.dDate),'</td><td>',convert(varchar(500),d.StatementIssued) )
		from (
					SELECT 
						UPPER(ISNULL(S.ServerResolvedName,L.ServerInstanceName)) AS ServerInstanceName, 
						ISNULL(PrincipalName,'') AS PrincipalName, 
						LEFT(dtDate,20) AS dDate, 
						ISNULL(StatementIssued,'') AS StatementIssued
					FROM dbo.LoginFailure AS L
						LEFT JOIN dbo.Server AS S ON L.ServerInstanceName = S.ServerNm
					WHERE	(@ServerName IS NULL OR ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
						AND (dtDate BETWEEN @StartDate AND @EndDate) 
						AND (PrincipalName = '0' AND LEFT(StatementIssued,25) != 'Network error code 0x2746')
					GROUP BY ISNULL(S.ServerResolvedName,L.ServerInstanceName), PrincipalName, LEFT(dtDate,20), StatementIssued
				) as d
		for xml path( 'tr' ), type ) as varchar(max) )
		SELECT @body2 = (CASE WHEN len(@body2) IS NULL THEN '' ELSE		
						(CONCAT('<table cellpadding="2" cellspacing="2" border="0"><tr><th style="background:#DBCFD0">Instance</th><th style="background:#DBCFD0">Name</th><th style="background:#DBCFD0">Date</th><th style="background:#DBCFD0">Statement Issued</th></tr>'
					, replace( replace( @body2, '&lt;', '<' ), '&gt;', '>' )
					, '</table>')) END);
		SELECT @body2 = LEFT(@body2,40000) -- Limit to 40 of the 64k

		----- Login Changes Get
		SELECT @body3 =	cast( (
		select td = CONCAT(d.ServerInstanceName,'</td><td>',d.Name,'</td><td>',CONVERT(varchar(50),d.Type),'</td><td>',CONVERT(varchar(50),d.create_date),'</td><td>',CONVERT(varchar(50),d.modify_date),'</td><td>',CONVERT(varchar(50),d.AuditDtBegin),'</td><td>',CONVERT(varchar(50),d.AuditDtEnd),'</td><td>',convert(varchar(50),d.AuditAction) )
		from  (
						SELECT 
							UPPER(ISNULL(S.ServerResolvedName,L.ServerInstanceName))  AS ServerInstanceName, 
							ISNULL([name],'') AS [name], 
							( CASE [type]	WHEN 'S' THEN 'Sql Login'
											WHEN 'U' THEN 'Windows Login'
											WHEN 'G' THEN 'Windows Group'
											WHEN 'R' THEN 'Server Role'
											WHEN 'C' THEN 'Certificate'
											WHEN 'K' THEN 'Asymmestric Key'
											ELSE 'Unknown' END 	) AS [Type], 
							create_date, modify_date, AuditDtBegin, AuditDtEnd,
							ISNULL(AuditAction,'') AS AuditAction
						FROM dbo.LoginScanRecord AS L
								LEFT JOIN dbo.Server AS S ON L.ServerInstanceName = S.ServerNm
						WHERE	(@ServerName IS NULL OR ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
							AND (AuditdtBegin BETWEEN @StartDate AND @EndDate OR AuditdtEnd BETWEEN @StartDate AND @EndDate) 
				) as d
		for xml path( 'tr' ), type ) as varchar(max) )
		SELECT @body3 = (CASE WHEN len(@body3) IS NULL THEN '' ELSE		
						(CONCAT('<table cellpadding="2" cellspacing="2" border="0"><tr><th style="background:#DBCFD0">Instance</th><th style="background:#DBCFD0">Name</th><th style="background:#DBCFD0">Type</th><th style="background:#DBCFD0">Create Date</th><th style="background:#DBCFD0">Modify Date</th><th style="background:#DBCFD0">Audit Date Begin</th><th style="background:#DBCFD0">Audit Date End</th><th style="background:#DBCFD0">Audit Action</th></tr>'
					, replace( replace( @body3, '&lt;', '<' ), '&gt;', '>' )
					, '</table>')) END);
		SELECT @body3 = LEFT(@body3,40000) -- Limit to 40 of the 64k

		------- Schema Changes
		SELECT @body4 =	cast( (
		select td =  CONCAT(CONVERT(varchar(50),d.ChangeDate), '</td><td>', d.ServerName, '</td><td>', d.DatabaseName, '</td><td>', d.ObjectName, '</td><td>', d.ObjectType, '</td><td>', d.DDLOperation, '</td><td>', d.LoginName, '</td><td>', d.NTUserName, '</td><td>', d.ApplicationName)
		from (
							SELECT 
								ChangeDate, 
								UPPER(ISNULL(S.ServerResolvedName,L.ServerName)) AS ServerName, 
								ISNULL(DatabaseName,'') AS DatabaseName, 
								ISNULL(ObjectName,'') AS ObjectName, 
								ISNULL(ObjectType,'') AS ObjectType, 
								ISNULL(DDLOperation,'') AS DDLOperation, 
								ISNULL(LoginName,'') AS LoginName, 
								ISNULL(NTUserName,'') AS NTUserName,
								ISNULL(ApplicationName,'') AS ApplicationName
							FROM dbo.SchemaChange AS L
								LEFT JOIN dbo.Server AS S ON L.ServerName = S.ServerNm
							WHERE	(@ServerName IS NULL OR ServerName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
								AND ChangeDate BETWEEN @StartDate AND @EndDate
				) as d
		for xml path( 'tr' ), type ) as varchar(max) )
		SELECT @body4 = (CASE WHEN len(@body4) IS NULL THEN '' ELSE		
						(CONCAT('<table cellpadding="2" cellspacing="2" border="0"><tr><th style="background:#DBCFD0">Change Date</th><th style="background:#DBCFD0">Server Name</th><th style="background:#DBCFD0">Database</th><th style="background:#DBCFD0">Object Name</th><th style="background:#DBCFD0">Object Type</th><th style="background:#DBCFD0">DDL Operation</th><th style="background:#DBCFD0">LoginName</th><th style="background:#DBCFD0">NT User Name</th><th style="background:#DBCFD0">Application</th></tr>'
						, replace( replace( @body4, '&lt;', '<' ), '&gt;', '>' )
						, '</table>')) END);
		SELECT @body4 = LEFT(@body4,40000) -- Limit to 40 of the 64k

		------- Permission Changes Get
		SELECT @body5 =	cast( (
		select td = CONCAT(d.ServerName,'</td><td>',d.[Database],'</td><td>',d.[User],'</td><td>',d.Permission,'</td><td>',d.Action,'</td><td>',d.Securable,'</td><td>',CONVERT(varchar(50),d.AuditDtBegin),'</td><td>',CONVERT(varchar(50),d.AuditDtEnd),'</td><td>',d.AuditAction)
		from (
					SELECT 
						UPPER(ISNULL(S.ServerResolvedName,L.ServerName)) AS ServerName, 
						ISNULL([Database],'') AS [Database], 
						ISNULL([User],'') AS [User], 
						ISNULL(Permission,'') AS Permission, 
						ISNULL([Action],'') AS [Action], 
						ISNULL(Securable,'') AS Securable, 
						AuditDtBegin, 
						AuditDtEnd, 
						ISNULL(AuditAction,'') AS AuditAction
					FROM dbo.UserPermissionScan AS L
						LEFT JOIN dbo.Server AS S ON L.ServerName = S.ServerNm
					WHERE	(@ServerName IS NULL OR ServerName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
						AND (AuditDtBegin BETWEEN @StartDate AND @EndDate OR AuditDtEnd BETWEEN @StartDate AND @EndDate)
				) as d
		for xml path( 'tr' ), type ) as varchar(max) )
		SELECT @body5 = (CASE WHEN len(@body5) IS NULL THEN '' ELSE		
						(CONCAT('<table cellpadding="2" cellspacing="2" border="0"><tr><th style="background:#DBCFD0">Instance</th><th style="background:#DBCFD0">Database</th><th style="background:#DBCFD0">User</th><th style="background:#DBCFD0">Permission</th><th style="background:#DBCFD0">Action</th><th style="background:#DBCFD0">Securable</th><th style="background:#DBCFD0">Begin</th><th style="background:#DBCFD0">End</th><th style="background:#DBCFD0">Audit Action</th></tr>'
					, replace( replace( @body5, '&lt;', '<' ), '&gt;', '>' )
					, '</table>')) END);
		SELECT @body5 = LEFT(@body5,40000) -- Limit to 40 of the 64k

		SELECT @bodyFIN = CONCAT( @StyleSheet,@Header,'<BR />',@GreenTitle,'LOGIN FAILURES</span></p><BR />', @body1,'<BR /><BR />',@GreenTitle,'LOGIN COUNTS</span></p><BR />',@body2,'<BR /><BR />',@GreenTitle,'LOGIN CHANGES</span></p><BR />',@body3,'<BR /><BR />',@GreenTitle,'SCHEMA CHANGES</span></p><BR />',@body4,'<BR /><BR />',@GreenTitle,'PERMISSION CHANGES</span></p><BR />',@body5);
		
		SELECT @bodyFIN = LEFT(@bodyFIN,60000); -- char limit 64k, leaving space for other vars

		If LEN(@bodyFIN) > 10
		BEGIN
		DECLARE @SubjectTxt   VARCHAR(50);
		SELECT @SubjectTxt   = CONCAT('Daily Audit ', UPPER(@InstanceName),':', UPPER(@ServerResolvedName));
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @E_profile_name,
			@recipients = @E_recipients,
			@body = @bodyFIN,
			@subject = @SubjectTxt,
			@body_format = 'HTML'; 
		END;



END
GO
/****** Object:  StoredProcedure [dbo].[EndAuditScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[EndAuditScan]
  @AuditScanID INT
AS
BEGIN
  SET NOCOUNT ON;
  
  UPDATE dbo.AuditScan
  SET ScanEndDate = GETDATE()
  WHERE AuditScanID = @AuditScanID;
END;
GO
/****** Object:  StoredProcedure [dbo].[ExecuteLoginScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	AUTHOR:		David Speight based on code from K. Brian Kelley
	SOURCE:		www.mssqltips.com/sqlservertip/2741/how-to-audit-login-changes-on-a-sql-server/
*/
CREATE PROC [dbo].[ExecuteLoginScan]
AS
BEGIN
  SET NOCOUNT ON;
  
	DECLARE @CurrentScanID INT;
	DECLARE @PreviousScanID INT;
	DECLARE @AuditDate DATETIME = (GETDATE());
    
	SET @PreviousScanID = (SELECT MAX(AuditScanID) FROM dbo.AuditScan);
	EXEC dbo.StartAuditScan @CurrentScanID OUTPUT;

	DELETE FROM dbo.CurrentLoginScan;

	INSERT INTO dbo.CurrentLoginScan
	([sid], [name], [type], create_date, modify_date, AuditScanID)
	SELECT [sid], [name], [type], create_date, modify_date, @CurrentScanID
	FROM master.sys.server_principals;

	-- Add new records
	INSERT INTO dbo.LoginScanRecord
	(AuditScanID, [sid], [name], [type], create_date, modify_date, AuditDtBegin, AuditAction)
	SELECT AuditScanID, [sid], [name], [type], create_date, modify_date, @AuditDate, 'Added'
	FROM dbo.CurrentLoginScan
	WHERE [sid] NOT IN (SELECT [Sid] FROM [dbo].[LoginScanRecord])
	
	-- Mark deleted records
	UPDATE dbo.LoginScanRecord
	SET AuditDtEnd = @AuditDate, 
		AuditAction = 'Deleted'
	WHERE AuditDtEnd IS NULL AND [sid] NOT IN (SELECT [Sid] FROM [dbo].[CurrentLoginScan])

	-- Mark Readded records
	INSERT INTO dbo.LoginScanRecord
	(AuditScanID, [sid], [name], [type], create_date, modify_date, AuditDtBegin, AuditAction)
	SELECT AuditScanID, [sid], [name], [type], create_date, modify_date, @AuditDate, 'ReAdded'
	FROM dbo.CurrentLoginScan
	WHERE [sid] IN (	SELECT ls.[sid]
						FROM [dbo].[LoginScanRecord] ls
						WHERE ls.ScanLogID = (SELECT MAX(ScanLogID) FROM [dbo].[LoginScanRecord] WHERE [sid] =ls.[sid])
						GROUP BY ls.[sid]
						HAVING MAX(ls.AuditDtEnd) IS NOT NULL
					)

	-- Changed items
	DECLARE @LoginScanReport TABLE ([sid] VARBINARY(85) NOT NULL);
	INSERT INTO @LoginScanReport 
	([sid])
	SELECT Curr.[sid]
	FROM dbo.CurrentLoginScan Curr
	JOIN (SELECT [sid], [name], [type], create_date, modify_date 
			FROM dbo.LoginScanRecord 
			WHERE AuditDtEnd IS NULL) Old
		ON Curr.[sid] = Old.[sid]
	WHERE (Curr.[name] <> Old.[name]) OR (Curr.[type] <> Old.[type]) 
			OR (Curr.create_date <> Old.create_date) OR (Curr.modify_date <> Old.modify_date);

	UPDATE dbo.LoginScanRecord
	SET AuditDtEnd = @AuditDate, 
		AuditAction = 'Historic'
	WHERE AuditDtEnd IS NULL AND [sid] IN (SELECT [sid] FROM @LoginScanReport);

	INSERT INTO dbo.LoginScanRecord
	(AuditScanID, [sid], [name], [type], create_date, modify_date, AuditDtBegin, AuditAction)
	SELECT AuditScanID, [sid], [name], [type], create_date, modify_date, @AuditDate, 'Modified'
	FROM dbo.CurrentLoginScan
	WHERE [sid] IN (SELECT [sid] FROM @LoginScanReport)

	
	EXEC dbo.EndAuditScan @CurrentScanID;

	-- Select our recent changes or updates
	SELECT * FROM [dbo].[LoginScanRecord] WHERE AuditDtBegin=@AuditDate OR AuditDtEnd = @AuditDate;

END;

GO
/****** Object:  StoredProcedure [dbo].[ExecuteSchemaChangeScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
/*
	Revision By:					David Speight
	Date:							Februray 2017
	Partly Based on query by:		Jason Brimhall
	URL:							jasonbrimhall.info/2015/03/11/audit-schema-change-report/
*/
-- =============================================
CREATE PROCEDURE [dbo].[ExecuteSchemaChangeScan]
@ExcludedDatabaseList NVARCHAR(4000) = NULL,	-- Comma separated. List all databases NOT to audit.
@IncludedDatabaseList NVARCHAR(4000) = NULL	-- Comma separated. List ONLY databases to include in audit. THIS setting overrides above setting.
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @CurrentScanID INT;
DECLARE @PreviousScanID INT;
DECLARE @AuditDate DATETIME = (GETDATE());
DECLARE @curDatabase NVARCHAR(150);
DECLARE @iCount INT;
DECLARE @StartTime DATETIME;
DECLARE @tDatabases TABLE (ID INT NOT NULL IDENTITY(1,1), DatabaseName nvarchar(150));

-- Get all databases on our instance
INSERT INTO @tDatabases ( DatabaseName )
SELECT [name] AS DatabaseName 
FROM master.sys.databases
WHERE @IncludedDatabaseList IS NULL;
-- Delete the databases we do not want
DELETE 
FROM @tDatabases
WHERE DatabaseName IN (SELECT [value] FROM dbo.SplitString(@ExcludedDatabaseList,','));

INSERT INTO @tDatabases ( DatabaseName )
SELECT [value] 
FROM dbo.SplitString(@IncludedDatabaseList,',')
WHERE  @IncludedDatabaseList IS NOT NULL;

SELECT @iCount = MAX(ID) FROM @tDatabases;

	--Begin Audit
	SET @PreviousScanID = (SELECT ISNULL(MAX(AuditScanID),0) FROM dbo.AuditScan);
	EXEC dbo.StartAuditScan @CurrentScanID OUTPUT;
	
	WHILE @iCount > 0
	BEGIN
				SELECT @curDatabase = DatabaseName FROM @tDatabases WHERE ID = @iCount;
				SELECT @StartTime = ISNULL(MAX(ChangeDate),'1900-01-01') FROM dbo.SchemaChange WHERE DatabaseName = @curDatabase;
 
				INSERT INTO dbo.SchemaChange
				(AuditScanID, ChangeDate, ServerName, DatabaseName, ObjectName, ObjectType, DDLOperation, LoginName, NTUserName, ApplicationName)
				SELECT  @CurrentScanID  
					, tt.StartTime AS ChangeDate 	
					, tt.ServerName
					, tt.DatabaseName
					, tt.ObjectName
					, sv.name AS ObjectType
					, tt.DDLOperation
					, tt.LoginName
					, tt.NTUserName
					, tt.ApplicationName  
				FROM (					SELECT ObjectName
										  , ObjectID
										  , DatabaseName
										  , StartTime
										  , EventClass
										  , EventSubClass
										  , ObjectType
										  , ServerName
										  , LoginName
										  , NTUserName
										  , ApplicationName
										  , (CASE EventClass	WHEN 46 THEN 'CREATE'
																WHEN 47 THEN 'DROP'
																WHEN 164 THEN 'ALTER' END) AS DDLOperation 
									FROM sys.fn_trace_gettable(CONVERT(VARCHAR(150), 
											( SELECT REVERSE(SUBSTRING(REVERSE(path),
													CHARINDEX('\',REVERSE(path)),256)) + 'log.trc'
												FROM    sys.traces
												WHERE   is_default = 1)), DEFAULT) T  
								  WHERE		EventClass in (46,47,164) 
											AND EventSubclass = 0
											AND ObjectType <> 21587					-- skip auto-statistics noise  
											AND ApplicationName != 'SQLServerCEIP'	-- There are 121,000 of these in master db 
											AND DatabaseName = @curDatabase
											AND ObjectName IS NOT NULL	
											AND StartTime > @StartTime
											AND StartTime > (	SELECT DATEADD(SECOND,1,ISNULL(MAX(ChangeDate),'1950-01-01'))
																FROM dbo.SchemaChange
																WHERE DatabaseName = @curDatabase)
						) tt
					INNER JOIN sys.trace_events AS te 
						ON tt.EventClass = te.trace_event_id
					INNER JOIN sys.trace_subclass_values tsv
						ON tt.EventClass = tsv.trace_event_id
						AND tt.ObjectType = tsv.subclass_value
					INNER JOIN master.dbo.spt_values sv 
						ON tsv.subclass_value = sv.number
						AND sv.type = 'EOD'
				ORDER BY StartTime DESC;
 
		SELECT @iCount = @iCount-1;
	END;

	EXEC dbo.EndAuditScan @CurrentScanID;

END


GO
/****** Object:  StoredProcedure [dbo].[ExecuteUserPermissionScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- Create date: 2017
-- =============================================
CREATE PROCEDURE [dbo].[ExecuteUserPermissionScan]
@ExcludedDatabaseList NVARCHAR(4000) = NULL,
@IncludedDatabaseList NVARCHAR(4000) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @CurrentScanID INT;
	DECLARE @PreviousScanID INT;
	DECLARE @AuditDate DATETIME = (GETDATE());
	DECLARE @curDatabase NVARCHAR(150);
	DECLARE @iCount INT;
	DECLARE @tDatabases TABLE (ID INT NOT NULL IDENTITY(1,1), DatabaseName nvarchar(150));
	DECLARE @tCurrPermission TABLE (ID INT NOT NULL IDENTITY(1,1),[ServerName] NVARCHAR(150), [DatabaseName] NVARCHAR(150), [User] NVARCHAR(128), [Permission] NVARCHAR(50), [Action] NVARCHAR(50), [Securable] NVARCHAR(500), [CheckSumDigi] BIGINT );

	-- Get all databases on our instance
	INSERT INTO @tDatabases ( DatabaseName )
	SELECT [name] AS DatabaseName 
	FROM master.sys.databases
	WHERE @IncludedDatabaseList IS NULL;
	-- Delete the databases we do not want
	DELETE 
	FROM @tDatabases
	WHERE DatabaseName IN (SELECT [value] FROM dbo.SplitString(@ExcludedDatabaseList,','));

	INSERT INTO @tDatabases ( DatabaseName )
	SELECT [value] 
	FROM dbo.SplitString(@IncludedDatabaseList,',')
	WHERE  @IncludedDatabaseList IS NOT NULL;

	SELECT @iCount = MAX(ID) FROM @tDatabases;
	

	-- Begin Audit
	SET @PreviousScanID = (SELECT MAX(AuditScanID) FROM dbo.AuditScan);
	EXEC dbo.StartAuditScan @CurrentScanID OUTPUT;
	
	WHILE @iCount > 0
	BEGIN
		-- Clear temp table
		DELETE
		FROM @tCurrPermission;

		SELECT @curDatabase = DatabaseName FROM @tDatabases WHERE ID = @iCount;

		DECLARE @qSQL NVARCHAR(4000)
		SELECT @qSql = '
		SELECT @@SERVERNAME AS [ServerName]
		, '''+@curDatabase+''' AS [DATABASE]
		,  USER_NAME(grantee_principal_id) AS ''User''
		,  state_desc AS ''Permission''
		, permission_name AS ''ACTION''
		, CASE class
			  WHEN 0 THEN ''Database::'' + DB_NAME()
			  WHEN 1 THEN OBJECT_NAME(major_id)
			  WHEN 3 THEN ''Schema::'' + SCHEMA_NAME(major_id) END AS ''Securable''
		, CHECKSUM(CONVERT(NVARCHAR(150),@@SERVERNAME),CONVERT(NVARCHAR(150),'''+ @curDatabase +'''),CONVERT(NVARCHAR(128),USER_NAME(grantee_principal_id)),
												state_desc,
												CONVERT(NVARCHAR(50),permission_name),(CASE class
												  WHEN 0 THEN ''Database::'' + DB_NAME()
												  WHEN 1 THEN OBJECT_NAME(major_id)
												  WHEN 3 THEN ''Schema::'' + SCHEMA_NAME(major_id) END))
		FROM '
		+ @curDatabase +
		'.sys.database_permissions dp
		WHERE class IN (0, 1, 3) AND minor_id = 0
		ORDER BY 3,6;'

		INSERT INTO @tCurrPermission (ServerName,DatabaseName, [User],Permission,[Action],Securable,[CheckSumDigi])
		EXECUTE(@qSql);

		-- DELETE DUPES
		DELETE 
		FROM  @tCurrPermission
		WHERE CheckSumDigi IN (SELECT CheckSumDigi FROM @tCurrPermission GROUP BY CheckSumDigi HAVING COUNT(CheckSumDigi) > 1)
			AND ID NOT IN (SELECT MAX(ID) FROM @tCurrPermission GROUP BY CheckSumDigi);

		-- Flag the MISSING Rows [set Action = changed, set AuditEnd if not in temp table and AuditEnd=null]
		UPDATE [dbo].[UserPermissionScan]
		SET AuditDtEnd = @AuditDate, AuditAction='Historic'
		WHERE [Database]=@curDatabase AND AuditDtEnd IS NULL AND CheckSumDigi NOT IN (SELECT CheckSumDigi FROM @tCurrPermission) 

		-- Delete all rows with no changes.
		DELETE 
		FROM @tCurrPermission
		WHERE CheckSumDigi IN (SELECT CheckSumDigi FROM [dbo].[UserPermissionScan] WHERE AuditDtEnd IS NULL)

		-- Add the new rows
		INSERT INTO dbo.UserPermissionScan
		(AuditScanID, ServerName, [DATABASE], [USER], Permission, [Action], Securable, AuditDtBegin, AuditAction)
		SELECT @CurrentScanID, ServerName, DataBaseName, [USER], Permission, [Action], Securable, @AuditDate, 'Added'
		FROM @tCurrPermission

		SELECT @iCount = @iCount-1;
	END;

	EXEC dbo.EndAuditScan @CurrentScanID;
	
END
GO
/****** Object:  StoredProcedure [dbo].[LoginAuditRecord]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- =============================================
CREATE PROCEDURE [dbo].[LoginAuditRecord] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO dbo.LoginAudit
	( [ServerName], [UserName], [LoginType], [IsDisabled], [IsServiceAccount], [IsSysAdmin], [IsProductionServer], [CreatedDate], [LastModified], [AuditDate])
	SELECT	@@SERVERNAME as ServerName,
			[name] as UserName,
			[type_desc] as LoginType,
			is_disabled as IsDisabled,
			(case when [name]  like '%SqlService%' then 1 else 0 end) as IsServiceAccount,
			IS_SRVROLEMEMBER('sysadmin', name) as isSysAdmin,
			1 as IsProductionServer,
			create_date as CreatedDate, 
			modify_date as LastModifiedDate,
			(getdate()) as AuditDate
	from sys.server_principals
	where [type] in ('S','U') and [name] not like 'NT%' and [name] not like '##%';

END
GO
/****** Object:  StoredProcedure [dbo].[LoginChangesGet]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		David Speight
-- Create date: 2017-03-06
-- =============================================
CREATE PROCEDURE [dbo].[LoginChangesGet] 
@ServerName NVARCHAR(4000),		-- List of servers to query
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ServerInstanceName, [name], 
		( CASE [type]	WHEN 'S' THEN 'Sql Login'
						WHEN 'U' THEN 'Windows Login'
						WHEN 'G' THEN 'Windows Group'
						WHEN 'R' THEN 'Server Role'
						WHEN 'C' THEN 'Certificate'
						WHEN 'K' THEN 'Asymmestric Key'
						ELSE 'Unknown' END 	) AS [Type], 
		create_date, modify_date, AuditDtBegin, AuditDtEnd, AuditAction
	FROM dbo.LoginScanRecord
	WHERE	(ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
		AND (AuditdtBegin BETWEEN @StartDate AND @EndDate OR AuditdtEnd BETWEEN @StartDate AND @EndDate) 
	ORDER BY ServerInstanceName,[name], [type];

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END
GO
/****** Object:  StoredProcedure [dbo].[LoginCountGet]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		David Speight
-- Create date: 2017-03-06
-- =============================================
CREATE PROCEDURE [dbo].[LoginCountGet] 
@ServerName NVARCHAR(4000),		-- List of servers to query
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ServerInstanceName, PrincipalName, dDate, Success, [Count] AS Total
	FROM dbo.LoginCount
	WHERE	(ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
		AND (dDate BETWEEN CONVERT(DATE,@StartDate) AND CONVERT(DATE,@EndDate)) 
	ORDER BY ServerInstanceName, PrincipalName, dDate;

END
GO
/****** Object:  StoredProcedure [dbo].[LoginCountRecord]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- Create date: February 2017
-- =============================================
CREATE PROCEDURE [dbo].[LoginCountRecord]
@StartDate DATETIME = NULL,
@EndDate DATETIME = NULL,
@LogPath VARCHAR(500) = 'E:\MSSQL\Log\Audit\LoginAuditLog*'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- WHEN NO DATE PARAMS ARE PASSED -- We get only today's events
	SELECT @StartDate = (CASE WHEN @StartDate IS NULL THEN CONVERT(DATE,(GETDATE())) ELSE @StartDate END);
	SELECT @EndDate = (CASE WHEN @EndDate IS NULL THEN CONVERT(DATE,(DATEADD(DAY,1,GETDATE()))) ELSE @EndDate END);

	MERGE INTO dbo.LoginCount AS trgt
	USING	(
				SELECT server_instance_name, server_principal_name, CONVERT(DATE,event_time) AS dtEvent, succeeded, COUNT(*) AS [Count]
				FROM sys.fn_get_audit_file(@LogPath,NULL,NULL)
				WHERE action_id IN ('LGIF','LGIS')
				AND event_time BETWEEN @StartDate AND @EndDate
				GROUP BY server_instance_name, server_principal_name,CONVERT(DATE,event_time), succeeded
			) AS src
	ON (		trgt.ServerInstanceName = src.server_instance_name 
			AND trgt.PrincipalName = src.server_principal_name
			AND trgt.dDate = src.dtEvent
			AND trgt.Success = src.succeeded)
	WHEN MATCHED THEN
		UPDATE SET [Count] = src.[Count]
	WHEN NOT MATCHED THEN
		INSERT (ServerInstanceName, PrincipalName, dDate, Success, [Count])
		VALUES (src.server_instance_name, src.server_principal_name, src.dtEvent, src.succeeded, src.[Count]);


END
GO
/****** Object:  StoredProcedure [dbo].[LoginFailureRecord]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- Create date: February 2017
-- =============================================
CREATE PROCEDURE [dbo].[LoginFailureRecord]
@StartDate DATETIME = NULL,
@EndDate DATETIME = NULL,
@LogPath VARCHAR(500) = 'L:\Audit\Audit_ToSecurityLog*'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- WHEN NO DATE PARAMS ARE PASSED -- We get only today's events
	SELECT @StartDate = (CASE WHEN @StartDate IS NULL THEN CONVERT(DATE,(GETDATE())) ELSE @StartDate END);
	SELECT @EndDate = (CASE WHEN @EndDate IS NULL THEN CONVERT(DATE,(DATEADD(DAY,1,GETDATE()))) ELSE @EndDate END);

	INSERT INTO dbo.LoginFailure
	(ServerInstanceName, PrincipalName, dtDate, StatementIssued)
    SELECT  server_instance_name, server_principal_id, event_time,  [statement] 
	FROM sys.fn_get_audit_file(@LogPath,NULL,NULL)
	WHERE action_id IN ('LGIF')
	AND event_time BETWEEN @StartDate AND @EndDate
	AND event_time > (SELECT ISNULL(MAX(dtDate),'2017-01-01') FROM dbo.LoginFailure)
	ORDER BY event_time;

END
GO
/****** Object:  StoredProcedure [dbo].[LoginFailureRecord_RDS]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		David Speight
-- Create date: 20200825
-- =============================================
CREATE   PROCEDURE [dbo].[LoginFailureRecord_RDS]
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO [dbo].[LoginFailure]
				([ServerInstanceName], [PrincipalName], [dtDate], [StatementIssued])
	SELECT		server_instance_name,  server_principal_name,  event_time, Concat(statement,' [',application_name,']')
	FROM		msdb.dbo.rds_fn_get_audit_file
	             ('D:\rdsdbdata\SQLAudit\*.sqlaudit'
	             , default
	             , default )
	WHERE		LEFT(statement,12) = 'Login failed'
				-- Remember Event_time is datatype DATETIME2 and must be converted.
				and CONVERT(Datetime,event_time) NOT IN (Select dtDate from [dbo].[LoginFailure]);

END
GO
/****** Object:  StoredProcedure [dbo].[LoginFailuresGet]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		David Speight
-- Create date: 2017-03-06
-- =============================================
CREATE PROCEDURE [dbo].[LoginFailuresGet] 
@ServerName NVARCHAR(4000),		-- List of servers to query
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ServerInstanceName, PrincipalName, LEFT(dtDate,20), StatementIssued
	FROM dbo.LoginFailure
	WHERE	(ServerInstanceName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
		AND (dtDate BETWEEN @StartDate AND @EndDate) 
	GROUP BY ServerInstanceName, PrincipalName, LEFT(dtDate,20), StatementIssued
	ORDER BY ServerInstanceName, PrincipalName, LEFT(dtDate,20);

END
GO
/****** Object:  StoredProcedure [dbo].[SchemaChangeGet]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		David Speight
-- Create date: 2017-03-06
-- =============================================
CREATE PROCEDURE [dbo].[SchemaChangeGet] 
@ServerName NVARCHAR(4000),		-- List of servers to query
@DatabaseName NVARCHAR(4000),	-- List of databases to query
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ChangeDate, ServerName, DatabaseName, ObjectName, ObjectType, DDLOperation, LoginName, NTUserName, ApplicationName
	FROM dbo.SchemaChange
	WHERE	ServerName IN (SELECT [value] FROM dbo.SplitString(@ServerName,','))
		AND	DatabaseName IN (SELECT [value] FROM dbo.SplitString(@DatabaseName,','))
		AND ChangeDate BETWEEN @StartDate AND @EndDate
	ORDER BY ServerName, DatabaseName, ChangeDate, ObjectName;

END
GO
/****** Object:  StoredProcedure [dbo].[StartAuditScan]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[StartAuditScan] 
  @AuditScanID INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  
  DECLARE @AuditScanIDTable TABLE(AuditScanID INT);
  
  INSERT INTO dbo.AuditScan (ScanStartDate) 
    OUTPUT INSERTED.AuditScanID INTO @AuditScanIDTable
  VALUES (GETDATE());
  
  SET @AuditScanID = (SELECT AuditScanID FROM @AuditScanIDTable);
END;
GO
/****** Object:  StoredProcedure [dbo].[UserPermissionGet]    Script Date: 4/18/2023 8:52:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		David Speight
-- Create date: 2017-03-06
-- =============================================
CREATE PROCEDURE [dbo].[UserPermissionGet] 
@ServerName NVARCHAR(4000),		-- List of servers to query
@DatabaseName NVARCHAR(4000),	-- List of databases to query
@StartDate DATETIME,
@EndDate DATETIME
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT 
		ServerName, [Database], [User], Permission, [Action], Securable, AuditDtBegin, AuditDtEnd, AuditAction
	FROM dbo.UserPermissionScan
	WHERE	(ServerName IN (SELECT [value] FROM dbo.SplitString(@ServerName,',')))
		AND	([Database] IN (SELECT [value] FROM dbo.SplitString(@DatabaseName,',')))
		AND (AuditDtBegin BETWEEN @StartDate AND @EndDate OR AuditDtEnd BETWEEN @StartDate AND @EndDate) 
	ORDER BY ServerName, [Database], [User], Permission;

END
GO
