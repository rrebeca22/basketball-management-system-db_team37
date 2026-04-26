-- Data inserted to database shown here.

SELECT * FROM Stadium;
SELECT * FROM Team;
SELECT * FROM Player;
SELECT * FROM Coach;
SELECT * FROM Game;
SELECT * FROM Player_Stats;

-- Show procedures(update) and delete functionality. 
-- Run after: CALL sp_record_game_result(1, 115, 108);
SELECT * FROM Game;
SELECT * FROM Team;

-- Run after: CALL sp_upsert_player_stats(...);
SELECT * FROM Player_Stats;

-- Run after: DELETE FROM Player WHERE player_id = 8;
DELETE FROM Player_Stats WHERE player_id = 8;
DELETE FROM Player WHERE player_id = 8;