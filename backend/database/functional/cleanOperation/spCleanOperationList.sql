/**
 * @summary
 * Lists all clean operations for an account with summary statistics.
 * Results are ordered by creation date descending (most recent first).
 * 
 * @procedure spCleanOperationList
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - GET /api/v1/internal/clean-operation
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @returns {CleanOperationList} List of operations with statistics
 * 
 * @testScenarios
 * - Valid listing with existing operations
 * - Empty result set for account with no operations
 * - Multi-tenancy isolation verification
 * - Correct ordering by date descending
 */
CREATE OR ALTER PROCEDURE [functional].[spCleanOperationList]
  @idAccount INTEGER
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

  /**
   * @output {CleanOperationList, n, n}
   * @column {INT} idCleanOperation - Operation identifier
   * @column {NVARCHAR} directoryPath - Directory path analyzed
   * @column {BIT} includeSubdirectories - Subdirectories inclusion flag
   * @column {INT} totalFilesAnalyzed - Total files analyzed count
   * @column {INT} totalFilesRemoved - Total files removed count
   * @column {BIGINT} totalSpaceFreed - Total space freed in bytes
   * @column {TINYINT} status - Operation status code
   * @column {DATETIME2} dateCreated - Operation creation timestamp
   * @column {DATETIME2} dateCompleted - Operation completion timestamp
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
    [clnOpr].[dateCompleted]
  FROM [functional].[cleanOperation] [clnOpr]
  WHERE [clnOpr].[idAccount] = @idAccount
  ORDER BY [clnOpr].[dateCreated] DESC;
END;
GO