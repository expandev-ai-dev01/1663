/**
 * @summary
 * Creates a new clean operation record with initial status and criteria configuration.
 * This procedure initializes the file cleaning process by storing the directory path,
 * scan settings, and identification criteria.
 * 
 * @procedure spCleanOperationCreate
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - POST /api/v1/internal/clean-operation
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {NVARCHAR(500)} directoryPath
 *   - Required: Yes
 *   - Description: Full path of directory to be analyzed
 * 
 * @param {BIT} includeSubdirectories
 *   - Required: Yes
 *   - Description: Whether to include subdirectories in analysis
 * 
 * @param {NVARCHAR(MAX)} fileExtensions
 *   - Required: Yes
 *   - Description: JSON array of file extensions to identify as temporary
 * 
 * @param {NVARCHAR(MAX)} namingPatterns
 *   - Required: Yes
 *   - Description: JSON array of naming patterns for temporary files
 * 
 * @param {INT} minimumAgeDays
 *   - Required: Yes
 *   - Description: Minimum age in days for files to be considered
 * 
 * @param {BIGINT} minimumSizeBytes
 *   - Required: Yes
 *   - Description: Minimum size in bytes for files to be considered
 * 
 * @param {BIT} includeSystemFiles
 *   - Required: Yes
 *   - Description: Whether to include system files in analysis
 * 
 * @returns {INT} idCleanOperation - Created operation identifier
 * 
 * @testScenarios
 * - Valid creation with all required parameters
 * - Validation of directory path format
 * - Validation of minimum age and size constraints
 * - Multi-tenancy isolation verification
 */
CREATE OR ALTER PROCEDURE [functional].[spCleanOperationCreate]
  @idAccount INTEGER,
  @directoryPath NVARCHAR(500),
  @includeSubdirectories BIT,
  @fileExtensions NVARCHAR(MAX),
  @namingPatterns NVARCHAR(MAX),
  @minimumAgeDays INTEGER,
  @minimumSizeBytes BIGINT,
  @includeSystemFiles BIT
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

  IF (@directoryPath IS NULL OR LEN(TRIM(@directoryPath)) = 0)
  BEGIN
    ;THROW 51000, 'directoryPathRequired', 1;
  END;

  IF (@includeSubdirectories IS NULL)
  BEGIN
    ;THROW 51000, 'includeSubdirectoriesRequired', 1;
  END;

  IF (@fileExtensions IS NULL OR LEN(TRIM(@fileExtensions)) = 0)
  BEGIN
    ;THROW 51000, 'fileExtensionsRequired', 1;
  END;

  IF (@namingPatterns IS NULL OR LEN(TRIM(@namingPatterns)) = 0)
  BEGIN
    ;THROW 51000, 'namingPatternsRequired', 1;
  END;

  IF (@minimumAgeDays IS NULL)
  BEGIN
    ;THROW 51000, 'minimumAgeDaysRequired', 1;
  END;

  IF (@minimumSizeBytes IS NULL)
  BEGIN
    ;THROW 51000, 'minimumSizeBytesRequired', 1;
  END;

  IF (@includeSystemFiles IS NULL)
  BEGIN
    ;THROW 51000, 'includeSystemFilesRequired', 1;
  END;

  /**
   * @validation Business rule validation
   * @throw {invalidValue}
   */
  IF (@minimumAgeDays < 0)
  BEGIN
    ;THROW 51000, 'minimumAgeDaysMustBeEqualOrGreaterZero', 1;
  END;

  IF (@minimumSizeBytes < 0)
  BEGIN
    ;THROW 51000, 'minimumSizeBytesMustBeEqualOrGreaterZero', 1;
  END;

  BEGIN TRY
    DECLARE @idCleanOperation INTEGER;

    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-clean-operation-create} Create clean operation record
       */
      INSERT INTO [functional].[cleanOperation] (
        [idAccount],
        [directoryPath],
        [includeSubdirectories],
        [status],
        [dateCreated]
      )
      VALUES (
        @idAccount,
        @directoryPath,
        @includeSubdirectories,
        0,
        GETUTCDATE()
      );

      SET @idCleanOperation = SCOPE_IDENTITY();

      /**
       * @rule {fn-clean-criteria-create} Create associated criteria configuration
       */
      INSERT INTO [functional].[cleanCriteria] (
        [idAccount],
        [idCleanOperation],
        [fileExtensions],
        [namingPatterns],
        [minimumAgeDays],
        [minimumSizeBytes],
        [includeSystemFiles],
        [dateCreated]
      )
      VALUES (
        @idAccount,
        @idCleanOperation,
        @fileExtensions,
        @namingPatterns,
        @minimumAgeDays,
        @minimumSizeBytes,
        @includeSystemFiles,
        GETUTCDATE()
      );

      /**
       * @output {CleanOperationResult, 1, 1}
       * @column {INT} idCleanOperation - Created operation identifier
       */
      SELECT @idCleanOperation AS [idCleanOperation];

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO