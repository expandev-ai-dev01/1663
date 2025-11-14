/**
 * @summary
 * Updates the removal status of an identified file after removal attempt.
 * Records success or failure with error message.
 * 
 * @procedure spIdentifiedFileUpdateRemoval
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - PATCH /api/v1/internal/identified-file/:id/removal
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {INT} idIdentifiedFile
 *   - Required: Yes
 *   - Description: Identified file identifier
 * 
 * @param {BIT} removed
 *   - Required: Yes
 *   - Description: Removal success status
 * 
 * @param {NVARCHAR(500)} removalError
 *   - Required: No
 *   - Description: Error message if removal failed
 * 
 * @returns {BIT} success - Update success indicator
 * 
 * @testScenarios
 * - Valid update for successful removal
 * - Valid update for failed removal with error message
 * - Invalid file ID handling
 * - Multi-tenancy isolation verification
 */
CREATE OR ALTER PROCEDURE [functional].[spIdentifiedFileUpdateRemoval]
  @idAccount INTEGER,
  @idIdentifiedFile INTEGER,
  @removed BIT,
  @removalError NVARCHAR(500) = NULL
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

  IF (@idIdentifiedFile IS NULL)
  BEGIN
    ;THROW 51000, 'idIdentifiedFileRequired', 1;
  END;

  IF (@removed IS NULL)
  BEGIN
    ;THROW 51000, 'removedRequired', 1;
  END;

  /**
   * @validation Data consistency validation
   * @throw {recordNotFound}
   */
  IF NOT EXISTS (
    SELECT *
    FROM [functional].[identifiedFile] idnFil
    WHERE [idnFil].[idIdentifiedFile] = @idIdentifiedFile
      AND [idnFil].[idAccount] = @idAccount
  )
  BEGIN
    ;THROW 51000, 'identifiedFileDoesntExist', 1;
  END;

  BEGIN TRY
    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-identified-file-update-removal} Update file removal status
       */
      UPDATE [functional].[identifiedFile]
      SET
        [removed] = @removed,
        [removalError] = @removalError
      WHERE [idIdentifiedFile] = @idIdentifiedFile
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