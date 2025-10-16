import requests

BASE_URL = "http://localhost:5000/api/auth"
AUTH_USERNAME = "1"
AUTH_PASSWORD = "1"
TIMEOUT = 30

def test_refresh_access_token_with_valid_refresh_token():
    # Step 1: Login to get a valid refresh token
    login_payload = {
        "phone_number": AUTH_USERNAME,
        "password": AUTH_PASSWORD
    }
    login_headers = {
        "Content-Type": "application/json"
    }
    try:
        login_resp = requests.post(f"{BASE_URL}/login", json=login_payload, headers=login_headers, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status {login_resp.status_code}, response: {login_resp.text}"
        login_data = login_resp.json()
        assert "refresh_token" in login_data, "No refresh_token in login response"
        refresh_token = login_data["refresh_token"]

        # Step 2: Use the refresh token to get a new access token
        refresh_payload = {
            "refresh_token": refresh_token
        }
        refresh_resp = requests.post(f"{BASE_URL}/refresh", json=refresh_payload, headers=login_headers, timeout=TIMEOUT)
        assert refresh_resp.status_code == 200, f"Refresh token request failed with status {refresh_resp.status_code}, response: {refresh_resp.text}"
        refresh_data = refresh_resp.json()
        assert "token" in refresh_data, "No new access token in refresh response"
        new_access_token = refresh_data["token"]
        assert isinstance(new_access_token, str) and new_access_token.strip() != "", "New access token is invalid"
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

test_refresh_access_token_with_valid_refresh_token()