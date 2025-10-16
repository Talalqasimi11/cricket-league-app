import requests

BASE_URL = "http://localhost:5000/api"
TIMEOUT = 30

def test_get_all_teams_public_endpoint():
    url = f"{BASE_URL}/teams/all"
    try:
        response = requests.get(url, timeout=TIMEOUT)
    except requests.RequestException as e:
        assert False, f"Request to {url} failed: {e}"

    assert response.status_code == 200, f"Expected status code 200, got {response.status_code}"

    try:
        teams = response.json()
    except ValueError:
        assert False, "Response is not valid JSON"

    assert isinstance(teams, list), "Response JSON is not a list"

    # Validate each team object structure
    for team in teams:
        assert isinstance(team, dict), "Team item is not a JSON object"
        assert "id" in team and isinstance(team["id"], int), "Team id missing or not int"
        assert "team_name" in team and isinstance(team["team_name"], str), "Team name missing or not str"
        assert "team_location" in team and isinstance(team["team_location"], str), "Team location missing or not str"
        assert "matches_played" in team and isinstance(team["matches_played"], int), "Matches played missing or not int"
        assert "matches_won" in team and isinstance(team["matches_won"], int), "Matches won missing or not int"
        assert "trophies" in team and isinstance(team["trophies"], int), "Trophies missing or not int"

test_get_all_teams_public_endpoint()