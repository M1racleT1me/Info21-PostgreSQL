-- 1) Напиши процедуру добавления P2P-проверки
-- Параметры: ник проверяемого, ник проверяющего, название задания, статус P2P-проверки, время. 
-- Если задан статус «начало», добавь запись в таблицу Checks (в качестве даты используй сегодняшнюю). 
-- Добавь запись в таблицу P2P. 
-- Если задан статус «начало», в качестве проверки укажи только что добавленную запись, если же нет, то укажи проверку с незавершенным P2P-этапом.
CREATE OR REPLACE PROCEDURE prd_add_p2p_check (
    IN CheckedPeer VARCHAR,
    IN CheckingPeer VARCHAR,
    IN TaskTitle VARCHAR,
    IN P2PStatus check_status,
    IN TimeValue TIME
)
AS $$
DECLARE
    NewCheckID BIGINT;
    ExistingCheckID BIGINT;
    TaskExists BOOLEAN;
BEGIN
    IF P2PStatus = 'Start' THEN
        INSERT INTO Checks
        VALUES ((SELECT MAX(id) FROM Checks) + 1, CheckedPeer, TaskTitle, CURRENT_DATE);
        INSERT INTO P2P (id,"Check", CheckingPeer, State, Time)
        VALUES ((SELECT MAX(id) FROM P2P) + 1, (SELECT MAX("Check") FROM P2P) + 1, CheckingPeer, P2PStatus, TimeValue);
    ELSE
        INSERT INTO P2P (id,"Check", CheckingPeer, State, Time)
        VALUES ((SELECT MAX(id) FROM P2P) + 1, (SELECT MAX("Check") FROM P2p), CheckingPeer, P2PStatus, TimeValue);
    END IF;
END;
$$ LANGUAGE plpgsql;

call prd_add_p2p_check('azovbzwucs', 'iosfiypdje', 'DO1_Linux', 'Start', '10:00:00');
call prd_add_p2p_check('azovbzwucs', 'iosfiypdje', 'DO1_Linux', 'Success', '10:30:00');
-- DROP PROCEDURE prd_add_p2p_check;

-- 2) Напиши процедуру добавления проверки Verter'ом
-- Параметры: ник проверяемого, название задания, статус проверки Verter'ом, время. 
-- Добавь запись в таблицу Verter (в качестве проверки укажи проверку соответствующего задания с самым поздним (по времени) успешным P2P-этапом).
CREATE OR REPLACE PROCEDURE prd_add_verter_check(
    CheckedPeer VARCHAR(255),
    TaskTitle VARCHAR(255),            
    VerterStatus check_status,         
    TimeValue TIME  
)
AS $$
DECLARE
    LastP2PCheckID BIGINT;
    NewVerterID BIGINT;
    StartTime TIME;
    VerterStartExists BOOLEAN;
BEGIN
    SELECT p."Check" INTO LastP2PCheckID
    FROM p2p p
    JOIN checks c ON p."Check" = c.id
    WHERE c.peer = CheckedPeer
      AND c.task = TaskTitle
      AND p.state = 'Success'
    ORDER BY c.date DESC, p.time DESC
    LIMIT 1;

    IF LastP2PCheckID IS NULL THEN
        RAISE EXCEPTION 'Нет успешной P2P-проверки для пира % по заданию %', 
                        CheckedPeer, TaskTitle;
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM Verter 
        WHERE "Check" = LastP2PCheckID AND State = 'Start'
    ) INTO VerterStartExists;

    IF NOT VerterStartExists THEN
        StartTime := (TimeValue - INTERVAL '5 minutes')::TIME;
        
        SELECT COALESCE(MAX(id), 0) + 1 INTO NewVerterID FROM Verter;
        
        INSERT INTO Verter (id, "Check", State, Time)
        VALUES (NewVerterID, LastP2PCheckID, 'Start', StartTime);
    END IF;

    SELECT COALESCE(MAX(id), 0) + 1 INTO NewVerterID FROM Verter;
    INSERT INTO Verter (id, "Check", State, Time)
    VALUES (NewVerterID, LastP2PCheckID, VerterStatus, TimeValue);
END;
$$ LANGUAGE plpgsql;

call prd_add_verter_check('azovbzwucs', 'DO1_Linux', 'Success', '10:30:00');

-- DROP PROCEDURE prd_add_verter_check;

-- 3) Напиши триггер: после добавления записи со статусом «начало» в таблицу 
-- P2P изменяется соответствующая запись в таблице TransferredPoints
CREATE OR REPLACE FUNCTION validate_p2p_insert()
RETURNS TRIGGER AS $$
DECLARE
    checked_peer VARCHAR;
    new_id BIGINT;
BEGIN
    IF NEW.State = 'Start' THEN
        SELECT Peer INTO checked_peer
        FROM Checks
        WHERE id = NEW."Check";
        
        SELECT COALESCE(MAX(id), 0) + 1 INTO new_id FROM TransferredPoints;
        
        UPDATE TransferredPoints
        SET PointsAmount = PointsAmount + 1
        WHERE CheckingPeer = NEW.CheckingPeer
        AND CheckedPeer = checked_peer;
        
        IF NOT FOUND THEN
            INSERT INTO TransferredPoints (id, CheckingPeer, CheckedPeer, PointsAmount)
            VALUES (new_id, NEW.CheckingPeer, checked_peer, 1);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_p2p_insert 
AFTER INSERT ON p2p
FOR EACH ROW 
EXECUTE FUNCTION validate_p2p_insert();


INSERT INTO Peers (Nickname, Birthday) 
VALUES ('peer1', '1999-12-17'), ('peer2', '1999-12-18');

INSERT INTO Checks (id, Peer, Task, Date) 
VALUES (100000, 'peer1', 'DO1_Linux', NOW());

INSERT INTO p2p (id, "Check", CheckingPeer, State, Time) 
VALUES (100000, 100000, 'peer2', 'Start', '12:00');

select * from transferredpoints where checkingpeer = 'peer2'

-- 4) Напиши триггер: перед добавлением записи в таблицу XP проверяется корректность добавляемой записи
-- Запись считается корректной, если:
-- Количество XP не превышает максимальное доступное для проверяемой задачи.
-- Поле Check ссылается на успешную проверку.
-- Если запись не прошла проверку, не добавляй её в таблицу.
CREATE OR REPLACE FUNCTION validate_xp_insert()
RETURNS TRIGGER AS $$
DECLARE
    max_xp INT;
    p2p_status check_status;
    verter_status check_status;
    task_title VARCHAR;
BEGIN
    SELECT c.task, t.maxxp INTO task_title, max_xp
    FROM checks c
    JOIN tasks t ON c.task = t.title
    WHERE c.id = NEW."Check";
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Проверка с ID % не найдена', NEW."Check";
    END IF;

    IF NEW.xpamount > max_xp THEN
        RAISE EXCEPTION 'XP превышает максимальное значение для задания "%"', 
                        task_title;
    END IF;

    SELECT state INTO p2p_status
    FROM p2p
    WHERE "Check" = NEW."Check" AND state != 'Start'
    ORDER BY time DESC
    LIMIT 1;

    SELECT state INTO verter_status
    FROM verter
    WHERE "Check" = NEW."Check"
    ORDER BY time DESC
    LIMIT 1;

    IF p2p_status IS NULL THEN
        RAISE EXCEPTION 'Отсутствует P2P проверка для записи %', NEW."Check";
    ELSIF p2p_status != 'Success' THEN
        RAISE EXCEPTION 'P2P проверка не успешна (статус: %)', p2p_status;
    ELSIF verter_status IS NOT NULL AND verter_status != 'Success' THEN
        RAISE EXCEPTION 'Verter проверка не успешна (статус: %)', verter_status;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_xp_insert
BEFORE INSERT ON xp
FOR EACH ROW
EXECUTE FUNCTION validate_xp_insert();

INSERT INTO XP (id, "Check", xpamount)
        VALUES (6, 10, 100);

select * from xp where "Check" = 10