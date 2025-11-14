/**
 * @summary
 * Creates a new scheduled clean configuration.
 * Allows users to automate file cleaning operations on a recurring schedule.
 * 
 * @procedure spScheduledCleanCreate
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - POST /api/v1/internal/scheduled-clean
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @param {BIT} active
 *   - Required: Yes
 *   - Description: Schedule activation status
 * 
 * @param {NVARCHAR(50)} frequency
 *   - Required: Yes
 *   - Description: Schedule frequency (daily, weekly, monthly, custom)
 * 
 * @param {TIME} scheduleTime
 *   - Required: Yes
 *   - Description: Time of day for execution
 * 
 * @param {TINYINT} dayOfWeek
 *   - Required: No
 *   - Description: Day of week for weekly schedules (1-7)
 * 
 * @param {TINYINT} dayOfMonth
 *   - Required: No
 *   - Description: Day of month for monthly schedules (1-31)
 * 
 * @param {NVARCHAR(100)} cronExpression
 *   - Required: No
 *   - Description: Cron expression for custom schedules
 * 
 * @param {NVARCHAR(MAX)} directories
 *   - Required: Yes
 *   - Description: JSON array of directory paths to clean
 * 
 * @param {NVARCHAR(MAX)} criteriaConfig
 *   - Required: Yes
 *   - Description: JSON object with cleaning criteria configuration
 * 
 * @returns {INT} idScheduledClean - Created schedule identifier
 * 
 * @testScenarios
 * - Valid daily schedule creation
 * - Valid weekly schedule with day of week
 * - Valid monthly schedule with day of month
 * - Valid custom schedule with cron expression
 * - Validation of frequency-specific parameters
 * - Multi-tenancy isolation verification
 */
CREATE OR ALTER PROCEDURE [functional].[spScheduledCleanCreate]
  @idAccount INTEGER,
  @active BIT,
  @frequency NVARCHAR(50),
  @scheduleTime TIME,
  @dayOfWeek TINYINT = NULL,
  @dayOfMonth TINYINT = NULL,
  @cronExpression NVARCHAR(100) = NULL,
  @directories NVARCHAR(MAX),
  @criteriaConfig NVARCHAR(MAX)
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

  IF (@active IS NULL)
  BEGIN
    ;THROW 51000, 'activeRequired', 1;
  END;

  IF (@frequency IS NULL OR LEN(TRIM(@frequency)) = 0)
  BEGIN
    ;THROW 51000, 'frequencyRequired', 1;
  END;

  IF (@scheduleTime IS NULL)
  BEGIN
    ;THROW 51000, 'scheduleTimeRequired', 1;
  END;

  IF (@directories IS NULL OR LEN(TRIM(@directories)) = 0)
  BEGIN
    ;THROW 51000, 'directoriesRequired', 1;
  END;

  IF (@criteriaConfig IS NULL OR LEN(TRIM(@criteriaConfig)) = 0)
  BEGIN
    ;THROW 51000, 'criteriaConfigRequired', 1;
  END;

  /**
   * @validation Business rule validation
   * @throw {invalidValue}
   */
  IF (@frequency NOT IN ('daily', 'weekly', 'monthly', 'custom'))
  BEGIN
    ;THROW 51000, 'invalidFrequencyValue', 1;
  END;

  IF ((@frequency = 'weekly') AND (@dayOfWeek IS NULL))
  BEGIN
    ;THROW 51000, 'dayOfWeekRequiredForWeeklySchedule', 1;
  END;

  IF ((@frequency = 'monthly') AND (@dayOfMonth IS NULL))
  BEGIN
    ;THROW 51000, 'dayOfMonthRequiredForMonthlySchedule', 1;
  END;

  IF ((@frequency = 'custom') AND (@cronExpression IS NULL OR LEN(TRIM(@cronExpression)) = 0))
  BEGIN
    ;THROW 51000, 'cronExpressionRequiredForCustomSchedule', 1;
  END;

  IF ((@dayOfWeek IS NOT NULL) AND (@dayOfWeek NOT BETWEEN 1 AND 7))
  BEGIN
    ;THROW 51000, 'invalidDayOfWeekValue', 1;
  END;

  IF ((@dayOfMonth IS NOT NULL) AND (@dayOfMonth NOT BETWEEN 1 AND 31))
  BEGIN
    ;THROW 51000, 'invalidDayOfMonthValue', 1;
  END;

  BEGIN TRY
    DECLARE @idScheduledClean INTEGER;

    /**
     * @rule {db-transaction-control} Transaction management for data integrity
     */
    BEGIN TRAN;

      /**
       * @rule {fn-scheduled-clean-create} Create scheduled clean configuration
       */
      INSERT INTO [functional].[scheduledClean] (
        [idAccount],
        [active],
        [frequency],
        [scheduleTime],
        [dayOfWeek],
        [dayOfMonth],
        [cronExpression],
        [directories],
        [criteriaConfig],
        [dateCreated],
        [dateModified],
        [deleted]
      )
      VALUES (
        @idAccount,
        @active,
        @frequency,
        @scheduleTime,
        @dayOfWeek,
        @dayOfMonth,
        @cronExpression,
        @directories,
        @criteriaConfig,
        GETUTCDATE(),
        GETUTCDATE(),
        0
      );

      SET @idScheduledClean = SCOPE_IDENTITY();

      /**
       * @output {ScheduledCleanResult, 1, 1}
       * @column {INT} idScheduledClean - Created schedule identifier
       */
      SELECT @idScheduledClean AS [idScheduledClean];

    COMMIT TRAN;
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO