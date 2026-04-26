-- ============================================================
-- Basketball Management System
-- Team: Marco Cerron, Christian Jones, Ryan Markowitz, Rebeca Reyes
-- Target: MySQL 8.0+  (MySQL Workbench)
-- ============================================================

DROP DATABASE IF EXISTS basketball_mgmt;
CREATE DATABASE basketball_mgmt
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE basketball_mgmt;

-- Stadium table
CREATE TABLE Stadium (
  stadium_id    INT            NOT NULL AUTO_INCREMENT,
  naming_rights VARCHAR(100)   NOT NULL,
  city          VARCHAR(100)   NOT NULL,
  state         CHAR(2)        NOT NULL,
  max_capacity  INT            NOT NULL CHECK (max_capacity > 0),
  PRIMARY KEY (stadium_id)
);

-- Team table
CREATE TABLE Team (
  team_id     INT          NOT NULL AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL UNIQUE,
  wins        INT          NOT NULL DEFAULT 0 CHECK (wins >= 0),
  losses      INT          NOT NULL DEFAULT 0 CHECK (losses >= 0),
  stadium_id  INT          NOT NULL,
  PRIMARY KEY (team_id),
  CONSTRAINT fk_team_stadium
    FOREIGN KEY (stadium_id) REFERENCES Stadium (stadium_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Player table
CREATE TABLE Player (
  player_id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  position ENUM(
	'Point Guard',
	'Shooting Guard',
    'Small Forward',
    'Power Forward',
    'Center'
    ) NOT NULL,
  salary                  DECIMAL(12,2)  NOT NULL CHECK (salary >= 0),
  contract_years_remaining INT           NOT NULL CHECK (contract_years_remaining >= 0),
  age                     INT            NOT NULL CHECK (age BETWEEN 18 AND 50),
  height_inches           DECIMAL(5,1)   NOT NULL CHECK (height_inches > 0),
  weight_lbs              DECIMAL(6,1)   NOT NULL CHECK (weight_lbs > 0),
  team_id                 INT            NOT NULL,
  PRIMARY KEY (player_id),
  CONSTRAINT fk_player_team
    FOREIGN KEY (team_id) REFERENCES Team (team_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Coach table
CREATE TABLE Coach (
  coach_id                INT            NOT NULL AUTO_INCREMENT,
  name                    VARCHAR(100)   NOT NULL,
  title                   ENUM('Head Coach', 'Assistant Coach') NOT NULL,
  age                     INT            NOT NULL CHECK (age BETWEEN 18 AND 80),
  salary                  DECIMAL(12,2)  NOT NULL CHECK (salary >= 0),
  contract_years_remaining INT           NOT NULL CHECK (contract_years_remaining >= 0),
  team_id                 INT            NOT NULL,
  PRIMARY KEY (coach_id),
  CONSTRAINT fk_coach_team
    FOREIGN KEY (team_id) REFERENCES Team (team_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Game table
CREATE TABLE Game (
  game_id       INT            NOT NULL AUTO_INCREMENT,
  game_datetime DATETIME       NOT NULL,
  ticket_price  DECIMAL(8,2)   NOT NULL CHECK (ticket_price >= 0),
  home_team_id  INT            NOT NULL,
  away_team_id  INT            NOT NULL,
  stadium_id    INT            NOT NULL,
  home_score    INT            NULL CHECK (home_score >= 0),  -- NULL = not yet played
  away_score    INT            NULL CHECK (away_score >= 0),
  PRIMARY KEY (game_id),
  CONSTRAINT fk_game_home_team
    FOREIGN KEY (home_team_id) REFERENCES Team (team_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_game_away_team
    FOREIGN KEY (away_team_id) REFERENCES Team (team_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_game_stadium
    FOREIGN KEY (stadium_id) REFERENCES Stadium (stadium_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Player_Stats table  (one row per player per game)
CREATE TABLE Player_Stats (
  stat_id                 INT  NOT NULL AUTO_INCREMENT,
  player_id               INT  NOT NULL,
  game_id                 INT  NOT NULL,
  minutes_played          INT  NOT NULL DEFAULT 0 CHECK (minutes_played >= 0),
  points                  INT  NOT NULL DEFAULT 0 CHECK (points >= 0),
  rebounds                INT  NOT NULL DEFAULT 0 CHECK (rebounds >= 0),
  assists                 INT  NOT NULL DEFAULT 0 CHECK (assists >= 0),
  steals                  INT  NOT NULL DEFAULT 0 CHECK (steals >= 0),
  blocks                  INT  NOT NULL DEFAULT 0 CHECK (blocks >= 0),
  turnovers               INT  NOT NULL DEFAULT 0 CHECK (turnovers >= 0),
  field_goals_made        INT  NOT NULL DEFAULT 0 CHECK (field_goals_made >= 0),
  field_goals_attempted   INT  NOT NULL DEFAULT 0 CHECK (field_goals_attempted >= 0),
  free_throws_made        INT  NOT NULL DEFAULT 0 CHECK (free_throws_made >= 0),
  free_throws_attempted   INT  NOT NULL DEFAULT 0 CHECK (free_throws_attempted >= 0),
  PRIMARY KEY (stat_id),
  UNIQUE KEY uq_player_game (player_id, game_id),       -- one line per player per game
  CONSTRAINT fk_stats_player
    FOREIGN KEY (player_id) REFERENCES Player (player_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_stats_game
    FOREIGN KEY (game_id) REFERENCES Game (game_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT chk_fg_logic
    CHECK (field_goals_made <= field_goals_attempted),
  CONSTRAINT chk_ft_logic
    CHECK (free_throws_made <= free_throws_attempted)
);

-- Indexing for common query patterns
CREATE INDEX idx_player_team     ON Player (team_id);
CREATE INDEX idx_player_position ON Player (position);
CREATE INDEX idx_player_salary   ON Player (salary);
CREATE INDEX idx_coach_team      ON Coach (team_id);
CREATE INDEX idx_game_datetime   ON Game (game_datetime);
CREATE INDEX idx_game_home       ON Game (home_team_id);
CREATE INDEX idx_game_away       ON Game (away_team_id);
CREATE INDEX idx_game_stadium    ON Game (stadium_id);
CREATE INDEX idx_stats_player    ON Player_Stats (player_id);
CREATE INDEX idx_stats_game      ON Player_Stats (game_id);

-- Show Tables created
DESCRIBE stadium;
DESCRIBE Team;
DESCRIBE Player;
DESCRIBE Coach;
DESCRIBE Game;
DESCRIBE Player_Stats;

-- Views
-- Season averages per player view
CREATE OR REPLACE VIEW vw_player_season_avg AS
SELECT
  p.player_id,
  p.name                                                        AS player_name,
  p.position,
  t.name                                                        AS team_name,
  COUNT(ps.game_id)                                             AS games_played,
  ROUND(AVG(ps.points),          1)                             AS ppg,
  ROUND(AVG(ps.rebounds),        1)                             AS rpg,
  ROUND(AVG(ps.assists),         1)                             AS apg,
  ROUND(AVG(ps.steals),          1)                             AS spg,
  ROUND(AVG(ps.blocks),          1)                             AS bpg,
  ROUND(AVG(ps.turnovers),       1)                             AS topg,
  ROUND(AVG(ps.minutes_played),  1)                             AS mpg,
  ROUND(
    SUM(ps.field_goals_made) / NULLIF(SUM(ps.field_goals_attempted), 0) * 100,
    1
  )                                                             AS fg_pct,
  ROUND(
    SUM(ps.free_throws_made) / NULLIF(SUM(ps.free_throws_attempted), 0) * 100,
    1
  )                                                             AS ft_pct
FROM Player p
JOIN Team t          ON t.team_id   = p.team_id
LEFT JOIN Player_Stats ps ON ps.player_id = p.player_id
GROUP BY p.player_id, p.name, p.position, t.name;

-- League standings view
CREATE OR REPLACE VIEW vw_standings AS
SELECT
  t.team_id,
  t.name                                  AS team_name,
  s.naming_rights                         AS arena,
  t.wins,
  t.losses,
  t.wins + t.losses                       AS games_played,
  ROUND(t.wins / NULLIF(t.wins + t.losses, 0), 3) AS win_pct
FROM Team t
JOIN Stadium s ON s.stadium_id = t.stadium_id
ORDER BY win_pct DESC;

-- Game schedule (shows outcome when played, TBD when not) view
CREATE OR REPLACE VIEW vw_schedule AS
SELECT
  g.game_id,
  g.game_datetime,
  ht.name                                 AS home_team,
  at.name                                 AS away_team,
  s.naming_rights                         AS venue,
  s.city,
  g.ticket_price,
  CASE
    WHEN g.home_score IS NULL THEN 'Scheduled'
    WHEN g.home_score > g.away_score THEN CONCAT(ht.name, ' win')
    WHEN g.away_score > g.home_score THEN CONCAT(at.name, ' win')
    ELSE 'Tie'
  END                                     AS result,
  g.home_score,
  g.away_score
FROM Game g
JOIN Team    ht ON ht.team_id   = g.home_team_id
JOIN Team    at ON at.team_id   = g.away_team_id
JOIN Stadium s  ON s.stadium_id = g.stadium_id;

-- Procedures
DELIMITER $$

-- Record a game outcome and update team win/loss records
-- UPDATE FUNCTIONALITY
CREATE PROCEDURE sp_record_game_result (
  IN p_game_id    INT,
  IN p_home_score INT,
  IN p_away_score INT
)
BEGIN
  DECLARE v_home_team INT;
  DECLARE v_away_team INT;

  SELECT home_team_id, away_team_id
  INTO   v_home_team, v_away_team
  FROM   Game
  WHERE  game_id = p_game_id;

  UPDATE Game
  SET    home_score = p_home_score,
         away_score = p_away_score
  WHERE  game_id   = p_game_id;

  IF p_home_score > p_away_score THEN
    UPDATE Team SET wins   = wins   + 1 WHERE team_id = v_home_team;
    UPDATE Team SET losses = losses + 1 WHERE team_id = v_away_team;
  ELSEIF p_away_score > p_home_score THEN
    UPDATE Team SET wins   = wins   + 1 WHERE team_id = v_away_team;
    UPDATE Team SET losses = losses + 1 WHERE team_id = v_home_team;
  END IF;
END$$

-- Add / update a player's stat line for a specific game
-- 
CREATE PROCEDURE sp_upsert_player_stats (
  IN p_player_id             INT,
  IN p_game_id               INT,
  IN p_minutes_played        INT,
  IN p_points                INT,
  IN p_rebounds              INT,
  IN p_assists               INT,
  IN p_steals                INT,
  IN p_blocks                INT,
  IN p_turnovers             INT,
  IN p_field_goals_made      INT,
  IN p_field_goals_attempted INT,
  IN p_free_throws_made      INT,
  IN p_free_throws_attempted INT
)
BEGIN
  INSERT INTO Player_Stats (
    player_id, game_id, minutes_played, points, rebounds, assists,
    steals, blocks, turnovers,
    field_goals_made, field_goals_attempted,
    free_throws_made, free_throws_attempted
  ) VALUES (
    p_player_id, p_game_id, p_minutes_played, p_points, p_rebounds, p_assists,
    p_steals, p_blocks, p_turnovers,
    p_field_goals_made, p_field_goals_attempted,
    p_free_throws_made, p_free_throws_attempted
  )
  ON DUPLICATE KEY UPDATE
    minutes_played        = VALUES(minutes_played),
    points                = VALUES(points),
    rebounds              = VALUES(rebounds),
    assists               = VALUES(assists),
    steals                = VALUES(steals),
    blocks                = VALUES(blocks),
    turnovers             = VALUES(turnovers),
    field_goals_made      = VALUES(field_goals_made),
    field_goals_attempted = VALUES(field_goals_attempted),
    free_throws_made      = VALUES(free_throws_made),
    free_throws_attempted = VALUES(free_throws_attempted);
END$$

DELIMITER ;

-- Inserting data (Show insert functionality)

INSERT INTO Stadium (naming_rights, city, state, max_capacity) VALUES
  ('Chase Center',           'San Francisco', 'CA', 18064),
  ('Crypto.com Arena',       'Los Angeles',   'CA', 20000),
  ('TD Garden',              'Boston',        'MA', 19156),
  ('Madison Square Garden',  'New York',      'NY', 20789);

INSERT INTO Team (name, wins, losses, stadium_id) VALUES
  ('Golden State Warriors', 0, 0, 1),
  ('Los Angeles Lakers',    0, 0, 2),
  ('Boston Celtics',        0, 0, 3),
  ('New York Knicks',       0, 0, 4);

INSERT INTO Player (name, position, salary, contract_years_remaining, age, height_inches, weight_lbs, team_id) VALUES
  ('Steph Curry',   'Point Guard',    51915615, 2, 36, 75.0, 185.0, 1),
  ('Klay Thompson', 'Shooting Guard', 21563931, 1, 34, 78.5, 215.0, 1),
  ('LeBron James',  'Small Forward',  47607350, 1, 39, 81.0, 250.0, 2),
  ('Anthony Davis', 'Center',         43219440, 2, 31, 82.0, 253.0, 2),
  ('Jayson Tatum',  'Small Forward',  32600060, 3, 26, 80.0, 210.0, 3),
  ('Jaylen Brown',  'Shooting Guard', 29432479, 4, 27, 77.0, 223.0, 3),
  ('Jalen Brunson', 'Point Guard',    26032258, 3, 27, 74.0, 190.0, 4),
  ('Karl-Anthony Towns', 'Center',    49279091, 3, 28, 84.0, 271.0, 4);

INSERT INTO Coach (name, title, age, salary, contract_years_remaining, team_id) VALUES
  ('Steve Kerr',   'Head Coach',      58, 7000000, 2, 1),
  ('JB Bickerstaff', 'Head Coach',    45, 4000000, 3, 2),
  ('Joe Mazzulla', 'Head Coach',      35, 3500000, 4, 3),
  ('Tom Thibodeau','Head Coach',      65, 5000000, 2, 4);

INSERT INTO Game (game_datetime, ticket_price, home_team_id, away_team_id, stadium_id) VALUES
  ('2025-10-22 19:30:00', 250.00, 1, 2, 1),
  ('2025-10-24 20:00:00', 300.00, 3, 4, 3),
  ('2025-10-26 17:30:00', 275.00, 2, 3, 2),
  ('2025-10-28 19:00:00', 350.00, 4, 1, 4);

-- Show data inserted
SELECT * FROM Stadium;
SELECT * FROM Team;
SELECT * FROM Player;
SELECT * FROM Coach;
SELECT * FROM Game;
SELECT * FROM Player_Stats;

-- Show views before procedure calls:
SELECT * FROM vw_standings;
SELECT * FROM vw_schedule;
SELECT * FROM vw_player_season_avg;

-- Game results recorded
CALL sp_record_game_result(1, 115, 108);

-- Show updated Game and Team table after calling sp_record_game_result();
SELECT * FROM Game;
SELECT * FROM Team;

-- Adding player statistics for first game.
CALL sp_upsert_player_stats(1, 1, 36, 32, 4, 8, 2, 0, 3, 11, 22, 8, 9);   -- Curry
CALL sp_upsert_player_stats(2, 1, 28, 18, 3, 2, 1, 0, 2,  7, 16, 3, 4);   -- Klay
CALL sp_upsert_player_stats(3, 1, 38, 28, 7, 6, 3, 2, 4, 10, 20, 7, 8);   -- LeBron
CALL sp_upsert_player_stats(4, 1, 32, 22, 11, 1, 2, 4, 3,  9, 17, 4, 6);  -- A. Davis

-- Show updated Player_Stats table after calling sp_upsert_player_stats();
SELECT * FROM Player_Stats;

-- Removing a player (DELETE functionality):
DELETE FROM Player_Stats WHERE player_id = 8;
DELETE FROM Player WHERE player_id = 8;

-- Shows updated Player table after deleting a player.
SELECT * FROM Player;


-- Query examples:
-- 1. League standings
SELECT * FROM vw_standings;

-- 2. Full schedule
SELECT * FROM vw_schedule ORDER BY game_datetime;

-- 3. Season averages for all players, sorted by PPG
SELECT * FROM vw_player_season_avg ORDER BY ppg DESC;

-- 4. Filter players by position
SELECT name, team_name, ppg, rpg, apg
FROM vw_player_season_avg
WHERE position = 'Center'
ORDER BY ppg DESC;

-- 5. Roster salary search: players earning $30M+ with 2+ years left
SELECT name, position, salary, contract_years_remaining
FROM Player p
JOIN Team t ON t.team_id = p.team_id
WHERE salary >= 30000000 AND contract_years_remaining >= 2
ORDER BY salary DESC;

-- 6. Games at a specific stadium
SELECT * FROM vw_schedule WHERE venue = 'Chase Center';

-- 7. Games within a date range
SELECT * FROM vw_schedule
WHERE game_datetime BETWEEN '2025-10-22' AND '2025-10-28';