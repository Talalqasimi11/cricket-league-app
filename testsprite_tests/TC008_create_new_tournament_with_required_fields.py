import requests
from requests.auth import HTTPBasicAuth

BASE_URL = "http://localhost:5000"
REGISTER_URL = f"{BASE_URL}/api/auth/register"
LOGIN_URL = f"{BASE_URL}/api/auth/login"
TOURNAMENT_CREATE_URL = f"{BASE_URL}/api/tournaments/create"
TOURNAMENT_DELETE_URL = f"{BASE_URL}/api/tournaments/"  # Assuming DELETE /api/tournaments/{id} exists for cleanup

USERNAME = "1"
PASSWORD = "1"
AUTH = HTTPBasicAuth(USERNAME, PASSWORD)
TIMEOUT = 30


def test_create_new_tournament_with_required_fields():
    # Step 1: Login to get JWT token
    login_payload = {
        "phone_number": USERNAME,
        "password": PASSWORD
    }
    try:
        login_resp = requests.post(LOGIN_URL, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status {login_resp.status_code}"
        login_data = login_resp.json()
        token = login_data.get("token")
        assert token, "Token missing in login response"
    except Exception as e:
        raise AssertionError(f"Authentication failed: {e}")

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    # Create a new tournament with required fields
    tournament_payload = {
        "tournament_name": "Test Tournament TC008",
        "location": "Test Location",
        "start_date": "2025-12-01"
    }

    tournament_id = None
    try:
        create_resp = requests.post(TOURNAMENT_CREATE_URL, json=tournament_payload, headers=headers, timeout=TIMEOUT)
        assert create_resp.status_code == 201, f"Tournament creation failed with status {create_resp.status_code}"
        create_data = create_resp.json()
        assert create_data.get("message") == "Tournament created successfully", "Unexpected success message"
        tournament_id = create_data.get("id")
        assert isinstance(tournament_id, int) and tournament_id > 0, "Invalid tournament id returned"
    finally:
        # Cleanup: delete the created tournament if created
        if tournament_id is not None:
            try:
                delete_resp = requests.delete(f"{TOURNAMENT_DELETE_URL}{tournament_id}", headers=headers, timeout=TIMEOUT)
                if delete_resp.status_code not in (200, 204):
                    print(f"Warning: Failed to delete tournament id {tournament_id} during cleanup.")
            except Exception as cleanup_exc:
                print(f"Warning: Exception during cleanup deleting tournament id {tournament_id}: {cleanup_exc}")


test_create_new_tournament_with_required_fields()