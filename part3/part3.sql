-- 1) Напиши функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир-поинтов. 
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
CREATE OR REPLACE FUNCTION read_TransferredPoints()
	RETURNS TABLE(Peer1 VARCHAR, Peer2 VARCHAR, "PointsAmount" INTEGER)
AS $$
BEGIN
	RETURN QUERY
	WITH tmp AS (
	SELECT tp1.id, tp1.CheckingPeer, tp1.CheckedPeer,
		(tp1.PointsAmount - tp2.PointsAmount)
	FROM TransferredPoints AS tp1
	INNER JOIN TransferredPoints AS tp2
		ON tp1.CheckingPeer = tp2.CheckedPeer
		AND tp2.CheckingPeer = tp1.CheckedPeer)

	SELECT CheckingPeer AS Peer1, CheckedPeer AS Peer2, PointsAmount
	FROM
		(SELECT * FROM TransferredPoints as tp
			WHERE (id NOT IN (SELECT id FROM tmp))
			UNION
		SELECT * FROM tmp
			ORDER BY id ASC);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM read_TransferredPoints();
-- DROP FUNCTION read_TransferredPoints();

-- 2) Напиши функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включи только задания, успешно прошедшие проверку (определять по таблице Checks). 
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включи все успешные проверки.
CREATE OR REPLACE FUNCTION read_XP()
	RETURNS TABLE("Peer" VARCHAR, "Task" VARCHAR, "XP" INTEGER)
AS $read_xp_success$
BEGIN
	RETURN QUERY
	SELECT ch.Peer, ch.Task, xpamount as "XP" FROM xp
	INNER JOIN checks as ch
		ON ch.id = xp."Check"
	INNER JOIN verter as v
		ON ch.id = v."Check"
		AND v.state = 'Success'
	INNER JOIN p2p
		ON p2p."Check" = v."Check"
		AND p2p.state = 'Success'
	ORDER BY ch.id;
END;
$read_xp_success$ LANGUAGE plpgsql;

SELECT * FROM read_XP();
-- DROP FUNCTION read_XP();

-- 3) Напиши функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например, 12.05.2022. 
-- Функция возвращает только список пиров.
CREATE OR REPLACE FUNCTION peers_not_exited(day_visit date)
	RETURNS SETOF VARCHAR
AS $$
BEGIN
	RETURN QUERY
	SELECT peer
	FROM TimeTracking as tt
		WHERE date = day_visit
	GROUP BY peer
	HAVING SUM(tt.State) = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM peers_not_exited('2023-03-20');
-- SELECT * FROM peers_not_exited('2021-11-01');
-- DROP FUNCTION peers_not_exited(day_visit date);

-- 4) Посчитай изменение в количестве пир-поинтов каждого пира по таблице TransferredPoints
-- Результат выведи отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир-поинтов.
CREATE OR REPLACE FUNCTION change_prp_peers()
	RETURNS TABLE(Peer VARCHAR, "PointsChange" BIGINT)
AS $$
BEGIN
	RETURN QUERY
	WITH res_tp AS (
		SELECT CheckingPeer, PointsAmount
		FROM TransferredPoints 
			UNION ALL 
		SELECT CheckedPeer, -PointsAmount
		FROM TransferredPoints)
	SELECT CheckingPeer AS Peer, SUM(PointsAmount) AS PointsChange
	FROM res_tp
	GROUP BY Peer
	ORDER BY PointsChange DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM change_prp_peers();
-- DROP FUNCTION change_prp_peers();

-- 5) Посчитай изменение в количестве пир-поинтов каждого пира по таблице, возвращаемой первой функцией из Part 3
-- Результат выведи отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир-поинтов.
CREATE OR REPLACE FUNCTION change_number_prp()
	RETURNS TABLE("Peer" VARCHAR, "PointsChange" BIGINT)
AS $$
BEGIN
	RETURN QUERY
	WITH res AS 
		(SELECT Peer1, "PointsAmount" FROM read_TransferredPoints()
		WHERE "PointsAmount" > 0
			UNION ALL
		SELECT Peer2, -"PointsAmount" FROM read_TransferredPoints()
		WHERE "PointsAmount" > 0)

	SELECT Peer1 as Peer, SUM("PointsAmount") as PointsChange FROM res
	GROUP BY Peer1
	ORDER BY PointsChange DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM change_number_prp();
-- DROP FUNCTION change_number_prp();

-- 6) Определи самое часто проверяемое задание за каждый день
-- При одинаковом количестве проверок каких-то заданий в определенный день выведи их все. 
-- Формат вывода: день, название задания.
CREATE OR REPLACE FUNCTION frequently_checked_task_for_days()
	RETURNS TABLE("Day" DATE, "Task" VARCHAR)
AS $$
BEGIN
	RETURN QUERY
	WITH res AS (
		SELECT date, Task,
			RANK() OVER (PARTITION BY date ORDER BY COUNT(Task) DESC) AS num
		FROM Checks
		GROUP BY date, Task)
	SELECT date as "Day", Task FROM res
	WHERE num = 1;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM frequently_checked_task_for_days();
-- DROP FUNCTION frequently_checked_task_for_days();

-- 7) Найди всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
-- Параметры процедуры: название блока, например, «CPP». 
-- Результат выведи отсортированным по дате завершения. 
-- Формат вывода: ник пира, дата завершения блока (т. е. последнего выполненного задания из этого блока).
CREATE OR REPLACE FUNCTION peers_finished_blocks(block_name VARCHAR)
RETURNS TABLE("Peer" VARCHAR, "Day" DATE)
AS $$
BEGIN
 RETURN QUERY
 SELECT DISTINCT Peer, Date
 FROM Checks
 JOIN XP ON XP."Check" = Checks.ID
 WHERE Task IN (SELECT MAX(Title)
       FROM Tasks
       WHERE Title LIKE block_name || '%')
 ORDER BY Date DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM peers_finished_blocks('DO');
-- DROP FUNCTION peers_finished_blocks(block_name VARCHAR);

-- 8) Определи, к какому пиру стоит идти на проверку каждому обучающемуся
-- Определять нужно, исходя из рекомендаций друзей пира, т. е. нужно найти пира, проверяться у которого рекомендует наибольшее число друзей. 
-- Формат вывода: ник пира, ник найденного проверяющего.
CREATE OR REPLACE FUNCTION every_student_should_be_tested()
	RETURNS TABLE("Peer" VARCHAR, "RecommendedPeer" VARCHAR)
AS $$
BEGIN
	RETURN QUERY
		WITH tb_friends AS (
			SELECT DISTINCT peer1, peer2 FROM friends
				UNION
			SELECT peer2, peer1 FROM friends),
	
		friend_remodended AS (
			SELECT f.peer1 as peer, rc.RecommendedPeer, COUNT(*) AS cnt
			FROM tb_friends as f
			INNER JOIN Recommendations as rc
				ON f.peer2 = rc.Peer
				AND rc.RecommendedPeer <> f.peer1
			GROUP BY f.peer1, rc.RecommendedPeer)

		SELECT DISTINCT ON (Peer) Peer, RecommendedPeer
		FROM friend_remodended
		ORDER BY peer, cnt DESC, RecommendedPeer;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM every_student_should_be_tested();
-- DROP FUNCTION every_student_should_be_tested();

-- 9) Определи процент пиров, которые: Приступили только к блоку 1; Приступили только к блоку 2;
-- Приступили к обоим; Не приступили ни к одному.
CREATE OR REPLACE PROCEDURE pr_peer_blocks_simple(first_block VARCHAR, second_block VARCHAR) 
LANGUAGE PLPGSQL AS $$
DECLARE
    peer_count BIGINT;
BEGIN
    DROP TABLE IF EXISTS temp_block_results;
    CREATE TEMP TABLE temp_block_results (
        StartedBlock1 INT,
        StartedBlock2 INT,
        StartedBothBlocks INT,
        DidntStartAnyBlock INT
    ) ON COMMIT DROP;
	
    SELECT COUNT(*) INTO peer_count FROM Peers;

    WITH
    peers_block1 AS (SELECT DISTINCT Peer FROM Checks WHERE Task LIKE first_block || '%'),
    peers_block2 AS (SELECT DISTINCT Peer FROM Checks WHERE Task LIKE second_block || '%'),
    counts AS (
        SELECT
            (SELECT COUNT(*) FROM (SELECT Peer FROM peers_block1 EXCEPT SELECT Peer FROM peers_block2) t) AS count_only1,
            (SELECT COUNT(*) FROM (SELECT Peer FROM peers_block2 EXCEPT SELECT Peer FROM peers_block1) t) AS count_only2,
            (SELECT COUNT(*) FROM (SELECT Peer FROM peers_block1 INTERSECT SELECT Peer FROM peers_block2) t) AS count_both,
            (SELECT COUNT(*) FROM (SELECT Nickname FROM Peers EXCEPT SELECT Peer FROM peers_block1 EXCEPT SELECT Peer FROM peers_block2) t) AS count_none
    )
    INSERT INTO temp_block_results
    SELECT
        ROUND(count_only1 * 100.0 / peer_count),
        ROUND(count_only2 * 100.0 / peer_count),
        ROUND(count_both * 100.0 / peer_count),
        ROUND(count_none * 100.0 / peer_count)
    FROM counts;
END;
$$;

CALL pr_peer_blocks_simple('CPP', 'DO');
SELECT * FROM temp_block_results;
-- DROP PROCEDURE pr_peer_blocks_simple(first_block VARCHAR, second_block VARCHAR);

-- 10) Определи процент пиров, которые когда-либо успешно проходили проверку в свой день рождения
-- Также определи процент пиров, которые хоть раз проваливали проверку в свой день рождения. 
-- Формат вывода: процент пиров, успешно прошедших проверку в день рождения, процент пиров, проваливших проверку в день рождения.
CREATE OR REPLACE FUNCTION peers_was_checked_on_birthday()
RETURNS TABLE(SuccessfulChecks INT, UnsuccessfulChecks INT)
AS $$
DECLARE 
 check_success INT;
 check_failure INT;
 success_percent NUMERIC;
 failure_percent NUMERIC;
BEGIN
 WITH peers_check AS (
   SELECT DISTINCT ch.peer AS peer, v.state as state
   FROM Peers as p
   INNER JOIN Checks as ch
    ON p.nickname = ch.peer AND TO_CHAR(p.birthday, 'MM-DD') = TO_CHAR(ch.date, 'MM-DD') 
   INNER JOIN Verter as v
    ON ch.id = v."Check" 
    AND v.state = 'Success'
    OR v.state = 'Failure'
   WHERE ch.id = v."Check"
  )
 SELECT 
  (SELECT COUNT(peer) FROM peers_check WHERE state = 'Success'),
  (SELECT COUNT(peer) FROM peers_check WHERE state = 'Failure')
 INTO check_success, check_failure
 FROM peers_check;

 success_percent := ROUND(100.0 * check_success / (check_success + check_failure));
 failure_percent := 100 - success_percent;

 RETURN QUERY
  SELECT
  success_percent::INT AS SuccessfulChecks,
  failure_percent::INT AS UnsuccessfulChecks;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM peers_was_checked_on_birthday();
-- DROP FUNCTION peers_was_checked_on_birthday();

-- 11) Определи всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3
-- Параметры процедуры: названия заданий 1, 2 и 3. 
-- Формат вывода: список пиров.
CREATE OR REPLACE PROCEDURE find_peers_completed_tasks_except(
				first_task VARCHAR, second_task VARCHAR, third_task VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
	DROP TABLE IF EXISTS temp_table;
    CREATE TEMPORARY TABLE temp_table (Peer VARCHAR) ON COMMIT DROP;
	
	WITH t1 AS(
			SELECT DISTINCT Peer 
			FROM Checks as ch
			INNER JOIN Verter as v
				ON v."Check" = ch.id
			WHERE v.State = 'Success' 
				AND ch.Task = first_task),
	    t2 AS(
		    SELECT DISTINCT Peer 
			FROM Checks as ch
		    INNER JOIN Verter as v
				ON v."Check" = ch.id
		    WHERE v.State = 'Success' 
				AND ch.Task = second_task),
	    t3 AS(
		    SELECT DISTINCT Peer 
			FROM Checks as ch
		    INNER JOIN Verter as v
				ON v."Check" = ch.id
		    WHERE v.State = 'Failure'
				AND ch.Task = third_task)

	INSERT INTO temp_table
		SELECT * FROM t1
			INTERSECT
		SELECT * FROM t2
			INTERSECT
		SELECT * FROM t3;
END;
$$;

-- CALL find_peers_completed_tasks_except('DO5','CPP1','DO1');
CALL find_peers_completed_tasks_except('DO5_SimpleDocker','CPP1_s21_matrixplus','DO1_Linux');
SELECT * FROM temp_table;
-- DROP PROCEDURE find_peers_completed_tasks_except;

-- 12) Используя рекурсивное обобщенное табличное выражение, для каждой задачи выведи кол-во предшествующих ей задач
-- То есть сколько задач нужно выполнить, исходя из условий входа, чтобы получить доступ к текущей. 
-- Формат вывода: название задачи, количество предшествующих.
CREATE OR REPLACE FUNCTION number_previous_tasks_for_future()
	RETURNS TABLE(Task VARCHAR, PrevCount INTEGER) 
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		WITH RECURSIVE task_hierarchy AS (
		SELECT  Title, ParentTask, 0 AS PrevCount
		FROM Tasks
			WHERE ParentTask IS NULL
		
		UNION ALL
	
		SELECT t.Title, t.ParentTask, th.PrevCount + 1
		FROM Tasks as t
		JOIN task_hierarchy as th 
			ON t.ParentTask = th.Title)
			
	SELECT t.Title AS Task, t.PrevCount
	FROM task_hierarchy as t
	ORDER BY Task;	
END;
$$;

SELECT * FROM number_previous_tasks_for_future();
-- DROP FUNCTION number_previous_tasks_for_future();

-- 13) Найди «удачные» для проверок дни. День считается «удачным», если в нем есть хотя бы N идущих подряд успешных проверки
-- Параметры процедуры: количество идущих подряд успешных проверок N. 
-- Временем проверки считай время начала P2P-этапа. 
-- Под идущими подряд успешными проверками подразумеваются успешные проверки, между которыми нет неуспешных. 
-- При этом кол-во опыта за каждую из этих проверок должно быть не меньше 80% от максимального.
CREATE OR REPLACE PROCEDURE lucky_days(IN n INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    luck_day TEXT := '';
    list RECORD;
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_results(days DATE) ON COMMIT DROP;

    WITH successful_checks AS (
        SELECT ch.Date, t.maxxp, xp.xpamount
        FROM Checks ch
        INNER JOIN P2P 
			ON ch.id = P2P."Check" AND P2P.state = 'Start'
        INNER JOIN Verter v 
			ON ch.id = v."Check" AND v.state = 'Success'
        INNER JOIN Tasks t 
			ON t.title = ch.task
        INNER JOIN XP 
			ON ch.id = XP."Check"
        WHERE XP.xpamount >= t.maxxp * 0.8
    )
	INSERT INTO temp_results
	    SELECT Date
	    FROM successful_checks
	    GROUP BY Date
	    HAVING COUNT(Date) >= n;
    
    FOR list IN 
		SELECT days FROM temp_results ORDER BY days
    LOOP
        luck_day := luck_day || list.days || '; ';
    END LOOP;
    RAISE NOTICE 'Good days for inspections: %', luck_day;
END;
$$;
CALL lucky_days(1);
-- SELECT * FROM temp_results;
-- DROP PROCEDURE lucky_days(IN n INTEGER);

-- 14) Определи пира с наибольшим количеством XP
-- Формат вывода: ник пира, количество XP.
CREATE OR REPLACE FUNCTION get_top_peer()
	RETURNS TABLE(Peer VARCHAR, XP BIGINT) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
		SELECT ch.Peer, SUM(XP.XPAmount) AS XP
		FROM Checks as ch
		INNER JOIN XP 
			ON ch.id = XP."Check"
		WHERE EXISTS (
				SELECT 1 FROM Verter as v
				WHERE v."Check" = ch.id 
					AND v.State = 'Success')
		GROUP BY ch.Peer
		ORDER BY XP DESC
		LIMIT 1;
END;
$$;

SELECT * FROM get_top_peer();
-- DROP FUNCTION get_top_peer();

-- 15) Определи пиров, приходивших раньше заданного времени не менее N раз за всё время
-- Параметры процедуры: время, количество раз N. 
-- Формат вывода: список пиров.
CREATE OR REPLACE PROCEDURE find_early_coming_peers(IN find_time TIME, IN N INT)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_early_peers(Peer VARCHAR) ON COMMIT DROP;
	INSERT INTO temp_early_peers
	    SELECT tt.Peer 
	    FROM TimeTracking as tt
	    WHERE tt.Time < find_time
	      AND tt.State = '1'
	    GROUP BY tt.Peer
	    HAVING COUNT(*) >= N;
END;
$$;

CALL find_early_coming_peers('19:08:52', 1);
SELECT * FROM temp_early_peers;
-- DROP PROCEDURE find_early_coming_peers(IN find_time TIME, IN N INT);

-- 16) Определи пиров, выходивших за последние N дней из кампуса больше M раз
-- Параметры процедуры: количество дней N, количество раз M. 
-- Формат вывода: список пиров.
CREATE OR REPLACE PROCEDURE find_left_peers(IN N INT, IN M INT)
LANGUAGE plpgsql
AS $$
BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp_left_peers(Peer VARCHAR) ON COMMIT DROP;
	INSERT INTO temp_left_peers
	    SELECT tt.Peer 
	    FROM Peers as p
		JOIN TimeTracking as tt
			ON tt.Peer = p.Nickname
	    	WHERE (tt.State = '2') AND (Date >= current_date - N)
	    GROUP BY tt.Peer
	    HAVING COUNT(*) > M;
END;
$$;

CALL find_left_peers(200, 1);
SELECT * FROM temp_left_peers;
-- DROP PROCEDURE find_left_peers(IN N INT, IN M INT);

-- 17) Определи для каждого месяца процент ранних входов
-- Для каждого месяца посчитай, сколько раз люди, родившиеся в этом месяце, приходили в кампус за всё время (будем называть это общим числом входов).
-- Для каждого месяца посчитай процент ранних входов в кампус относительно общего числа входов. 
-- Формат вывода: месяц, процент ранних входов.
CREATE OR REPLACE FUNCTION percentage_entrance_each_month()
RETURNS TABLE(Month TEXT, EarlyEntries INT) 
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
		WITH all_months AS (
			SELECT 
			generate_series(1, 12) AS month_num,
			trim(to_char(to_date(generate_series(1, 12)::text, 'MM'), 'Month')) AS month_name),
			
			peer_stats AS (
				SELECT 
					EXTRACT(MONTH FROM p.Birthday) AS birth_month,
					(SUM(CASE WHEN tt.State = 1 
							THEN 1 ELSE 0 END))::numeric AS total_entries,
					(SUM(CASE WHEN tt.State = 1 AND tt.Time < '12:00:00' 
							THEN 1 ELSE 0 END))::numeric AS early_entries
				FROM Peers as p
				LEFT JOIN TimeTracking as tt 
					ON p.Nickname = tt.Peer
				GROUP BY EXTRACT(MONTH FROM p.Birthday))
	
		SELECT am.month_name AS Month,
			(CASE
				WHEN ps.total_entries IS NULL THEN 0
				WHEN ps.total_entries = 0 THEN 0
				ELSE ROUND((ps.early_entries / ps.total_entries) * 100)::INT
			END) AS EarlyEntries
		FROM all_months as am
		LEFT JOIN peer_stats as ps 
			ON am.month_num = ps.birth_month
		ORDER BY am.month_num;	
END;
$$;

SELECT * FROM percentage_entrance_each_month();
-- DROP FUNCTION percentage_entrance_each_month();
