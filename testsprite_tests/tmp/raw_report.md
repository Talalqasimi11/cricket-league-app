
# TestSprite AI Testing Report(MCP)

---

## 1️⃣ Document Metadata
- **Project Name:** cricket-league-app
- **Date:** 2025-10-16
- **Prepared by:** TestSprite AI Team

---

## 2️⃣ Requirement Validation Summary

#### Test TC001
- **Test Name:** register new captain with valid data
- **Test Code:** [TC001_register_new_captain_with_valid_data.py](./TC001_register_new_captain_with_valid_data.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 29, in <module>
  File "<string>", line 22, in test_register_new_captain_with_valid_data
AssertionError: Expected status code 201, got 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/fadaa499-6136-42ac-9261-d622f8fe42f4
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC002
- **Test Name:** login captain with correct credentials
- **Test Code:** [TC002_login_captain_with_correct_credentials.py](./TC002_login_captain_with_correct_credentials.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 33, in <module>
  File "<string>", line 20, in test_login_captain_with_correct_credentials
AssertionError: Expected status code 200, got 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/7c1d59a8-8d7c-490c-b234-e21c47baf590
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC003
- **Test Name:** refresh access token using valid refresh token
- **Test Code:** [TC003_refresh_access_token_using_valid_refresh_token.py](./TC003_refresh_access_token_using_valid_refresh_token.py)
- **Test Error:** Traceback (most recent call last):
  File "<string>", line 16, in test_refresh_access_token_using_valid_refresh_token
  File "/var/task/requests/models.py", line 1024, in raise_for_status
    raise HTTPError(http_error_msg, response=self)
requests.exceptions.HTTPError: 500 Server Error: Internal Server Error for url: http://localhost:5000/api/auth/login

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 40, in <module>
  File "<string>", line 18, in test_refresh_access_token_using_valid_refresh_token
AssertionError: Login request failed: 500 Server Error: Internal Server Error for url: http://localhost:5000/api/auth/login

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/06e2dce0-d5cb-4b46-81b4-4226b3e0adbc
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC004
- **Test Name:** logout user and revoke refresh token
- **Test Code:** [TC004_logout_user_and_revoke_refresh_token.py](./TC004_logout_user_and_revoke_refresh_token.py)
- **Test Error:** Traceback (most recent call last):
  File "<string>", line 19, in test_logout_user_and_revoke_refresh_token
AssertionError: Login failed with status code 500

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 41, in <module>
  File "<string>", line 39, in test_logout_user_and_revoke_refresh_token
AssertionError: Test TC004 failed: Login failed with status code 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/3be00b45-0b68-42c3-bacd-ce20921344b3
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC005
- **Test Name:** get all teams public endpoint
- **Test Code:** [TC005_get_all_teams_public_endpoint.py](./TC005_get_all_teams_public_endpoint.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 32, in <module>
  File "<string>", line 13, in test_get_all_teams_public_endpoint
AssertionError: Expected status code 200, got 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/148caa1a-202a-466b-9019-9b9bffff469b
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC006
- **Test Name:** get authenticated users team details
- **Test Code:** [TC006_get_authenticated_users_team_details.py](./TC006_get_authenticated_users_team_details.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 51, in <module>
  File "<string>", line 18, in test_get_authenticated_users_team_details
AssertionError: Login failed: {"error":"Server error","details":"Cannot read properties of undefined (reading 'query')"}

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/16cbe2c6-7e8b-4c0e-906a-9ce7fc61a15a
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC007
- **Test Name:** add new player to team with valid data
- **Test Code:** [TC007_add_new_player_to_team_with_valid_data.py](./TC007_add_new_player_to_team_with_valid_data.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 49, in <module>
  File "<string>", line 21, in test_add_new_player_to_team_with_valid_data
AssertionError: Login failed: {"error":"Server error","details":"Cannot read properties of undefined (reading 'query')"}

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/a6413413-2baa-48a4-9f0b-9bc3677d0b0d
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC008
- **Test Name:** create new tournament with required fields
- **Test Code:** [TC008_create_new_tournament_with_required_fields.py](./TC008_create_new_tournament_with_required_fields.py)
- **Test Error:** Traceback (most recent call last):
  File "<string>", line 24, in test_create_new_tournament_with_required_fields
AssertionError: Login failed with status 500

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 62, in <module>
  File "<string>", line 29, in test_create_new_tournament_with_required_fields
AssertionError: Authentication failed: Login failed with status 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/fdc46ff9-fb4b-442a-a160-ae005818c96a
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC009
- **Test Name:** get list of all tournaments
- **Test Code:** [TC009_get_list_of_all_tournaments.py](./TC009_get_list_of_all_tournaments.py)
- **Test Error:** Traceback (most recent call last):
  File "<string>", line 26, in test_get_list_of_all_tournaments
AssertionError: Login failed with status 500

During handling of the above exception, another exception occurred:

Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 75, in <module>
  File "<string>", line 31, in test_get_list_of_all_tournaments
AssertionError: Authentication failed: Login failed with status 500

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/8d75cfe4-52ef-4c2b-9216-a3fcb82ed20c
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---

#### Test TC010
- **Test Name:** start new innings for a match
- **Test Code:** [TC010_start_new_innings_for_a_match.py](./TC010_start_new_innings_for_a_match.py)
- **Test Error:** Traceback (most recent call last):
  File "/var/task/handler.py", line 258, in run_with_retry
    exec(code, exec_env)
  File "<string>", line 60, in <module>
  File "<string>", line 18, in test_start_new_innings_for_match
AssertionError: Login failed: Too many requests, please try again later.

- **Test Visualization and Result:** https://www.testsprite.com/dashboard/mcp/tests/3b5100fd-536b-4d2f-a673-dae4ad815562/9506bbd5-f22f-4722-8376-9bce1d86eab2
- **Status:** ❌ Failed
- **Analysis / Findings:** {{TODO:AI_ANALYSIS}}.
---


## 3️⃣ Coverage & Matching Metrics

- **0.00** of tests passed

| Requirement        | Total Tests | ✅ Passed | ❌ Failed  |
|--------------------|-------------|-----------|------------|
| ...                | ...         | ...       | ...        |
---


## 4️⃣ Key Gaps / Risks
{AI_GNERATED_KET_GAPS_AND_RISKS}
---