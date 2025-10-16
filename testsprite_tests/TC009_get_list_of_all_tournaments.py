import requests

BASE_URL = "http://localhost:5000/api"
AUTH_CREDENTIALS = ("1", "1")
TIMEOUT = 30

def test_get_list_of_all_tournaments():
    # First, perform basic health check to ensure system status before main test
    try:
        health_resp = requests.get(f"http://localhost:5000/health", timeout=TIMEOUT)
        assert health_resp.status_code == 200
        health_data = health_resp.json()
        assert health_data.get("status") == "ok"
        assert health_data.get("db") in ("up", "down")
    except Exception as e:
        raise AssertionError(f"Health check failed: {e}")

    # Authenticate using phone_number and password to get JWT token
    login_url = f"http://localhost:5000/api/auth/login"
    login_payload = {
        "phone_number": AUTH_CREDENTIALS[0],
        "password": AUTH_CREDENTIALS[1]
    }
    try:
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status {login_resp.status_code}"
        login_data = login_resp.json()
        token = login_data.get("token")
        assert token and isinstance(token, str) and token.strip() != ""
    except Exception as e:
        raise AssertionError(f"Authentication failed: {e}")

    headers = {
        "Authorization": f"Bearer {token}"
    }

    # Call the /tournaments/ GET endpoint to fetch all tournaments
    tournaments_url = f"{BASE_URL}/tournaments/"
    try:
        resp = requests.get(tournaments_url, headers=headers, timeout=TIMEOUT)
    except Exception as e:
        raise AssertionError(f"Request to {tournaments_url} failed: {e}")

    assert resp.status_code == 200, f"Expected 200 OK but got {resp.status_code}"

    try:
        tournaments = resp.json()
    except Exception as e:
        raise AssertionError("Response is not valid JSON")

    assert isinstance(tournaments, list), "Response is not a list"

    # Validate each tournament object for required fields and types
    allowed_statuses = {"not_started", "live", "completed", "abandoned"}
    for tournament in tournaments:
        assert isinstance(tournament, dict), "Tournament item is not an object"
        # id
        assert "id" in tournament, "Tournament missing 'id'"
        assert isinstance(tournament["id"], int), "'id' is not int"
        # tournament_name
        assert "tournament_name" in tournament, "Tournament missing 'tournament_name'"
        assert isinstance(tournament["tournament_name"], str), "'tournament_name' is not string"
        # location
        assert "location" in tournament, "Tournament missing 'location'"
        assert isinstance(tournament["location"], str), "'location' is not string"
        # start_date
        assert "start_date" in tournament, "Tournament missing 'start_date'"
        assert isinstance(tournament["start_date"], str), "'start_date' is not string"
        # status
        assert "status" in tournament, "Tournament missing 'status'"
        assert tournament["status"] in allowed_statuses, "'status' has invalid value"

    print("TC009 passed: Retrieved list of tournaments with correct structure and status 200")

test_get_list_of_all_tournaments()