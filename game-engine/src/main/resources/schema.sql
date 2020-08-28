CREATE TABLE IF NOT EXISTS SCORES(
  playerId VARCHAR (250) PRIMARY KEY,
  score INT,
  progression INT,
  devPoint INT,
  secPoint INT,
  opsPoint INT
);

CREATE TABLE IF NOT EXISTS PLAYERS_INFO(
  id VARCHAR (250) PRIMARY KEY,
  token VARCHAR (250),
  cloud9URL VARCHAR (250),
  awsAccountId VARCHAR (250),
  login VARCHAR (250),
  password VARCHAR (250),
  sshKey VARCHAR (5000)
);
