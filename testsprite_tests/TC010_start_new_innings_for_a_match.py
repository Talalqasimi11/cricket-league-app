import requests

BASE_URL = "http://localhost:5000"
AUTH_URL = f"{BASE_URL}/api/auth/login"
START_INNINGS_URL = f"{BASE_URL}/api/live/start-innings"
TEAMS_ALL_URL = f"{BASE_URL}/api/teams/all"
TOURNAMENTS_URL = f"{BASE_URL}/api/tournaments/"

TIMEOUT = 30

def test_start_new_innings_for_match():
    # Step 1: Login to get JWT token
    login_payload = {
        "phone_number": "1",
        "password": "1"
    }
    login_response = requests.post(AUTH_URL, json=login_payload, timeout=TIMEOUT)
    assert login_response.status_code == 200, f"Login failed: {login_response.text}"
    login_data = login_response.json()
    token = login_data.get("token")
    assert token and isinstance(token, str), "JWT token not found in login response"

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Fetch all teams to get batting_team_id and bowling_team_id
    teams_response = requests.get(TEAMS_ALL_URL, timeout=TIMEOUT)
    assert teams_response.status_code == 200, f"Failed to get teams: {teams_response.text}"
    teams = teams_response.json()
    assert isinstance(teams, list) and len(teams) >= 2, "Need at least two teams to run this test"
    batting_team_id = teams[0]["id"]
    bowling_team_id = teams[1]["id"]

    # To get a match_id, try to get tournaments and assume first tournament id
    tournaments_response = requests.get(TOURNAMENTS_URL, timeout=TIMEOUT)
    assert tournaments_response.status_code == 200, f"Failed to get tournaments: {tournaments_response.text}"
    tournaments = tournaments_response.json()
    assert isinstance(tournaments, list) and len(tournaments) >= 1, "At least one tournament required"
    match_id = tournaments[0]["id"]

    # Prepare payload for starting innings
    innings_payload = {
        "match_id": match_id,
        "batting_team_id": batting_team_id,
        "bowling_team_id": bowling_team_id,
        "overs": 5
    }

    # POST to start innings
    start_innings_response = requests.post(START_INNINGS_URL, headers=headers, json=innings_payload, timeout=TIMEOUT)
    assert start_innings_response.status_code == 201, f"Failed to start innings: {start_innings_response.text}"
    response_data = start_innings_response.json()
    assert response_data.get("message") == "Innings started successfully", "Success message mismatch"
    innings_id = response_data.get("innings_id")
    assert innings_id and isinstance(innings_id, int), "Innings ID missing or invalid"


test_start_new_innings_for_match()