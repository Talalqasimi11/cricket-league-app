import requests

BASE_URL = "http://localhost:5000"
AUTH_URL = f"{BASE_URL}/api/auth/login"
ADD_PLAYER_URL = f"{BASE_URL}/api/players/add"

USERNAME = "1"
PASSWORD = "1"
TIMEOUT = 30


def test_add_player_to_team_with_authentication():
    # Login to get JWT token
    try:
        login_resp = requests.post(
            AUTH_URL,
            json={"phone_number": USERNAME, "password": PASSWORD},
            timeout=TIMEOUT,
        )
        assert login_resp.status_code == 200, f"Login failed: {login_resp.text}"
        login_data = login_resp.json()
        token = login_data.get("token")
        assert token, "No token received in login response"

        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

        # Add a new player to the authenticated user's team
        player_payload = {
            "player_name": "Test Player",
            "player_role": "batsman"
        }
        response = requests.post(ADD_PLAYER_URL, json=player_payload, headers=headers, timeout=TIMEOUT)
        assert response.status_code == 201, f"Add player failed: {response.text}"
        resp_json = response.json()
        assert "message" in resp_json, "Response missing 'message' key"
        assert "player added successfully" in resp_json["message"].lower(), f"Unexpected success message: {resp_json['message']}"
    except requests.RequestException as e:
        assert False, f"Request exception occurred: {e}"


test_add_player_to_team_with_authentication()