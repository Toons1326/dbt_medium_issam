# demo_snowflake_dbt-v2

CI/CD pipeline for dbt using Snowflake's **native dbt integration** — no local dbt install needed.

This is the V2 of [demo_snowflake_dbt](https://github.com/eddaouissam/demo_snowflake_dbt). The main difference is that dbt now runs entirely inside Snowflake (Workspaces + dbt Project objects), and orchestration is handled by Snowflake Tasks instead of GitHub Actions cron.

## How it works

```
┌─────────────────────────────────────────────────────────────────────┐
│                        SNOWFLAKE WORKSPACE                         │
│                     (develop dbt models here)                      │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ git push (feature branch)
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            GITHUB                                  │
│                                                                    │
│   feature/branch ──── Pull Request ────── merge to main            │
│                             │                      │               │
│                             ▼                      ▼               │
│                     ┌──────────────┐      ┌──────────────┐         │
│                     │  CI Workflow  │      │  CD Workflow  │         │
│                     │              │      │              │         │
│                     │  deploy test │      │  deploy prod │         │
│                     │  dbt run     │      │  setup tasks │         │
│                     │  dbt test    │      │              │         │
│                     └──────┬───────┘      └──────┬───────┘         │
│                            │                     │                 │
└────────────────────────────┼─────────────────────┼─────────────────┘
                             │                     │
                             ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          SNOWFLAKE                                 │
│                                                                    │
│   ┌──────────────┐                    ┌──────────────┐             │
│   │  DBT_DEV_DB  │                    │  DBT_PROD_DB │             │
│   │              │                    │              │             │
│   │  tester dbt  │                    │  prod dbt    │             │
│   │  project obj │                    │  project obj │             │
│   └──────────────┘                    └──────┬───────┘             │
│                                              │                     │
│                                    ┌─────────┴─────────┐           │
│                                    │  SNOWFLAKE TASKS   │           │
│                                    │                    │           │
│                                    │  daily_run (cron)  │           │
│                                    │       │            │           │
│                                    │       ▼            │           │
│                                    │  daily_test        │           │
│                                    └────────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

## Repo structure

```
├── .github/workflows/
│   ├── incoming_pr.yml        # CI — test on PRs
│   └── pr_merged.yml          # CD — deploy on merge
├── config_scripts/
│   ├── Setup Snow.sql         # Snowflake env setup (roles, DBs, grants)
│   └── schedules.sql          # Snowflake Tasks definitions
├── demosnowdbt/
│   ├── models/
│   ├── macros/
│   ├── seeds/
│   ├── tests/
│   ├── dbt_project.yml
│   ├── packages.yml
│   └── profiles.yml
└── README.md
```

## Setup

### 1. Snowflake

Run `config_scripts/Setup Snow.sql` as `ACCOUNTADMIN`. It creates the role, warehouse, databases, schemas and grants.

Then grant task execution privileges :

```sql
USE ROLE ACCOUNTADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE DBT_ROLE;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE DBT_ROLE;
```

### 2. GitHub

Create an environment named `prod` in your repo settings (Settings → Environments).

**Secrets :**

| Name | Value |
|---|---|
| `SNOWFLAKE_ACCOUNT` | your account identifier |
| `SNOWFLAKE_USER` | your username |
| `SNOWFLAKE_PASSWORD` | your password |

**Variables :**

| Name | Value |
|---|---|
| `SNOWFLAKE_DATABASE` | `DBT_DEV_DB` |
| `SNOWFLAKE_SCHEMA` | `DBT_SCHEMA` |
| `SNOWFLAKE_ROLE` | `DBT_ROLE` |
| `SNOWFLAKE_WAREHOUSE` | `DBT_WH` |

### 3. Test it

```bash
git checkout -b feature/test-pipeline
# make a change in demosnowdbt/models/
git add . && git commit -m "test ci/cd" && git push origin feature/test-pipeline
```

Open a PR → CI runs → merge → CD deploys to prod. That's it.

## Workflows

**`incoming_pr.yml`** (CI) — triggers on PRs to `main`
- Deploys a tester dbt project object on `DBT_DEV_DB`
- Runs `dbt run` + `dbt test` against dev

**`pr_merged.yml`** (CD) — triggers on merge to `main`
- Deploys the production dbt project object on `DBT_PROD_DB`
- Deploys Snowflake Tasks for daily orchestration

## Orchestration

Two chained Snowflake Tasks defined in `config_scripts/schedules.sql` :

- **`dbt_daily_run`** — runs `dbt run --target prod` every day at midnight UTC
- **`dbt_daily_test`** — runs `dbt test --target prod` right after

## V1 vs V2

| | V1 | V2 |
|---|---|---|
| Dev environment | Local (VS Code + dbt Core) | Snowflake Workspaces |
| Deployment | dbt CLI via GitHub Actions | Snowflake CLI (`snow dbt`) |
| Orchestration | GitHub Actions cron | Snowflake Tasks |
| Local install | Python + dbt Core | Nothing |

## Links

- [V1 repo](https://github.com/eddaouissam/demo_snowflake_dbt)
- [Snowflake docs — dbt Projects](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake)
- [Snowflake docs — Schedule dbt runs](https://docs.snowflake.com/en/user-guide/data-engineering/dbt-projects-on-snowflake-schedule-project-execution)
- [LinkedIn](https://www.linkedin.com/in/m%E2%80%99hamed-issam-ed-daou-045674211/)

⭐ if this helped !