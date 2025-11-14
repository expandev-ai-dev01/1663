/**
 * @summary
 * Retrieves detailed information about a specific scheduled clean configuration.
 * 
 * @procedure spScheduledCleanGet
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - GET /api/v1/internal/scheduled-clean/:id
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
 * @returns {ScheduledCleanDetail} Schedule configuration details
 * 
 * @testScenarios
 * - Valid retrieval with existing schedule
 * - Not found scenario with invalid ID
 * - Multi-tenancy isolation verification
 * - Soft delete filtering
 */
CREATE OR ALTER PROCEDURE [functional].[spScheduledCleanGet]
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

  /**
   * @output {ScheduledCleanDetail, 1, n}
   * @column {INT} idScheduledClean - Schedule identifier
   * @column {BIT} active - Schedule activation status
   * @column {NVARCHAR} frequency - Schedule frequency
   * @column {TIME} scheduleTime - Execution time
   * @column {TINYINT} dayOfWeek - Day of week for weekly schedules
   * @column {TINYINT} dayOfMonth - Day of month for monthly schedules
   * @column {NVARCHAR} cronExpression - Cron expression for custom schedules
   * @column {NVARCHAR} directories - JSON array of directories
   * @column {NVARCHAR} criteriaConfig - JSON criteria configuration
   * @column {DATETIME2} nextExecution - Next scheduled execution
   * @column {DATETIME2} lastExecution - Last execution timestamp
   * @column {DATETIME2} dateCreated - Creation timestamp
   * @column {DATETIME2} dateModified - Last modification timestamp
   */
  SELECT
    [schCln].[idScheduledClean],
    [schCln].[active],
    [schCln].[frequency],
    [schCln].[scheduleTime],
    [schCln].[dayOfWeek],
    [schCln].[dayOfMonth],
    [schCln].[cronExpression],
    [schCln].[directories],
    [schCln].[criteriaConfig],
    [schCln].[nextExecution],
    [schCln].[lastExecution],
    [schCln].[dateCreated],
    [schCln].[dateModified]
  FROM [functional].[scheduledClean] [schCln]
  WHERE [schCln].[idAccount] = @idAccount
    AND [schCln].[idScheduledClean] = @idScheduledClean
    AND [schCln].[deleted] = 0;
END;
GO