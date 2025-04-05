CREATE DATABASE IPL;
USE IPL;
CREATE TABLE cleaned_matches (
    id INT PRIMARY KEY,
    season INT,
    city VARCHAR(100),
    date DATE,
    team1 VARCHAR(100),
    team2 VARCHAR(100),
    toss_winner VARCHAR(100),
    toss_decision VARCHAR(10),
    result VARCHAR(50),
    winner VARCHAR(100),
    win_by_runs INT,
    win_by_wickets INT,
    player_of_match VARCHAR(100),
    venue VARCHAR(255)
);
CREATE TABLE cleaned_deliver  (
    match_id INT,
    inning INT,
    batting_team VARCHAR(100),
    bowling_team VARCHAR(100),
    `over` INT,  -- Enclosed in backticks
    ball INT,
    batter VARCHAR(100),
    bowler VARCHAR(100),
    non_striker VARCHAR(100),
    batsman_runs INT,
    extra_runs INT,
    total_runs INT,
    is_wicket INT,
    player_dismissed VARCHAR(100),
    dismissal_kind VARCHAR(50),
    fielder VARCHAR(100)
);
SELECT * FROM  cleaned_deliver LIMIT 10;
SELECT * FROM cleaned_matches LIMIT 10;

ALTER TABLE cleaned_matches RENAME TO matches;
ALTER TABLE cleaned_deliver RENAME TO deliveries;

SELECT COUNT(*) AS Total_matches FROM matches;
SELECT COUNT(*)  AS no_of_deliveries FROM deliveries;
SELECT DISTINCT(city),season FROM matches;
SELECT DISTINCT(city) FROM matches;

-- 1. Ipl match winners for each season (2008-2024)
SELECT season, winner, COUNT(*) AS total_wins
FROM matches
GROUP BY season, winner
ORDER BY season ASC, total_wins DESC;

-- 2 Extract Teams That Reached a more than 100  Result Margin
SELECT winner, result_margin
FROM matches
WHERE result_margin >= 100
ORDER BY result_margin DESC
LIMIT 7;

-- 3 Extract the ids of matches,teams ,cites  and year That Reached the target runs more than 250
SELECT id,team1,team2,city,target_runs,YEAR(date) AS match_year
FROM matches
WHERE target_runs > 250
ORDER BY target_runs DESC;

-- 4 Most frequently Matches Played in a Stadium

SELECT venue, COUNT(*) AS total_matches
FROM matches
GROUP BY venue
ORDER BY total_matches DESC
LIMIT 10;

-- 5 Extract Matches That Were Abandoned Due to Rain

SELECT id
FROM matches
WHERE player_of_match="no_player_of_match";


-- 7.Which Team Wins the Most Tosses for Fielding/Batting

SELECT toss_winner, toss_decision, COUNT(*) AS count
FROM matches
GROUP BY toss_winner, toss_decision
ORDER BY count DESC; 

-- 8. Batsmen with Most Sixes

SELECT batter, COUNT(*) AS no_of_sixes
FROM deliveries
WHERE batsman_runs = 6
GROUP BY batter
ORDER BY no_of_sixes DESC
LIMIT 10;

-- 9 total runs scored in the year 2020 by sunrises
SELECT batting_team, SUM(total_runs) AS total_runs,year(date)
FROM deliveries
JOIN matches ON deliveries.match_id = matches.id
WHERE Date = '2020' and batting_team='Sunrisers Hyderabad'
GROUP BY batting_team
ORDER BY total_runs DESC;

-- 10. Top 10 bowlers based on the most wickets
SELECT bowler, COUNT(player_dismissed) AS total_wickets
FROM deliveries
WHERE dismissal_kind IS NOT NULL
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 10;

-- 11.top 10 batters who scored most runs

SELECT batter, SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;

-- 12.Get the season who played in M Chinnaswamy Stadium ,city banglore,year,id
SELECT id,season,venue,YEAR(date),city
FROM matches 
WHERE venue="M Chinnaswamy Stadium" AND city="Bangalore"
LIMIT 10;

-- 13. extract the id,winner,season,year where winner is KKR
SELECT id,winner,season,YEAR(date) FROM matches
WHERE winner="Kolkata Knight Riders"
ORDER BY id DESC;

-- 14. Total matches played by each teams
SELECT team1 AS team, COUNT(*) AS total_matches 
FROM matches
GROUP BY team1
UNION ALL
SELECT team2 AS team, COUNT(*) AS total_matches 
FROM matches
GROUP BY team2;

-- 15.Finding the match with the highest number of extras conceded
SELECT match_id, SUM(extra_runs) AS total_extras
FROM deliveries
GROUP BY match_id
ORDER BY total_extras DESC;

-- 16. the average first innings score for each season
SELECT m.season, ROUND(AVG(d.total_runs), 2) AS avg_first_innings_score
FROM deliveries d
JOIN matches m ON d.match_id = m.id
WHERE inning = 1
GROUP BY m.season
ORDER BY m.season;

-- 17. 

SELECT inning,extras_type,non_striker
FROM deliveries 
WHERE extras_type="legbyes" AND non_striker="SC Ganguly";

-- 18 write a query to extract id,legbyes or wides and non striker from deliveries
SELECT match_id,extras_type,non_striker
FROM deliveries 
WHERE extras_type="legbyes" OR extras_type="wides"; 

-- Advanced queries:

-- 1. Identifying Close Matches (Wins by 10 or Fewer Runs or 1 Wicket)

SELECT id, team1, team2, winner, result, result_margin
FROM matches
WHERE (result = 'runs' AND result_margin <= 10) 
   OR (result = 'wickets' AND result_margin = 1);

-- 2.Comparing Teams' Run Rates Across All Matches

SELECT batting_team, 
       ROUND(SUM(total_runs) / COUNT(DISTINCT match_id), 2) AS avg_run_rate
FROM deliveries
GROUP BY batting_team
ORDER BY avg_run_rate DESC;

-- 3. Average Runs Scored in Each Over of an IPL Match
SELECT 'over', ROUND(AVG(total_runs), 2) AS avg_runs
FROM deliveries
GROUP BY 'over'
ORDER BY 'over';

-- 4.Extract the teams with most successfull run chases
SELECT winner, COUNT(*) AS successful_chases
FROM matches
WHERE toss_decision = 'field' AND result = 'wickets'
GROUP BY winner
ORDER BY successful_chases DESC;

-- 5. Blowers with most wickets 

SELECT bowler, COUNT(player_dismissed) AS total_wickets
FROM deliveries
WHERE player_dismissed IS NOT NULL
GROUP BY bowler
ORDER BY total_wickets DESC
LIMIT 5;

-- 6.  Identifying the Most Consistent Teams Over the Years
SELECT season, winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, total_wins DESC;

-- 7.Matches Where a Team Scored More Than 200 Runs (CASE Function)
SELECT id, team1, team2,YEAR(date),
       (CASE 
           WHEN target_runs > 200 THEN 'High Score' 
           ELSE 'Low Score' 
       END) AS match_category
FROM matches;

-- 8.Most Six-Hitting Batsmen (Window Function)

SELECT batter, total_sixes
FROM (
    SELECT batter, 
           COUNT(*) AS total_sixes,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS 'rank'
    FROM deliveries
    WHERE batsman_runs = 6
    GROUP BY batter
) t
WHERE 'rank' <= 5;

-- 9. Running Total of Runs Scored by Each Team (Window Function)
SELECT 
    match_id,
    batting_team,
    'over',
    ball,
    SUM(total_runs) OVER (PARTITION BY match_id, batting_team ORDER BY 'over', ball) AS running_total_runs
FROM deliveries;

-- 10. Assigns a unique row number to each delivery per match in order of runs scored.
SELECT 
    match_id,
    batting_team,
    'over',
    ball,
    total_runs,
    ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY total_runs DESC) AS row_num
FROM deliveries;

-- 11. Ranks deliveries within a match, but skips ranks if there are ties.

SELECT 
    match_id,
    batting_team,
    'over',
    ball,
    total_runs,
    RANK() OVER (PARTITION BY match_id ORDER BY total_runs DESC) AS 'rank'
FROM deliveries;

-- 12.  Using DENSE_RANK() – Similar to RANK(), but does not skip ranking.

SELECT 
    match_id,
    batting_team,
    'over',
    ball,
    total_runs,
    DENSE_RANK() OVER (PARTITION BY match_id ORDER BY total_runs DESC) AS 'dense_rank'
FROM deliveries;

-- 13 Checking Player Performance Based on Runs Scored

SELECT 
    batter,
    SUM(batsman_runs) AS total_runs,
    (CASE 
        WHEN SUM(batsman_runs) >= 50 AND SUM(batsman_runs) < 100 THEN 'Half-century'
        WHEN SUM(batsman_runs) >= 100 THEN 'Century'
        ELSE 'Below 50'
    END) AS performance_category
FROM deliveries
GROUP BY batter;

-- 14 Classify Runs Scored in Each Delivery

SELECT 
    match_id,
    batting_team,
    'over',
    ball,
    total_runs,
    (CASE 
        WHEN total_runs = 0 THEN 'Dot Ball'
        WHEN total_runs = 1 THEN 'Single'
        WHEN total_runs = 2 THEN 'Double'
        WHEN total_runs = 3 THEN 'Triple'
        WHEN total_runs = 4 THEN 'Boundary'
        WHEN total_runs = 6 THEN 'Six'
        ELSE 'Other'
    END )AS run_category
FROM deliveries;



