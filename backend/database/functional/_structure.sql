/**
 * @schema functional
 * Business logic schema for AutoClean application
 */
CREATE SCHEMA [functional];
GO

/**
 * @table {cleanOperation} Stores information about file cleaning operations
 * @multitenancy true
 * @softDelete false
 * @alias clnOpr
 */
CREATE TABLE [functional].[cleanOperation] (
  [idCleanOperation] INTEGER IDENTITY(1, 1) NOT NULL,
  [idAccount] INTEGER NOT NULL,
  [directoryPath] NVARCHAR(500) NOT NULL,
  [includeSubdirectories] BIT NOT NULL,
  [totalFilesAnalyzed] INTEGER NOT NULL DEFAULT (0),
  [totalFilesRemoved] INTEGER NOT NULL DEFAULT (0),
  [totalSpaceFreed] BIGINT NOT NULL DEFAULT (0),
  [status] TINYINT NOT NULL DEFAULT (0),
  [dateCreated] DATETIME2 NOT NULL DEFAULT (GETUTCDATE()),
  [dateCompleted] DATETIME2 NULL
);

/**
 * @table {cleanCriteria} Stores criteria configuration for file identification
 * @multitenancy true
 * @softDelete false
 * @alias clnCrt
 */
CREATE TABLE [functional].[cleanCriteria] (
  [idCleanCriteria] INTEGER IDENTITY(1, 1) NOT NULL,
  [idAccount] INTEGER NOT NULL,
  [idCleanOperation] INTEGER NOT NULL,
  [fileExtensions] NVARCHAR(MAX) NOT NULL,
  [namingPatterns] NVARCHAR(MAX) NOT NULL,
  [minimumAgeDays] INTEGER NOT NULL DEFAULT (7),
  [minimumSizeBytes] BIGINT NOT NULL DEFAULT (0),
  [includeSystemFiles] BIT NOT NULL DEFAULT (0),
  [dateCreated] DATETIME2 NOT NULL DEFAULT (GETUTCDATE())
);

/**
 * @table {identifiedFile} Stores information about files identified for removal
 * @multitenancy true
 * @softDelete false
 * @alias idnFil
 */
CREATE TABLE [functional].[identifiedFile] (
  [idIdentifiedFile] INTEGER IDENTITY(1, 1) NOT NULL,
  [idAccount] INTEGER NOT NULL,
  [idCleanOperation] INTEGER NOT NULL,
  [filePath] NVARCHAR(500) NOT NULL,
  [fileName] NVARCHAR(255) NOT NULL,
  [fileExtension] NVARCHAR(50) NOT NULL,
  [fileSizeBytes] BIGINT NOT NULL,
  [fileModifiedDate] DATETIME2 NOT NULL,
  [identificationCriteria] NVARCHAR(200) NOT NULL,
  [selected] BIT NOT NULL DEFAULT (1),
  [removed] BIT NOT NULL DEFAULT (0),
  [removalError] NVARCHAR(500) NULL,
  [dateCreated] DATETIME2 NOT NULL DEFAULT (GETUTCDATE())
);

/**
 * @table {scheduledClean} Stores scheduled cleaning configurations
 * @multitenancy true
 * @softDelete true
 * @alias schCln
 */
CREATE TABLE [functional].[scheduledClean] (
  [idScheduledClean] INTEGER IDENTITY(1, 1) NOT NULL,
  [idAccount] INTEGER NOT NULL,
  [active] BIT NOT NULL DEFAULT (0),
  [frequency] NVARCHAR(50) NOT NULL,
  [scheduleTime] TIME NOT NULL,
  [dayOfWeek] TINYINT NULL,
  [dayOfMonth] TINYINT NULL,
  [cronExpression] NVARCHAR(100) NULL,
  [directories] NVARCHAR(MAX) NOT NULL,
  [criteriaConfig] NVARCHAR(MAX) NOT NULL,
  [nextExecution] DATETIME2 NULL,
  [lastExecution] DATETIME2 NULL,
  [dateCreated] DATETIME2 NOT NULL DEFAULT (GETUTCDATE()),
  [dateModified] DATETIME2 NOT NULL DEFAULT (GETUTCDATE()),
  [deleted] BIT NOT NULL DEFAULT (0)
);

/**
 * @primaryKey {pkCleanOperation}
 * @keyType Object
 */
ALTER TABLE [functional].[cleanOperation]
ADD CONSTRAINT [pkCleanOperation] PRIMARY KEY CLUSTERED ([idCleanOperation]);

/**
 * @primaryKey {pkCleanCriteria}
 * @keyType Object
 */
ALTER TABLE [functional].[cleanCriteria]
ADD CONSTRAINT [pkCleanCriteria] PRIMARY KEY CLUSTERED ([idCleanCriteria]);

/**
 * @primaryKey {pkIdentifiedFile}
 * @keyType Object
 */
ALTER TABLE [functional].[identifiedFile]
ADD CONSTRAINT [pkIdentifiedFile] PRIMARY KEY CLUSTERED ([idIdentifiedFile]);

/**
 * @primaryKey {pkScheduledClean}
 * @keyType Object
 */
ALTER TABLE [functional].[scheduledClean]
ADD CONSTRAINT [pkScheduledClean] PRIMARY KEY CLUSTERED ([idScheduledClean]);

/**
 * @foreignKey {fkCleanCriteria_CleanOperation} Links criteria to operation
 * @target {functional.cleanOperation}
 */
ALTER TABLE [functional].[cleanCriteria]
ADD CONSTRAINT [fkCleanCriteria_CleanOperation] FOREIGN KEY ([idCleanOperation])
REFERENCES [functional].[cleanOperation]([idCleanOperation]);

/**
 * @foreignKey {fkIdentifiedFile_CleanOperation} Links identified files to operation
 * @target {functional.cleanOperation}
 */
ALTER TABLE [functional].[identifiedFile]
ADD CONSTRAINT [fkIdentifiedFile_CleanOperation] FOREIGN KEY ([idCleanOperation])
REFERENCES [functional].[cleanOperation]([idCleanOperation]);

/**
 * @check {chkCleanOperation_Status} Validates operation status values
 * @enum {0} Not Started
 * @enum {1} In Progress
 * @enum {2} Completed
 * @enum {3} Error
 */
ALTER TABLE [functional].[cleanOperation]
ADD CONSTRAINT [chkCleanOperation_Status] CHECK ([status] BETWEEN 0 AND 3);

/**
 * @check {chkCleanCriteria_MinimumAge} Validates minimum age is non-negative
 */
ALTER TABLE [functional].[cleanCriteria]
ADD CONSTRAINT [chkCleanCriteria_MinimumAge] CHECK ([minimumAgeDays] >= 0);

/**
 * @check {chkCleanCriteria_MinimumSize} Validates minimum size is non-negative
 */
ALTER TABLE [functional].[cleanCriteria]
ADD CONSTRAINT [chkCleanCriteria_MinimumSize] CHECK ([minimumSizeBytes] >= 0);

/**
 * @check {chkScheduledClean_Frequency} Validates frequency values
 * @enum {daily} Daily execution
 * @enum {weekly} Weekly execution
 * @enum {monthly} Monthly execution
 * @enum {custom} Custom cron expression
 */
ALTER TABLE [functional].[scheduledClean]
ADD CONSTRAINT [chkScheduledClean_Frequency] CHECK ([frequency] IN ('daily', 'weekly', 'monthly', 'custom'));

/**
 * @check {chkScheduledClean_DayOfWeek} Validates day of week range
 */
ALTER TABLE [functional].[scheduledClean]
ADD CONSTRAINT [chkScheduledClean_DayOfWeek] CHECK ([dayOfWeek] IS NULL OR ([dayOfWeek] BETWEEN 1 AND 7));

/**
 * @check {chkScheduledClean_DayOfMonth} Validates day of month range
 */
ALTER TABLE [functional].[scheduledClean]
ADD CONSTRAINT [chkScheduledClean_DayOfMonth] CHECK ([dayOfMonth] IS NULL OR ([dayOfMonth] BETWEEN 1 AND 31));

/**
 * @index {ixCleanOperation_Account} Multi-tenancy isolation index
 * @type ForeignKey
 */
CREATE NONCLUSTERED INDEX [ixCleanOperation_Account]
ON [functional].[cleanOperation]([idAccount]);

/**
 * @index {ixCleanOperation_Account_Status} Operation status filtering
 * @type Search
 */
CREATE NONCLUSTERED INDEX [ixCleanOperation_Account_Status]
ON [functional].[cleanOperation]([idAccount], [status])
INCLUDE ([dateCreated], [totalFilesRemoved], [totalSpaceFreed]);

/**
 * @index {ixCleanCriteria_Account_Operation} Criteria lookup by operation
 * @type ForeignKey
 */
CREATE NONCLUSTERED INDEX [ixCleanCriteria_Account_Operation]
ON [functional].[cleanCriteria]([idAccount], [idCleanOperation]);

/**
 * @index {ixIdentifiedFile_Account_Operation} File lookup by operation
 * @type ForeignKey
 */
CREATE NONCLUSTERED INDEX [ixIdentifiedFile_Account_Operation]
ON [functional].[identifiedFile]([idAccount], [idCleanOperation]);

/**
 * @index {ixIdentifiedFile_Account_Selected} Selected files filtering
 * @type Search
 */
CREATE NONCLUSTERED INDEX [ixIdentifiedFile_Account_Selected]
ON [functional].[identifiedFile]([idAccount], [selected])
INCLUDE ([removed], [fileSizeBytes]);

/**
 * @index {ixScheduledClean_Account} Multi-tenancy isolation index
 * @type ForeignKey
 * @filter Active schedules only
 */
CREATE NONCLUSTERED INDEX [ixScheduledClean_Account]
ON [functional].[scheduledClean]([idAccount])
WHERE [deleted] = 0;

/**
 * @index {ixScheduledClean_Account_Active} Active schedules filtering
 * @type Search
 * @filter Active and not deleted
 */
CREATE NONCLUSTERED INDEX [ixScheduledClean_Account_Active]
ON [functional].[scheduledClean]([idAccount], [active])
INCLUDE ([nextExecution], [frequency])
WHERE [deleted] = 0;
GO