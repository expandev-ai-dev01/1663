/**
 * @summary
 * Updates an existing scheduled clean configuration.
 * Allows modification of schedule parameters and criteria.
 * 
 * @procedure spScheduledCleanUpdate
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - PUT /api/v1/internal/scheduled-clean/:id
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
 * @param {BIT} active
 *   - Required: Yes
 *   - Description: Schedule activation status
 * 
 * @param {NVARCHAR(50)} frequency
 *   - Required: Yes
 *   - Description: Schedule frequency
 * 
 * @param {TIME} scheduleTime
 *   - Required: Yes
 *   - Description: Time of day for execution
 * 
 * @param {TINYINT} dayOfWeek
 *   - Required: No
 *   - Description: Day of week for weekly schedules
 * 
 * @param {TINYINT} dayOfMonth
 *   - Required: No
 *   - Description: Day of month for monthly schedules
 * 
 * @param {NVARCHAR(100)} cronExpression
 *   - Required: No
 *   - Description: Cron expression for custom schedules
 * 
 * @param {NVARCHAR(MAX)} directories
 *   - Required: Yes
 *   - Description: JSON array of directory paths
 * 
 * @param {NVARCHAR(MAX)} criteriaConfig
 *   - Required: Yes
 *   - Description: JSON criteria configuration
 * 
 * @returns {BIT} success - Update success indicator
 * 
 * @testScenarios
 * - Valid update with all parameters
 * - Frequency change validation
 * - Invalid schedule ID handling
 * - Multi-tenancy isolation verification
 * - Soft delete filtering
 */
CREATE OR ALTER PROCEDURE [functional].[spScheduledCleanUpdate]
  @idAccount INTEGER,
  @idScheduledClean INTEGER,
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

  IF (@idScheduledClean IS NULL)
  BEGIN
    ;THROW 51000, 'idScheduledCleanRequired', 1;
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
       * @rule {fn-scheduled-clean-update} Update schedule configuration
       */
      UPDATE [functional].[scheduledClean]
      SET
        [active] = @active,
        [frequency] = @frequency,
        [scheduleTime] = @scheduleTime,
        [dayOfWeek] = @dayOfWeek,
        [dayOfMonth] = @dayOfMonth,
        [cronExpression] = @cronExpression,
        [directories] = @directories,
        [criteriaConfig] = @criteriaConfig,
        [dateModified] = GETUTCDATE()
      WHERE [idScheduledClean] = @idScheduledClean
        AND [idAccount] = @idAccount
        AND [deleted] = 0;

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