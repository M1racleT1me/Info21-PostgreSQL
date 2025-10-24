CREATE TABLE Peers(
	Nickname VARCHAR PRIMARY KEY,
	Birthday DATE NOT NULL
);

CREATE TABLE Tasks(
	Title VARCHAR PRIMARY KEY,
	ParentTask VARCHAR DEFAULT NULL,
	FOREIGN KEY (ParentTask) REFERENCES Tasks(Title),
	MaxXP BIGINT NOT NULL,
	CHECK (MaxXP > 0)
);

CREATE TYPE check_status AS ENUM ('Start','Success','Failure');

CREATE TABLE P2P(
	ID BIGINT PRIMARY KEY,
	"Check" BIGINT,
	CheckingPeer VARCHAR,
	FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
	State check_status,
	Time TIME
);

CREATE TABLE Verter(
	ID BIGINT PRIMARY KEY,
	"Check" BIGINT,
	State check_status,
	Time TIME
);

CREATE TABLE Checks(
	ID BIGINT PRIMARY KEY,
	Peer VARCHAR,
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	Task VARCHAR,
	FOREIGN KEY (Task) REFERENCES Tasks(Title),
	Date DATE
);

ALTER TABLE P2P ADD CONSTRAINT fk_p2p_checks 
FOREIGN KEY ("Check") REFERENCES Checks(ID);

ALTER TABLE Verter ADD CONSTRAINT fk_verter_checks
FOREIGN KEY ("Check") REFERENCES Checks(ID);

CREATE TABLE TransferredPoints(
	ID BIGINT PRIMARY KEY,
	CheckingPeer VARCHAR,
	FOREIGN KEY (CheckingPeer) REFERENCES Peers(Nickname),
	CheckedPeer VARCHAR,
	CHECK (CheckingPeer != CheckedPeer),
	FOREIGN KEY (CheckedPeer) REFERENCES Peers(Nickname),
	PointsAmount INTEGER
);

CREATE TABLE Friends(
	ID BIGINT PRIMARY KEY,
	Peer1 VARCHAR NOT NULL,
	FOREIGN KEY (Peer1) REFERENCES Peers(Nickname),
	Peer2 VARCHAR NOT NULL,
	FOREIGN KEY (Peer2) REFERENCES Peers(Nickname)
);

CREATE TABLE Recommendations(
	ID BIGINT PRIMARY KEY,
	Peer VARCHAR,
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname),
	RecommendedPeer VARCHAR,
	FOREIGN KEY (RecommendedPeer) REFERENCES Peers(Nickname)
);

CREATE TABLE XP(
	ID BIGINT PRIMARY KEY,
	"Check" BIGINT,
	XPAmount INTEGER,
	CHECK (XPAmount >= 0),
	CONSTRAINT fk_xp_checks FOREIGN KEY ("Check") REFERENCES Checks(ID)
);

CREATE TABLE TimeTracking(
	ID BIGINT PRIMARY KEY,
	Peer VARCHAR,
	Date DATE,
	Time TIME,
	State BIGINT,
	CHECK (State IN (1, 2)),
	FOREIGN KEY (Peer) REFERENCES Peers(Nickname)
);
