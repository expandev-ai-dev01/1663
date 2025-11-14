/**
 * @summary
 * Updates the status and statistics of a clean operation.
 * Used to track progress and completion of file analysis and removal operations.
 * 
 * @procedure spCleanOperationUpdateStatus
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - PATCH /api/v1/internal/clean-operation/:id/status
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
 * @param {TINYINT} status
 *   - Required: Yes
 *   - Description: New status code (0=Not Started, 1=In Progress, 2=Completed, 3=Error)
 * 
 * @param {INT} totalFilesAnalyzed
 *   - Required: No
 *   - Description: Total files analyzed count
 * 
 * @param {INT} totalFilesRemoved
 *   - Required: No
 *   - Description: Total files removed count
 * 
 * @param {BIGINT} totalSpaceFreed
 *   - Required: No
 *   - Description: Total space freed in bytes
 * 
 * @returns {BIT} success - Update success indicator
 * 
 * @testScenarios
 * - Valid status update with statistics
 * - Status update without optional statistics
 * - Invalid operation ID handling
 * - Multi-tenancy isolation verification
 * - Status value validation
 */
CREATE OR ALTER PROCEDURE [functional].[spCleanOperationUpdateStatus]
  @idAccount INTEGER,
  @idCleanOperation INTEGER,
  @status TINYINT,
  @totalFilesAnalyzed INTEGER = NULL,
  @totalFilesRemoved INTEGER = NULL,
  @totalSpaceFreed BIGINT = NULL
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

  IF (@status IS NULL)
  BEGIN
    ;THROW 51000, 'statusRequired', 1;
  END;

  /**
   * @validation Business rule validation
   * @throw {invalidValue}
   */
  IF (@status NOT BETWEEN 0 AND 3)
  BEGIN
    ;THROW 51000, 'invalidStatusValue', 1;
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

  BEGIN TRY
    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-clean-operation-update} Update operation status and statistics
       */
      UPDATE [functional].[cleanOperation]
      SET
        [status] = @status,
        [totalFilesAnalyzed] = COALESCE(@totalFilesAnalyzed, [totalFilesAnalyzed]),
        [totalFilesRemoved] = COALESCE(@totalFilesRemoved, [totalFilesRemoved]),
        [totalSpaceFreed] = COALESCE(@totalSpaceFreed, [totalSpaceFreed]),
        [dateCompleted] = CASE WHEN @status = 2 THEN GETUTCDATE() ELSE [dateCompleted] END
      WHERE [idCleanOperation] = @idCleanOperation
        AND [idAccount] = @idAccount;

      /**
       * @output {UpdateResult, 1, 1}
       * @column {BIT} success - Update success indicator
       */
      SELECT CAST(1 AS BIT) AS [success];

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO