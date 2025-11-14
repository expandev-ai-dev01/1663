/**
 * @summary
 * Retrieves detailed information about a specific clean operation including
 * its criteria configuration and statistics.
 * 
 * @procedure spCleanOperationGet
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - GET /api/v1/internal/clean-operation/:id
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {INT} idCleanOperation
 *   - Required: Yes
 *   - Description: Clean operation identifier
 * 
 * @returns {CleanOperationDetail} Operation details with criteria
 * 
 * @testScenarios
 * - Valid retrieval with existing operation
 * - Not found scenario with invalid ID
 * - Multi-tenancy isolation verification
 */
CREATE OR ALTER PROCEDURE [functional].[spCleanOperationGet]
  @idAccount INTEGER,
  @idCleanOperation INTEGER
AS
BEGIN
  SET NOCOUNT ON;

  /**
   * @validation Required parameter validation
   * @throw {parameterRequired}
   */
  IF (@idAccount IS NULL)
  BEGIN
    ;THROW 51000, 'idAccountRequired', 1;
  END;

  IF (@idCleanOperation IS NULL)
  BEGIN
    ;THROW 51000, 'idCleanOperationRequired', 1;
  END;

  /**
   * @validation Data consistency validation
   * @throw {recordNotFound}
   */
  IF NOT EXISTS (
    SELECT *
    FROM [functional].[cleanOperation] clnOpr
    WHERE [clnOpr].[idCleanOperation] = @idCleanOperation
      AND [clnOpr].[idAccount] = @idAccount
  )
  BEGIN
    ;THROW 51000, 'cleanOperationDoesntExist', 1;
  END;

  /**
   * @output {CleanOperationDetail, 1, n}
   * @column {INT} idCleanOperation - Operation identifier
   * @column {NVARCHAR} directoryPath - Directory path analyzed
   * @column {BIT} includeSubdirectories - Subdirectories inclusion flag
   * @column {INT} totalFilesAnalyzed - Total files analyzed count
   * @column {INT} totalFilesRemoved - Total files removed count
   * @column {BIGINT} totalSpaceFreed - Total space freed in bytes
   * @column {TINYINT} status - Operation status code
   * @column {DATETIME2} dateCreated - Operation creation timestamp
   * @column {DATETIME2} dateCompleted - Operation completion timestamp
   * @column {NVARCHAR} fileExtensions - JSON array of file extensions
   * @column {NVARCHAR} namingPatterns - JSON array of naming patterns
   * @column {INT} minimumAgeDays - Minimum age criteria in days
   * @column {BIGINT} minimumSizeBytes - Minimum size criteria in bytes
   * @column {BIT} includeSystemFiles - System files inclusion flag
   */
  SELECT
    [clnOpr].[idCleanOperation],
    [clnOpr].[directoryPath],
    [clnOpr].[includeSubdirectories],
    [clnOpr].[totalFilesAnalyzed],
    [clnOpr].[totalFilesRemoved],
    [clnOpr].[totalSpaceFreed],
    [clnOpr].[status],
    [clnOpr].[dateCreated],
    [clnOpr].[dateCompleted],
    [clnCrt].[fileExtensions],
    [clnCrt].[namingPatterns],
    [clnCrt].[minimumAgeDays],
    [clnCrt].[minimumSizeBytes],
    [clnCrt].[includeSystemFiles]
  FROM [functional].[cleanOperation] [clnOpr]
    JOIN [functional].[cleanCriteria] [clnCrt] ON (
      [clnCrt].[idAccount] = [clnOpr].[idAccount]
      AND [clnCrt].[idCleanOperation] = [clnOpr].[idCleanOperation]
    )
  WHERE [clnOpr].[idAccount] = @idAccount
    AND [clnOpr].[idCleanOperation] = @idCleanOperation;
END;
GO