CREATE OR REPLACE PROCEDURE pr_import_from_csv(table_name TEXT, csv_file_path TEXT, delimiter CHAR(1))
LANGUAGE plpgsql AS
$$
BEGIN
    EXECUTE format('COPY %s TO %L WITH CSV HEADER DELIMITER %L', table_name, csv_file_path, delimiter);
END;
$$;

SET dataset_path.const TO '/opt/goinfre/ultronip/SQL2_Info21_v1.0-2/src/dataset_sql/export/';
SET datestyle = 'ISO, DMY';

CALL pr_import_from_csv('peers', current_setting('dataset_path.const')||'peers.csv', ';');
CALL pr_import_from_csv('tasks', current_setting('dataset_path.const')||'tasks.csv', ';');
CALL pr_import_from_csv('checks', current_setting('dataset_path.const')||'checks.csv', ';');
CALL pr_import_from_csv('friends', current_setting('dataset_path.const')||'friends.csv', ';');
CALL pr_import_from_csv('p2p', current_setting('dataset_path.const')||'P2P.csv', ';');
CALL pr_import_from_csv('recommendations', current_setting('dataset_path.const')||'recommendations.csv', ';');
CALL pr_import_from_csv('timetracking', current_setting('dataset_path.const')||'time_tracking.csv', ';');
CALL pr_import_from_csv('transferredpoints', current_setting('dataset_path.const')||'transferred_points.csv', ';');
CALL pr_import_from_csv('verter', current_setting('dataset_path.const')||'verter.csv', ';');
CALL pr_import_from_csv('xp', current_setting('dataset_path.const')||'xp.csv', ';');
