USE ROLE DBT_ROLE;
USE WAREHOUSE DBT_WH;

-- Task 1 : dbt run every day at midnight UTC
CREATE OR ALTER TASK DBT_PROD_DB.DBT_SCHEMA.dbt_daily_run
  WAREHOUSE = DBT_WH
  SCHEDULE = 'USING CRON 0 0 * * * UTC'
  COMMENT = 'Daily dbt run on production project'
AS
  EXECUTE DBT PROJECT DBT_PROD_DB.DBT_SCHEMA.demosnowdbt_prod_gh_action
    COMMAND = 'run';

-- Task 2 : dbt test chained after the run
CREATE OR ALTER TASK DBT_PROD_DB.DBT_SCHEMA.dbt_daily_test
  WAREHOUSE = DBT_WH
  COMMENT = 'Daily dbt test after production run'
  AFTER DBT_PROD_DB.DBT_SCHEMA.dbt_daily_run
AS
  EXECUTE DBT PROJECT DBT_PROD_DB.DBT_SCHEMA.demosnowdbt_prod_gh_action
    COMMAND = 'test';
  
-- Resume tasks (child first, then parent)
ALTER TASK DBT_PROD_DB.DBT_SCHEMA.dbt_daily_test RESUME;
ALTER TASK DBT_PROD_DB.DBT_SCHEMA.dbt_daily_run RESUME;