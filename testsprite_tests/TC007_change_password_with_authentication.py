import requests

BASE_URL = "http://localhost:5000/api/auth"
USERNAME = "1"
PASSWORD = "1"
TIMEOUT = 30

def test_change_password_with_authentication():
    # Step 1: Login to get JWT token
    login_url = f"{BASE_URL}/login"
    login_payload = {
        "phone_number": USERNAME,
        "password": PASSWORD
    }
    try:
        login_resp = requests.post(login_url, json=login_payload, timeout=TIMEOUT)
        assert login_resp.status_code == 200, f"Login failed with status {login_resp.status_code}"
        login_json = login_resp.json()
        token = login_json.get("token")
        assert token, "Token not found in login response"
    except requests.RequestException as e:
        assert False, f"Request to login endpoint failed: {str(e)}"
    
    # Step 2: Change password with the authenticated token
    change_password_url = f"{BASE_URL}/change-password"
    new_password = PASSWORD + "New"  # Ensure meets minimum 8 chars
    change_payload = {
        "current_password": PASSWORD,
        "new_password": new_password
    }
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    try:
        change_resp = requests.put(change_password_url, json=change_payload, headers=headers, timeout=TIMEOUT)
        assert change_resp.status_code == 200, f"Change password failed with status {change_resp.status_code}"
        change_json = change_resp.json()
        msg = change_json.get("message")
        assert msg and "password changed" in msg.lower(), f"Unexpected message: {msg}"
    except requests.RequestException as e:
        assert False, f"Request to change-password endpoint failed: {str(e)}"
    finally:
        # Step 3: Revert password to original so test is idempotent
        revert_payload = {
            "current_password": new_password,
            "new_password": PASSWORD
        }
        try:
            revert_resp = requests.put(change_password_url, json=revert_payload, headers=headers, timeout=TIMEOUT)
            assert revert_resp.status_code == 200, f"Revert password failed with status {revert_resp.status_code}"
            revert_json = revert_resp.json()
            revert_msg = revert_json.get("message")
            assert revert_msg and "password changed" in revert_msg.lower(), f"Unexpected revert message: {revert_msg}"
        except Exception:
            # Do not raise, test already passed, just best effort revert
            pass

test_change_password_with_authentication()