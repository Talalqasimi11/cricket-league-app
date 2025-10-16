import requests

BASE_URL = "http://localhost:5000"
AUTH_ENDPOINT = "/api/auth/login"
ADD_PLAYER_ENDPOINT = "/api/players/add"
MY_TEAM_ENDPOINT = "/api/teams/my-team"
DELETE_PLAYER_ENDPOINT_TEMPLATE = "/api/players/{player_id}/delete"
TIMEOUT = 30
USERNAME = "1"
PASSWORD = "1"

def test_add_new_player_to_team_with_valid_data():
    session = requests.Session()
    try:
        # Login to get JWT token
        login_payload = {
            "phone_number": USERNAME,
            "password": PASSWORD
        }
        login_resp = session.post(f"{BASE_URL}{AUTH_ENDPOINT}", json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
        login_data = login_resp.json()
        token = login_data.get("token")
        assert token, "No token received on login"
        headers = {"Authorization": f"Bearer {token}"}
        
        # Get authenticated user's team to confirm valid session (optional, but verify authentication)
        team_resp = session.get(f"{BASE_URL}{MY_TEAM_ENDPOINT}", headers=headers, timeout=TIMEOUT)
        assert team_resp.status_code == 200, f"Fetching team failed: {team_resp.text}"
        team_data = team_resp.json()
        assert "id" in team_data and "team_name" in team_data, "Invalid team data returned"
        
        # Add a new player with valid data
        player_payload = {
            "player_name": "Test Player TC007",
            "player_role": "batsman"
        }
        add_player_resp = session.post(f"{BASE_URL}{ADD_PLAYER_ENDPOINT}", json=player_payload, headers=headers, timeout=TIMEOUT)
        assert add_player_resp.status_code == 201, f"Add player failed: {add_player_resp.text}"
        add_player_data = add_player_resp.json()
        assert add_player_data.get("message") == "Player added successfully", "Unexpected success message"
        
        # The response schema does not specify returning player id, so we must get it by listing players or assume no delete endpoint provided so cleanup not implemented
        
    finally:
        # No explicit player delete endpoint described in PRD or test instructions
        pass

test_add_new_player_to_team_with_valid_data()