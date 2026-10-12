USE football_lab;

CREATE OR REPLACE VIEW team_result AS
SELECT
    season_id,
    home_team_id AS team_id,
    home_goals AS goals_for,
    away_goals AS goals_against,
    home_possession AS possession,
    home_shots_on_target AS shots_on_target,
    CASE WHEN home_goals > away_goals THEN 3 WHEN home_goals = away_goals THEN 1 ELSE 0 END AS points
FROM game
UNION ALL
SELECT
    season_id,
    away_team_id,
    away_goals,
    home_goals,
    away_possession,
    away_shots_on_target,
    CASE WHEN away_goals > home_goals THEN 3 WHEN away_goals = home_goals THEN 1 ELSE 0 END
FROM game;

SELECT game.game_id, game.home_goals, game.home_possession 
FROM game 
WHERE game.home_goals > 2 AND game.home_possession > 60.0
ORDER BY game.home_goals DESC, game.home_possession DESC, game.game_id
LIMIT 10;

SELECT game.game_id, season.season_name, game.home_goals, game.away_goals,
       (game.home_goals + game.away_goals) AS total_goals
FROM game
JOIN season ON game.season_id = season.season_id
WHERE season.season_name = '18/19'
ORDER BY total_goals DESC, game.game_id
LIMIT 5;

SELECT game.game_id, season.season_name,
       home_team.team_name AS home_team_name,
       away_team.team_name AS away_team_name,
       game.home_goals, game.away_goals,
       (game.home_goals + game.away_goals) AS total_goals
FROM game
JOIN season ON game.season_id = season.season_id
JOIN team AS home_team ON game.home_team_id = home_team.team_id
JOIN team AS away_team ON game.away_team_id = away_team.team_id
ORDER BY total_goals DESC, game.game_id
LIMIT 5;

SELECT season.season_name, COUNT(game.game_id) AS total_matches
FROM season
LEFT JOIN game ON season.season_id = game.season_id
GROUP BY season.season_id, season.season_name
ORDER BY season.season_name;

SELECT team.team_name,
       COUNT(*) AS total_played,
       SUM(team_result.points) AS total_points,
       ROUND(AVG(team_result.points), 2) AS points_per_game
FROM team_result
JOIN team ON team.team_id = team_result.team_id
GROUP BY team.team_id, team.team_name
ORDER BY total_points DESC, total_played DESC
LIMIT 10;

SELECT team.team_name,
       COUNT(*) AS total_wins,
       ROUND(AVG(team_result.possession), 1) AS avg_possession_in_wins
FROM team_result
JOIN team ON team.team_id = team_result.team_id
WHERE team_result.points = 3
GROUP BY team.team_id, team.team_name
ORDER BY avg_possession_in_wins DESC
LIMIT 10;

SELECT COUNT(*) AS total_wins,
       ROUND(100 * SUM(possession < 50) / COUNT(*), 1) AS pct_wins_below_50,
       ROUND(100 * SUM(possession < 45) / COUNT(*), 1) AS pct_wins_below_45
FROM team_result
WHERE points = 3;

SELECT season.season_name,
       team.team_name,
       SUM(team_result.shots_on_target) AS total_shots_on_target,
       SUM(team_result.goals_for) AS total_goals,
       SUM(team_result.shots_on_target) - SUM(team_result.goals_for) AS shots_goals_diff,
       ROUND(100 * SUM(team_result.goals_for) / SUM(team_result.shots_on_target), 1) AS conversion_pct
FROM team_result
JOIN season ON season.season_id = team_result.season_id
JOIN team ON team.team_id = team_result.team_id
GROUP BY season.season_id, season.season_name, team.team_id, team.team_name
ORDER BY shots_goals_diff DESC
LIMIT 5;

SELECT season.season_name,
       COUNT(*) AS total_matches,
       SUM(game.home_red_cards + game.away_red_cards) AS total_red_cards,
       SUM(game.home_goals + game.away_goals) AS total_goals,
       ROUND(SUM(game.home_red_cards + game.away_red_cards) / COUNT(*), 3) AS red_cards_per_match,
       ROUND(SUM(game.home_goals + game.away_goals) / COUNT(*), 2) AS goals_per_match
FROM game
JOIN season ON game.season_id = season.season_id
GROUP BY season.season_id, season.season_name
ORDER BY total_red_cards DESC;
