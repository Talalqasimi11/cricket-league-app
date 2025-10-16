import requests

BASE_URL = "http://localhost:5000/api/auth"
TIMEOUT = 30

def test_register_new_captain_with_valid_data():
    url = f"{BASE_URL}/register"
    payload = {
        "phone_number": "+12345678901",
        "password": "StrongPass1",
        "team_name": "The Warriors",
        "team_location": "New York",
        "captain_name": "John Doe",
        "owner_name": "Jane Doe",
        "team_logo_url": "http://example.com/logo.png"
    }
    headers = {
        "Content-Type": "application/json"
    }
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=TIMEOUT)
        assert response.status_code == 201, f"Expected status code 201, got {response.status_code}"
        json_response = response.json()
        assert "message" in json_response, "Response JSON does not contain 'message'"
        assert json_response["message"].lower().find("success") != -1, f"Unexpected success message: {json_response['message']}"
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"

test_register_new_captain_with_valid_data()