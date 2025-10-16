import requests
from requests.auth import HTTPBasicAuth

BASE_URL = "http://localhost:5000/api/auth"
TIMEOUT = 30
USERNAME = "1"
PASSWORD = "1"

def test_logout_user_and_revoke_refresh_token():
    # Login first to get tokens
    login_url = f"{BASE_URL}/login"
    login_payload = {
        "phone_number": USERNAME,
        "password": PASSWORD
    }

    try:
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status code {login_resp.status_code}"
        login_data = login_resp.json()
        assert "token" in login_data and login_data["token"], "Access token missing in login response"
        assert "refresh_token" in login_data and login_data["refresh_token"], "Refresh token missing in login response"

        refresh_token = login_data["refresh_token"]

        # Logout to revoke refresh token
        logout_url = f"{BASE_URL}/logout"
        headers = {
            "Authorization": f"Bearer {login_data['token']}"
        }
        # According to PRD, logout is POST without body
        logout_resp = requests.post(logout_url, headers=headers, timeout=TIMEOUT)
        assert logout_resp.status_code == 200, f"Logout failed with status code {logout_resp.status_code}"
        logout_data = logout_resp.json()
        assert "message" in logout_data, "Logout confirmation message missing"
        assert logout_data["message"].lower() == "logged out", "Logout confirmation message incorrect"

    except (requests.RequestException, AssertionError) as e:
        raise AssertionError(f"Test TC004 failed: {e}")

test_logout_user_and_revoke_refresh_token()