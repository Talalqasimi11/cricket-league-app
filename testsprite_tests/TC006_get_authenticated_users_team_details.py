import requests

BASE_URL = "http://localhost:5000"
AUTH_URL = f"{BASE_URL}/api/auth/login"
MY_TEAM_URL = f"{BASE_URL}/api/teams/my-team"

USERNAME = "1"
PASSWORD = "1"

def test_get_authenticated_users_team_details():
    try:
        # Step 1: Authenticate to get JWT token
        login_payload = {
            "phone_number": USERNAME,
            "password": PASSWORD
        }
        login_resp = requests.post(AUTH_URL, json=login_payload, timeout=30)
        assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
        login_data = login_resp.json()

        token = login_data.get("token")
        assert token, "JWT token not found in login response"

        headers = {
            "Authorization": f"Bearer {token}"
        }

        # Step 2: Get authenticated user's team details
        team_resp = requests.get(MY_TEAM_URL, headers=headers, timeout=30)
        assert team_resp.status_code == 200, f"Failed to get team details: {team_resp.text}"
        team_data = team_resp.json()

        # Validate keys and types in the response
        assert isinstance(team_data, dict), "Team response is not a dictionary"

        expected_keys = {"id", "team_name", "team_location", "owner_id"}
        assert expected_keys.issubset(team_data.keys()), (
            f"Response missing keys: {expected_keys - set(team_data.keys())}"
        )

        assert isinstance(team_data["id"], int), "Team 'id' is not an integer"
        assert isinstance(team_data["team_name"], str), "Team 'team_name' is not a string"
        assert isinstance(team_data["team_location"], str), "Team 'team_location' is not a string"
        assert isinstance(team_data["owner_id"], int), "Team 'owner_id' is not an integer"

    except AssertionError as ae:
        raise
    except requests.RequestException as re:
        raise RuntimeError(f"Request failed: {re}")

test_get_authenticated_users_team_details()