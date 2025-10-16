import requests

BASE_URL = "http://localhost:5000/api/auth"
TIMEOUT = 30

def test_login_captain_with_correct_credentials():
    url = f"{BASE_URL}/login"
    payload = {
        "phone_number": "1",
        "password": "1"
    }
    headers = {
        "Content-Type": "application/json"
    }
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"
    try:
        data = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    assert "token" in data and isinstance(data["token"], str) and data["token"], "Access token missing or invalid"
    assert "refresh_token" in data and isinstance(data["refresh_token"], str) and data["refresh_token"], "Refresh token missing or invalid"
    assert "user" in data and isinstance(data["user"], dict), "User details missing or invalid"
    user = data["user"]
    assert "id" in user and isinstance(user["id"], int), "User id missing or invalid"
    assert "phone_number" in user and user["phone_number"] == payload["phone_number"], "User phone number missing or does not match"

test_login_captain_with_correct_credentials()