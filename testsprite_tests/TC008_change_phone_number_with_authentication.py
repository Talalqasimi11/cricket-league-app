import requests

BASE_URL = "http://localhost:5000"
AUTH_URL = f"{BASE_URL}/api/auth"
CHANGE_PHONE_URL = f"{AUTH_URL}/change-phone"
LOGIN_URL = f"{AUTH_URL}/login"

USERNAME = "1"
PASSWORD = "1"

def test_TC008_change_phone_number_with_authentication():
    # Step 1: Login to get JWT token
    login_payload = {
        "phone_number": USERNAME,
        "password": PASSWORD
    }
    try:
        login_response = requests.post(
            LOGIN_URL,
            json=login_payload,
            timeout=30
        )
        assert login_response.status_code == 200, f"Login failed: {login_response.text}"
        login_data = login_response.json()
        token = login_data.get("token")
        assert token and isinstance(token, str), "Token missing or invalid in login response"

        # Step 2: Change phone number using obtained token
        new_phone_number = "+12345678901"  # E.164 format; should be unique and valid

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        change_phone_payload = {
            "new_phone_number": new_phone_number
        }
        change_phone_response = requests.put(
            CHANGE_PHONE_URL,
            headers=headers,
            json=change_phone_payload,
            timeout=30
        )
        assert change_phone_response.status_code == 200, f"Change phone failed: {change_phone_response.text}"

        change_phone_data = change_phone_response.json()
        assert change_phone_data.get("phone_number") == new_phone_number, "Returned phone number does not match updated number"
        assert "message" in change_phone_data and "updated" in change_phone_data["message"].lower(), "Success message missing or incorrect"
        
    except requests.RequestException as e:
        assert False, f"HTTP Request failed: {e}"

test_TC008_change_phone_number_with_authentication()
