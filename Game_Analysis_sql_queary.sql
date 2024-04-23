SELECT* FROM game_project.level_details2;


1. Extract P_ID,Dev_ID,PName and Difficulty_level of all players at level 0.
Answer:

SELECT game_project.level_details2.P_ID,
      game_project.level_details2.Dev_ID, 
      game_project.level_details2.Difficulty, 
      game_project.player_details.PName
FROM game_project.level_details2
JOIN  game_project.player_details 
ON game_project.level_details2.P_ID =  game_project.player_details.P_ID
WHERE game_project.level_details2.Difficulty = 0;

 2.  Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast 3 stages are crossed.
Answer:

 SELECT game_project.player_details.L1_Code, AVG(game_project.level_details2.Kill_Count) AS Average_Kill_Count
FROM  game_project.player_details
JOIN game_project.level_details2 ON game_project.player_details.P_ID = game_project.level_details2.P_ID
WHERE Lives_Earned = 2
GROUP BY game_project.player_details.L1_Code
HAVING COUNT(Lives_Earned) >= 3;

 3. Find the total number of stages crossed at each diffuculty level where for Level2 with players use zm_series devices. Arrange the result in decsreasing order of total number of stages crossed.
Answer:

SELECT 
       SUM(Stages_crossed) AS total_stages_crossed,
       Difficulty
FROM game_project.level_details2
WHERE Level=2 AND Dev_Id LIKE 'zm%'
Group by Difficulty
ORDER BY total_Stages_crossed DESC;      
 
 4. Extract P_ID and the total number of unique dates for those players who have played games on multiple days.
Answer:

 SELECT P_ID, 
 COUNT(TimeStamp) AS Unique_Dates
FROM game_project.level_details2
GROUP BY P_ID
HAVING COUNT(TimeStamp) > 1;

 5. Find P_ID and level wise sum of kill_counts where kill_count is greater than avg kill count for the Medium difficulty.
Answer:

with MediumAvg AS ( 
SELECT AVG (Kill_Count)as avg_kill_count
 FROM game_project.level_details2
 where Difficulty= 'Medium'
 )
 select P_ID, Level, sum(kill_count) as total_kill_count
 from game_project.level_details2
 CROSS JOIN MediumAvg
 WHERE Kill_Count>(select avg_kill_count from MediumAvg)
 group by P_ID, Level;

6. Find Level and its corresponding Level code wise sum of lives earned excluding level 0. Arrange in asecending order of level.
Answer:

SELECT Level, SUM(Lives_earned) AS Total_lives_earned,
			  COALESCE (L1_Code, L2_Code) AS Level_code
FROM game_project.level_details2
INNER JOIN game_project.player_details ON 
( game_project.level_details2.P_ID = game_project.player_details.P_ID)
WHERE Level <> 0
GROUP BY Level,
		 L1_Code,
         L2_Code
ORDER BY Level ASC;

7. Find Top 3 score based on each dev_id and Rank them in increasing order using Row_Number. Display difficulty as well. 
Answer:

    WITH RankedScores AS (
    SELECT Dev_ID,
           Score,
           Difficulty,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Score) AS row_num
    FROM game_project.level_details2
)
SELECT Dev_ID, Score, Difficulty
FROM RankedScores
WHERE 
     row_num <= 3
ORDER BY Dev_ID, Difficulty, Score, row_num; 


8. Find first_login datetime for each device id
Answer:

SELECT Dev_ID, MIN(TimeStamp) AS first_login
FROM  game_project.level_details2
GROUP BY Dev_ID;
 
 9. Find Top 5 score based on each difficulty level and Rank them in increasing order using Rank. Display dev_id as well.
 Answer:
 
 WITH TopScores AS (
    SELECT 
        Dev_ID,
        Score,
        Difficulty,
        RANK() OVER (PARTITION BY Difficulty ORDER BY Score DESC) AS score_rank 
    FROM game_project.level_details2)
SELECT Dev_ID, Score, Difficulty, score_rank
FROM TopScores
WHERE score_rank <= 5 
ORDER BY Difficulty ASC, 
    score_rank ASC; 
 
 10. Find the device ID that is first logged in(based on start_datetime) for each player(p_id). Output should contain player id, device id and first login datetime.
Answer:

SELECT P_ID, Dev_ID, TimeStamp
FROM  game_project.level_details2
WHERE
    (P_ID, TimeStamp) IN (
        SELECT
            P_ID,
            MIN(TimeStamp) AS event_date
        FROM game_project.level_details2
        GROUP BY 1
    );
  
  11.For each player and date, how many kill_count played so far by the player. That is, the total number of games played by the player until that date.
-- a) window function
-- b) without window function

  USING WINDOW FUNCTION
  SELECT
    P_ID,
    TimeStamp,
    Kill_Count,
    SUM(Kill_Count) OVER (PARTITION BY P_ID ORDER BY TimeStamp) AS Cumulative_Kill_Count
FROM
     game_project.level_details2
ORDER BY
    P_ID, TimeStamp; 
    
  WITHOUT WINDOW FUNCTION
  
    SELECT
    t1.P_ID,
    t1.TimeStamp,
    t1.Kill_Count,
    (SELECT SUM(t2.Kill_Count)
     FROM  game_project.level_details2 t2
     WHERE t2.P_ID = t1.P_ID
       AND t2.TimeStamp <= t1.TimeStamp
    ) AS Cumulative_Kill_Count
FROM
    game_project.level_details2 t1
ORDER BY
    t1.P_ID, t1.TimeStamp; 
    
    
  12.Find the cumulative sum of an stages crossed over a start_datetime for each player id but exclude the most recent start_datetime.
  Answer:
  
  SELECT
    t1.P_ID,
    t1.TimeStamp,
    t1.Stages_crossed,
    (SELECT SUM(t2.Stages_crossed)
     FROM   game_project.level_details2 t2
     WHERE t2.P_ID = t1.P_ID
       AND t2.TimeStamp < t1.TimeStamp
    ) AS Cumulative_Stages_Crossed
FROM
     game_project.level_details2 t1
ORDER BY
    t1.P_ID, t1.TimeStamp;
    
  13. Extract top 3 highest sum of score for each device id and the corresponding player_id
  Answer:

  WITH RankedScores AS (
    SELECT Dev_ID, P_ID, SUM(Score) AS TotalScore,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank2
    FROM game_project.level_details2
    GROUP BY Dev_ID, P_ID
)
SELECT Dev_ID, P_ID, TotalScore
FROM RankedScores
WHERE 
	TotalScore >= 5600
ORDER BY Dev_ID,TotalScore; 


14. Find players who scored more than 50% of the avg score scored by sum of 
scores for each player_id
Answer:

WITH PlayerAverageScores AS (
    SELECT P_ID, AVG(Score) AS AvgScore
    FROM game_project.level_details2
    GROUP BY P_ID
)
SELECT t.P_ID, t.Score
FROM game_project.level_details2 t
JOIN PlayerAverageScores pas ON t.P_ID = pas.P_ID
WHERE t.Score > 0.5 * pas.AvgScore;



15. Find the cumulative sum of stages crossed over a start_datetime 
Answer: 

SELECT
    TimeStamp,
    Stages_crossed,
    SUM(Stages_crossed) OVER (ORDER BY TimeStamp) AS cumulative_stages_crossed
FROM
 game_project.level_details2  ;