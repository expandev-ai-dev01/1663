/**
 * @summary
 * Soft deletes a scheduled clean configuration.
 * Sets the deleted flag to prevent execution while preserving history.
 * 
 * @procedure spScheduledCleanDelete
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - DELETE /api/v1/internal/scheduled-clean/:id
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {INT} idScheduledClean
 *   - Required: Yes
 *   - Description: Scheduled clean identifier
 * 
 * @returns {BIT} success - Delete success indicator
 * 
 * @testScenarios
 * - Valid soft delete of existing schedule
 * - Invalid schedule ID handling
 * - Multi-tenancy isolation verification
 * - Already deleted schedule handling
 */
CREATE OR ALTER PROCEDURE [functional].[spScheduledCleanDelete]
  @idAccount INTEGER,
  @idScheduledClean INTEGER
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

  IF (@idScheduledClean IS NULL)
  BEGIN
    ;THROW 51000, 'idScheduledCleanRequired', 1;
  END;

  /**
   * @validation Data consistency validation
   * @throw {recordNotFound}
   */
  IF NOT EXISTS (
    SELECT *
    FROM [functional].[scheduledClean] schCln
    WHERE [schCln].[idScheduledClean] = @idScheduledClean
      AND [schCln].[idAccount] = @idAccount
      AND [schCln].[deleted] = 0
  )
  BEGIN
    ;THROW 51000, 'scheduledCleanDoesntExist', 1;
  END;

  BEGIN TRY
    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-scheduled-clean-soft-delete} Soft delete schedule
       */
      UPDATE [functional].[scheduledClean]
      SET
        [deleted] = 1,
        [active] = 0,
        [dateModified] = GETUTCDATE()
      WHERE [idScheduledClean] = @idScheduledClean
        AND [idAccount] = @idAccount
        AND [deleted] = 0;

      /**
       * @output {DeleteResult, 1, 1}
       * @column {BIT} success - Delete success indicator
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