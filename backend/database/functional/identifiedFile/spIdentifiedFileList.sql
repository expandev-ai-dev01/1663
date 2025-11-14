/**
 * @summary
 * Lists all identified files for a specific clean operation.
 * Returns file metadata and current selection/removal status.
 * 
 * @procedure spIdentifiedFileList
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - GET /api/v1/internal/clean-operation/:id/files
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
 * @returns {IdentifiedFileList} List of identified files
 * 
 * @testScenarios
 * - Valid listing with existing files
 * - Empty result set for operation with no files
 * - Multi-tenancy isolation verification
 * - Correct ordering by file path
 */
CREATE OR ALTER PROCEDURE [functional].[spIdentifiedFileList]
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
   * @output {IdentifiedFileList, n, n}
   * @column {INT} idIdentifiedFile - File record identifier
   * @column {NVARCHAR} filePath - Full file path
   * @column {NVARCHAR} fileName - File name
   * @column {NVARCHAR} fileExtension - File extension
   * @column {BIGINT} fileSizeBytes - File size in bytes
   * @column {DATETIME2} fileModifiedDate - File last modified date
   * @column {NVARCHAR} identificationCriteria - Identification criteria
   * @column {BIT} selected - Selection status for removal
   * @column {BIT} removed - Removal completion status
   * @column {NVARCHAR} removalError - Error message if removal failed
   */
  SELECT
    [idnFil].[idIdentifiedFile],
    [idnFil].[filePath],
    [idnFil].[fileName],
    [idnFil].[fileExtension],
    [idnFil].[fileSizeBytes],
    [idnFil].[fileModifiedDate],
    [idnFil].[identificationCriteria],
    [idnFil].[selected],
    [idnFil].[removed],
    [idnFil].[removalError]
  FROM [functional].[identifiedFile] [idnFil]
  WHERE [idnFil].[idAccount] = @idAccount
    AND [idnFil].[idCleanOperation] = @idCleanOperation
  ORDER BY [idnFil].[filePath];
END;
GO