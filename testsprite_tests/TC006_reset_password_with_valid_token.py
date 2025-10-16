import requests
from requests.auth import HTTPBasicAuth

BASE_URL = "http://localhost:5000/api/auth"
TIMEOUT = 30

def test_reset_password_with_valid_token():
    # Test data for registration and passwords
    phone_number = "+19999999999"
    original_password = "Original1!"
    new_password = "Newpass1!"
    team_name = "Test Team TC006"
    team_location = "Test Location"

    # Register a new user (captain) to ensure a valid user exists
    register_payload = {
        "phone_number": phone_number,
        "password": original_password,
        "team_name": team_name,
        "team_location": team_location
    }
    try:
        reg_resp = requests.post(
            f"{BASE_URL}/register",
            json=register_payload,
            timeout=TIMEOUT
        )
        # If user already exists or created successfully proceed, else fail
        assert reg_resp.status_code in (201, 409), f"Unexpected register status: {reg_resp.status_code}"
    except Exception as e:
        raise AssertionError(f"Registration step failed: {str(e)}")

    # Request password reset token using /forgot-password
    forgot_payload = {"phone_number": phone_number}
    try:
        forgot_resp = requests.post(
            f"{BASE_URL}/forgot-password",
            json=forgot_payload,
            timeout=TIMEOUT
        )
        assert forgot_resp.status_code == 200, f"Forgot-password responded with {forgot_resp.status_code}"
        forgot_json = forgot_resp.json()
        reset_token = forgot_json.get("token")
        assert reset_token and isinstance(reset_token, str), "Reset token not found or invalid in forgot-password response"
    except Exception as e:
        raise AssertionError(f"Forgot-password step failed: {str(e)}")

    # Use reset token to reset password via /reset-password
    reset_payload = {
        "phone_number": phone_number,
        "token": reset_token,
        "new_password": new_password
    }
    try:
        reset_resp = requests.post(
            f"{BASE_URL}/reset-password",
            json=reset_payload,
            timeout=TIMEOUT
        )
        assert reset_resp.status_code == 200, f"Reset-password responded with {reset_resp.status_code}"
        reset_json = reset_resp.json()
        assert reset_json.get("message") == "Password reset successful", f"Unexpected message: {reset_json.get('message')}"
    except Exception as e:
        raise AssertionError(f"Reset-password step failed: {str(e)}")

    # Verify login with new password to confirm password reset
    login_payload = {
        "phone_number": phone_number,
        "password": new_password
    }
    try:
        login_resp = requests.post(
            f"{BASE_URL}/login",
            json=login_payload,
            timeout=TIMEOUT
        )
        assert login_resp.status_code == 200, f"Login after reset responded with {login_resp.status_code}"
        login_json = login_resp.json()
        assert "token" in login_json and "refresh_token" in login_json, "Tokens not found in login response"
        assert login_json.get("message") == "Login successful"
        assert login_json.get("user") and login_json["user"].get("phone_number") == phone_number
    except Exception as e:
        raise AssertionError(f"Login after reset step failed: {str(e)}")

test_reset_password_with_valid_token()