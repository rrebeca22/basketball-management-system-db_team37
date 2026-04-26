USE basketball_mgmt;

-- Sample queries for data

-- 1. League standings
SELECT * FROM vw_standings;

-- 2. Full schedule
SELECT * FROM vw_schedule ORDER BY game_datetime;

-- 3. Season averages for all players by PPG
SELECT * FROM vw_player_season_avg ORDER BY ppg DESC;

-- 4. Showing Center position players
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