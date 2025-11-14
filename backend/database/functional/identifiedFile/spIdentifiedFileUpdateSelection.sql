/**
 * @summary
 * Updates the selection status of identified files for removal.
 * Allows users to select or deselect files before executing removal operation.
 * 
 * @procedure spIdentifiedFileUpdateSelection
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - PATCH /api/v1/internal/identified-file/selection
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {NVARCHAR(MAX)} fileIds
 *   - Required: Yes
 *   - Description: JSON array of file IDs to update
 * 
 * @param {BIT} selected
 *   - Required: Yes
 *   - Description: New selection status
 * 
 * @returns {INT} updatedCount - Number of files updated
 * 
 * @testScenarios
 * - Valid selection update for multiple files
 * - Valid deselection update
 * - Empty file IDs array handling
 * - Multi-tenancy isolation verification
 */
CREATE OR ALTER PROCEDURE [functional].[spIdentifiedFileUpdateSelection]
  @idAccount INTEGER,
  @fileIds NVARCHAR(MAX),
  @selected BIT
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

  IF (@fileIds IS NULL OR LEN(TRIM(@fileIds)) = 0)
  BEGIN
    ;THROW 51000, 'fileIdsRequired', 1;
  END;

  IF (@selected IS NULL)
  BEGIN
    ;THROW 51000, 'selectedRequired', 1;
  END;

  BEGIN TRY
    DECLARE @updatedCount INTEGER;

    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-identified-file-update-selection} Update file selection status
       */
      UPDATE [idnFil]
      SET [idnFil].[selected] = @selected
      FROM [functional].[identifiedFile] [idnFil]
        CROSS APPLY OPENJSON(@fileIds) WITH ([idIdentifiedFile] INTEGER '$') [ids]
      WHERE [idnFil].[idAccount] = @idAccount
        AND [idnFil].[idIdentifiedFile] = [ids].[idIdentifiedFile];

      SET @updatedCount = @@ROWCOUNT;

      /**
       * @output {UpdateResult, 1, 1}
       * @column {INT} updatedCount - Number of files updated
       */
      SELECT @updatedCount AS [updatedCount];

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO