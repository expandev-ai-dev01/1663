/**
 * @summary
 * Lists all scheduled clean configurations for an account.
 * Returns only active (non-deleted) schedules ordered by creation date.
 * 
 * @procedure spScheduledCleanList
 * @schema functional
 * @type stored-procedure
 * 
 * @endpoints
 * - GET /api/v1/internal/scheduled-clean
 * 
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy isolation
 * 
 * @returns {ScheduledCleanList} List of schedule configurations
 * 
 * @testScenarios
 * - Valid listing with existing schedules
 * - Empty result set for account with no schedules
 * - Multi-tenancy isolation verification
 * - Soft delete filtering
 * - Correct ordering by date descending
 */
CREATE OR ALTER PROCEDURE [functional].[spScheduledCleanList]
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
   * @output {ScheduledCleanList, n, n}
   * @column {INT} idScheduledClean - Schedule identifier
   * @column {BIT} active - Schedule activation status
   * @column {NVARCHAR} frequency - Schedule frequency
   * @column {TIME} scheduleTime - Execution time
   * @column {TINYINT} dayOfWeek - Day of week for weekly schedules
   * @column {TINYINT} dayOfMonth - Day of month for monthly schedules
   * @column {DATETIME2} nextExecution - Next scheduled execution
   * @column {DATETIME2} lastExecution - Last execution timestamp
   * @column {DATETIME2} dateCreated - Creation timestamp
   */
  SELECT
    [schCln].[idScheduledClean],
    [schCln].[active],
    [schCln].[frequency],
    [schCln].[scheduleTime],
    [schCln].[dayOfWeek],
    [schCln].[dayOfMonth],
    [schCln].[nextExecution],
    [schCln].[lastExecution],
    [schCln].[dateCreated]
  FROM [functional].[scheduledClean] [schCln]
  WHERE [schCln].[idAccount] = @idAccount
    AND [schCln].[deleted] = 0
  ORDER BY [schCln].[dateCreated] DESC;
END;
GO