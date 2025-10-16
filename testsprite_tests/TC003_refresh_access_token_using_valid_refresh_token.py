import requests

BASE_URL = "http://localhost:5000/api/auth"
USERNAME = "+12345678901"
PASSWORD = "password123"
TIMEOUT = 30

def test_refresh_access_token_using_valid_refresh_token():
    login_url = f"{BASE_URL}/login"
    refresh_url = f"{BASE_URL}/refresh"

    # Step 1: Login to get refresh token
    login_payload = {"phone_number": USERNAME, "password": PASSWORD}
    try:
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        login_resp.raise_for_status()
    except requests.RequestException as e:
        assert False, f"Login request failed: {e}"

    login_data = login_resp.json()
    assert login_resp.status_code == 200, f"Expected 200 for login, got {login_resp.status_code}"
    assert "refresh_token" in login_data, "refresh_token not found in login response"
    refresh_token = login_data["refresh_token"]
    assert isinstance(refresh_token, str) and len(refresh_token) > 0, "Invalid refresh_token value"

    # Step 2: Use refresh token to get new access token
    refresh_payload = {"refresh_token": refresh_token}
    try:
        refresh_resp = requests.post(refresh_url, json=refresh_payload, timeout=TIMEOUT)
        refresh_resp.raise_for_status()
    except requests.RequestException as e:
        assert False, f"Refresh token request failed: {e}"

    refresh_data = refresh_resp.json()
    assert refresh_resp.status_code == 200, f"Expected 200 for refresh, got {refresh_resp.status_code}"
    assert "token" in refresh_data, "New access token not found in refresh response"
    new_access_token = refresh_data["token"]
    assert isinstance(new_access_token, str) and len(new_access_token) > 0, "Invalid new access token value"

test_refresh_access_token_using_valid_refresh_token()