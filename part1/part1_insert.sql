INSERT INTO Peers (Nickname, Birthday) VALUES
 ('mvazvelhwy', '2011/05/23'),
 ('iosfiypdje', '2005/05/01'),
 ('wbbmjueeye', '1995/05/06'),
 ('wsiwgwornx', '1998/11/22'),
 ('prbedzugjq', '1990/09/23'),
 ('azovbzwucs', '2002/08/08');

INSERT INTO Tasks (Title, ParentTask, MaxXP) VALUES
 ('C3_SimpleBashUtils', Null, 151),
 ('CPP1_s21_matrixplus', 'C3_SimpleBashUtils', 268),
 ('DO1_Linux', 'CPP1_s21_matrixplus', 733),
 ('DO2_Linux Network', 'DO1_Linux', 720),
 ('DO5_SimpleDocker', 'DO2_Linux Network', 775);

INSERT INTO Checks (ID, Peer, Task, Date) VALUES 
 (1, 'mvazvelhwy', 'DO5_SimpleDocker', '2022/03/05'),
 (2, 'wbbmjueeye', 'CPP1_s21_matrixplus', '2021/04/04'),
 (3, 'wbbmjueeye', 'C3_SimpleBashUtils', '2022/06/30'),
 (4, 'wbbmjueeye', 'CPP1_s21_matrixplus', '2021/03/31'),
 (5, 'azovbzwucs', 'DO1_Linux', '2022/07/16'),
 (6, 'mvazvelhwy', 'CPP1_s21_matrixplus', '2005/05/01'),
 (7, 'prbedzugjq', 'CPP1_s21_matrixplus', '1990/09/23'),
 (8, 'iosfiypdje', 'C3_SimpleBashUtils', '2002/08/08'),
 (9, 'mvazvelhwy', 'DO1_Linux', '2022/03/05');

INSERT INTO P2P (id, "Check", CheckingPeer, State, Time) VALUES
 (1, 1, 'iosfiypdje', 'Start', '06:36:32'),
 (2, 1, 'iosfiypdje', 'Success', '14:51:06'),
 (3, 2, 'iosfiypdje', 'Start', '14:43:44'),
 (4, 2, 'iosfiypdje', 'Success', '22:37:00'),
 (5, 3, 'prbedzugjq', 'Start', '02:38:53'),
 (6, 3, 'prbedzugjq', 'Success', '10:45:21'),
 (7, 4, 'iosfiypdje', 'Start', '09:15:31'),
 (8, 4, 'iosfiypdje', 'Success', '10:11:00'),
 (9, 5, 'prbedzugjq', 'Start', '11:20:00'),
 (10, 5, 'prbedzugjq', 'Success', '15:30:00'),
 (11, 6, 'wsiwgwornx', 'Start', '13:10:00'),
 (12, 6, 'wsiwgwornx', 'Success', '17:45:00'),
 (13, 7, 'iosfiypdje', 'Start', '08:30:00'),
 (14, 7, 'iosfiypdje', 'Failure', '12:40:00'),
 (15, 8, 'azovbzwucs', 'Start', '10:00:00'),
 (16, 8, 'azovbzwucs', 'Success', '14:15:00'),
 (17, 9, 'iosfiypdje', 'Start', '16:20:00'),
 (18, 9, 'iosfiypdje', 'Failure', '20:30:00');

INSERT INTO Verter (ID, "Check", State, Time) VALUES
 (1, 1, 'Start', '04:20:18'),
 (2, 1, 'Success', '08:53:48'),
 (3, 2, 'Start', '09:29:40'),
 (4, 2, 'Success', '18:40:43'),
 (5, 3, 'Start', '17:47:22'),
 (6, 6, 'Start', '04:20:18'),
 (7, 6, 'Success', '20:04:08'),
 (8, 7, 'Start', '19:41:49'),
 (9, 7, 'Success', '20:44:38'),
 (10, 8, 'Start', '19:41:49'),
 (11, 8, 'Failure', '20:44:38'),
 (12, 9, 'Start', '14:20:18'),
 (13, 9, 'Failure', '18:53:48');

INSERT INTO TransferredPoints (ID, CheckingPeer, CheckedPeer, PointsAmount) VALUES
 (1, 'iosfiypdje', 'mvazvelhwy', 2),
 (2, 'wbbmjueeye', 'mvazvelhwy', 1),
 (3, 'iosfiypdje', 'wsiwgwornx', 3),
 (4, 'prbedzugjq', 'wsiwgwornx', 1),
 (5, 'iosfiypdje', 'prbedzugjq', 1);
 
INSERT INTO Friends (ID, Peer1, Peer2) VALUES
 (1, 'iosfiypdje', 'mvazvelhwy'),
 (2, 'wbbmjueeye', 'mvazvelhwy'),
 (3, 'prbedzugjq', 'iosfiypdje'),
 (4, 'prbedzugjq', 'wsiwgwornx'),
 (5, 'wsiwgwornx', 'wbbmjueeye'),
 (6, 'azovbzwucs', 'iosfiypdje'),
 (7, 'azovbzwucs', 'mvazvelhwy');

INSERT INTO Recommendations (ID, Peer, RecommendedPeer) VALUES
 (1, 'mvazvelhwy', 'azovbzwucs'),
 (2, 'azovbzwucs', 'mvazvelhwy'),
 (3, 'prbedzugjq', 'iosfiypdje'),
 (4, 'iosfiypdje', 'mvazvelhwy'),
 (5, 'azovbzwucs', 'wbbmjueeye'),
 (6, 'iosfiypdje', 'azovbzwucs'),
 (7, 'mvazvelhwy', 'azovbzwucs'),
 (8, 'iosfiypdje', 'prbedzugjq');
 
INSERT INTO XP (ID, "Check", XPAmount) VALUES
 (1, 1, 649),
 (2, 2, 40),
 (3, 3, 30),
 (4, 4, 260),
 (5, 1, 244);

INSERT INTO TimeTracking (ID, Peer, Date, Time, State) VALUES
 (1, 'mvazvelhwy', '2021/06/26', '05:43:00', 1),
 (2, 'mvazvelhwy', '2021/06/26', '18:08:25', 2),
 (3, 'mvazvelhwy', '2021/06/26', '20:31:23', 1),
 (4, 'mvazvelhwy', '2021/06/26', '21:57:49', 2),
 (5, 'azovbzwucs', '2022/03/06', '20:13:39', 1),
 (6, 'azovbzwucs', '2022/03/06', '20:54:33', 2),
 (7, 'prbedzugjq', '2023/03/20', '09:36:00', 1),
 (8, 'iosfiypdje', '2025/02/26', '08:44:00', 1),
 (9, 'iosfiypdje', '2025/02/26', '18:47:00', 2),
 (10, 'iosfiypdje', '2025/03/12', '13:40:00', 1),
 (11, 'iosfiypdje', '2025/03/12', '20:21:00', 2);