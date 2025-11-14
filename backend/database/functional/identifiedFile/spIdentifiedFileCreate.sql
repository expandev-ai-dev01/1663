/**
 * @summary
 * Creates a new identified file record during the analysis phase.
 * Stores file metadata and identification criteria for later selection and removal.
 * 
 * @procedure spIdentifiedFileCreate
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - POST /api/v1/internal/identified-file
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {INT} idCleanOperation
 *   - Required: Yes
 *   - Description: Associated clean operation identifier
 * 
 * @param {NVARCHAR(500)} filePath
 *   - Required: Yes
 *   - Description: Full path of the identified file
 * 
 * @param {NVARCHAR(255)} fileName
 *   - Required: Yes
 *   - Description: File name without path
 * 
 * @param {NVARCHAR(50)} fileExtension
 *   - Required: Yes
 *   - Description: File extension
 * 
 * @param {BIGINT} fileSizeBytes
 *   - Required: Yes
 *   - Description: File size in bytes
 * 
 * @param {DATETIME2} fileModifiedDate
 *   - Required: Yes
 *   - Description: File last modified date
 * 
 * @param {NVARCHAR(200)} identificationCriteria
 *   - Required: Yes
 *   - Description: Criteria that identified this file
 * 
 * @returns {INT} idIdentifiedFile - Created file record identifier
 * 
 * @testScenarios
 * - Valid file record creation
 * - Validation of required parameters
 * - Multi-tenancy isolation verification
 * - Foreign key constraint validation
 */
CREATE OR ALTER PROCEDURE [functional].[spIdentifiedFileCreate]
  @idAccount INTEGER,
  @idCleanOperation INTEGER,
  @filePath NVARCHAR(500),
  @fileName NVARCHAR(255),
  @fileExtension NVARCHAR(50),
  @fileSizeBytes BIGINT,
  @fileModifiedDate DATETIME2,
  @identificationCriteria NVARCHAR(200)
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

  IF (@filePath IS NULL OR LEN(TRIM(@filePath)) = 0)
  BEGIN
    ;THROW 51000, 'filePathRequired', 1;
  END;

  IF (@fileName IS NULL OR LEN(TRIM(@fileName)) = 0)
  BEGIN
    ;THROW 51000, 'fileNameRequired', 1;
  END;

  IF (@fileExtension IS NULL OR LEN(TRIM(@fileExtension)) = 0)
  BEGIN
    ;THROW 51000, 'fileExtensionRequired', 1;
  END;

  IF (@fileSizeBytes IS NULL)
  BEGIN
    ;THROW 51000, 'fileSizeBytesRequired', 1;
  END;

  IF (@fileModifiedDate IS NULL)
  BEGIN
    ;THROW 51000, 'fileModifiedDateRequired', 1;
  END;

  IF (@identificationCriteria IS NULL OR LEN(TRIM(@identificationCriteria)) = 0)
  BEGIN
    ;THROW 51000, 'identificationCriteriaRequired', 1;
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
    DECLARE @idIdentifiedFile INTEGER;

    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-identified-file-create} Create identified file record
       */
      INSERT INTO [functional].[identifiedFile] (
        [idAccount],
        [idCleanOperation],
        [filePath],
        [fileName],
        [fileExtension],
        [fileSizeBytes],
        [fileModifiedDate],
        [identificationCriteria],
        [selected],
        [removed],
        [dateCreated]
      )
      VALUES (
        @idAccount,
        @idCleanOperation,
        @filePath,
        @fileName,
        @fileExtension,
        @fileSizeBytes,
        @fileModifiedDate,
        @identificationCriteria,
        1,
        0,
        GETUTCDATE()
      );

      SET @idIdentifiedFile = SCOPE_IDENTITY();

      /**
       * @output {IdentifiedFileResult, 1, 1}
       * @column {INT} idIdentifiedFile - Created file record identifier
       */
      SELECT @idIdentifiedFile AS [idIdentifiedFile];

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO