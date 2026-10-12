CREATE DATABASE IF NOT EXISTS football_lab;
USE football_lab;

DROP TABLE IF EXISTS game;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS season;

CREATE TABLE season (
    season_id INT AUTO_INCREMENT PRIMARY KEY,
    season_name VARCHAR(20) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE team (
    team_id INT AUTO_INCREMENT PRIMARY KEY,
    team_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE game (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    season_id INT NOT NULL,
    home_team_id INT NOT NULL,
    away_team_id INT NOT NULL,
    home_goals INT NOT NULL CHECK (home_goals >= 0),
    away_goals INT NOT NULL CHECK (away_goals >= 0),
    home_possession DECIMAL(5,2) NOT NULL CHECK (home_possession BETWEEN 0 AND 100),
    away_possession DECIMAL(5,2) NOT NULL CHECK (away_possession BETWEEN 0 AND 100),
    home_shots_on_target INT NOT NULL CHECK (home_shots_on_target >= 0),
    away_shots_on_target INT NOT NULL CHECK (away_shots_on_target >= 0),
    home_red_cards INT NOT NULL CHECK (home_red_cards >= 0),
    away_red_cards INT NOT NULL CHECK (away_red_cards >= 0),
    CONSTRAINT fk_season FOREIGN KEY (season_id) REFERENCES season(season_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_home_team FOREIGN KEY (home_team_id) REFERENCES team(team_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_away_team FOREIGN KEY (away_team_id) REFERENCES team(team_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
