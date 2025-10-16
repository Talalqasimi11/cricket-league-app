import requests

BASE_URL = "http://localhost:5000/api"
TIMEOUT = 30

def test_get_all_teams_public_endpoint():
    url = f"{BASE_URL}/teams/all"
    try:
        response = requests.get(url, timeout=TIMEOUT)
        response.raise_for_status()
    except requests.RequestException as e:
        assert False, f"Request failed: {e}"
    assert response.status_code == 200, f"Expected status 200, got {response.status_code}"
    try:
        teams = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"
    assert isinstance(teams, list), "Response is not a list"
    for team in teams:
        assert isinstance(team, dict), "Each team entry should be a dictionary"
        required_fields = ["id", "team_name", "team_location", "matches_played", "matches_won", "trophies"]
        for field in required_fields:
            assert field in team, f"Field '{field}' missing in team data"
        assert isinstance(team["id"], int), "Field 'id' should be int"
        assert isinstance(team["team_name"], str), "Field 'team_name' should be str"
        assert isinstance(team["team_location"], str), "Field 'team_location' should be str"
        assert isinstance(team["matches_played"], int), "Field 'matches_played' should be int"
        assert isinstance(team["matches_won"], int), "Field 'matches_won' should be int"
        assert isinstance(team["trophies"], int), "Field 'trophies' should be int"

test_get_all_teams_public_endpoint()
