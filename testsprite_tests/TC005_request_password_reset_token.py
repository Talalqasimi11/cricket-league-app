import requests
from requests.auth import HTTPBasicAuth

BASE_URL = "http://localhost:5000/api/auth"
USERNAME = "1"
PASSWORD = "1"
TIMEOUT = 30

def test_request_password_reset_token():
    try:
        # Login to verify user exists and get phone number
        login_url = f"{BASE_URL}/login"
        login_payload = {
            "phone_number": USERNAME,
            "password": PASSWORD
        }
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status {login_resp.status_code}"
        login_data = login_resp.json()
        phone_number = login_data.get("user", {}).get("phone_number")
        assert phone_number, "Phone number is missing in login response user data"

        # Request password reset token
        forgot_password_url = f"{BASE_URL}/forgot-password"
        forgot_payload = {"phone_number": phone_number}
        forgot_resp = requests.post(forgot_password_url, json=forgot_payload, timeout=TIMEOUT)
        assert forgot_resp.status_code == 200, f"Forgot password request failed with status {forgot_resp.status_code}"
        forgot_data = forgot_resp.json()
        assert "message" in forgot_data, "No message field in forgot password response"
        # The response example says message is like "If the account exists, a reset was initiated"
        assert isinstance(forgot_data["message"], str) and len(forgot_data["message"]) > 0
        # Token is returned in response (for development only)
        assert "token" in forgot_data and isinstance(forgot_data["token"], str) and len(forgot_data["token"]) > 0

    except (requests.RequestException, AssertionError) as e:
        raise AssertionError(f"Test failed: {e}")

test_request_password_reset_token()