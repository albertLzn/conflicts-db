-- Supprime la base si elle existe déjà
DROP DATABASE IF EXISTS conflicts_db;

-- Crée la base de données
CREATE DATABASE conflicts_db;
USE conflicts_db;

-- Crée un utilisateur avec mot de passe
CREATE USER IF NOT EXISTS 'game_user'@'localhost' IDENTIFIED BY 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON conflicts_db.* TO 'game_user'@'localhost';
FLUSH PRIVILEGES;

-- Création des tables
CREATE TABLE Players (
    PlayerID BIGINT PRIMARY KEY,
    Username VARCHAR(32) UNIQUE NOT NULL,
    AllianceID BIGINT,
    LastLogin TIMESTAMP,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Resources JSON,
    Position JSON,
    Level INT DEFAULT 1,
    Experience INT DEFAULT 0,
    Buildings JSON,
    Professions JSON
);

CREATE TABLE HeroTemplates (
    TemplateID BIGINT PRIMARY KEY,
    Name VARCHAR(32),
    Rarity INT, -- Nombre d'étoiles
    BaseStats JSON, -- {force, intelligence, defense, agilite}
    UniqueSkill JSON, -- {name, description, effects}
    AwakeningBonus JSON, -- Stats bonus en état éveillé
    ScalingPerLevel JSON -- {force, intelligence, defense, agilite}
);

CREATE TABLE Heroes (
    HeroID BIGINT PRIMARY KEY,
    PlayerID BIGINT REFERENCES Players(PlayerID),
    TemplateID BIGINT REFERENCES HeroTemplates(TemplateID),
    Level INT DEFAULT 1,
    Experience INT DEFAULT 0,
    CurrentEndurance INT DEFAULT 120,
    IsAwakened BOOLEAN DEFAULT FALSE,
    Advancement INT DEFAULT 0, -- Nombre d'emblèmes utilisés
    Status VARCHAR(32), -- AVAILABLE, IN_LEGION, WOUNDED
    WoundedUntil TIMESTAMP,
    TalentPoints JSON, -- {command: points, economy: points, pvp: points}
    TalentTree JSON, -- {command: [{skill, level}], economy: [...], pvp: [...]}
    EquippedSkills JSON, -- [skill1_id, skill2_id]
    CurrentStats JSON -- Stats actuelles avec bonus
);

CREATE TABLE Legions (
    LegionID BIGINT PRIMARY KEY,
    PlayerID BIGINT REFERENCES Players(PlayerID),
    Name VARCHAR(32),
    Heroes JSON, 
    Units JSON,
    Position JSON,
    CurrentOrder JSON,
    Status VARCHAR(32) -- MARCHING, FIGHTING, STATIONED
);

-- Table pour les skills génériques que les héros peuvent équiper
CREATE TABLE Skills (
    SkillID BIGINT PRIMARY KEY,
    Name VARCHAR(32),
    Description TEXT,
    Effects JSON,
    Requirements JSON -- Niveau minimum, etc
);
CREATE TABLE Alliances (
    AllianceID BIGINT PRIMARY KEY,
    Name VARCHAR(32) UNIQUE NOT NULL,
    LeaderID BIGINT REFERENCES Players(PlayerID),
    Level INT DEFAULT 1,
    Experience INT DEFAULT 0,
    Territory JSON,
    TotalPoints INT DEFAULT 0,
    Members JSON,
    AllyAlliances JSON,
    EnemyAlliances JSON,
    Diplomacy JSON,
    Technologies JSON,
    Treasury JSON
);

CREATE TABLE Cities (
    CityID BIGINT PRIMARY KEY,
    Name VARCHAR(32) NOT NULL,
    OwnerID BIGINT REFERENCES Players(PlayerID),
    AllianceID BIGINT REFERENCES Alliances(AllianceID),
    CountID BIGINT,
    Position JSON,
    Level INT DEFAULT 1,
    Population INT DEFAULT 0,
    Residents JSON,
    Buildings JSON,
    Resources JSON,
    Defense JSON,
    Trade JSON
);

CREATE TABLE Battles (
    BattleID BIGINT PRIMARY KEY,
    Location JSON,
    StartTime TIMESTAMP,
    EndTime TIMESTAMP,
    AttackerID BIGINT REFERENCES Players(PlayerID),
    DefenderID BIGINT REFERENCES Players(PlayerID),
    Units JSON,
    Result JSON,
    Type VARCHAR(32)
);

CREATE TABLE Shops (
    ShopID BIGINT PRIMARY KEY,
    OwnerID BIGINT REFERENCES Players(PlayerID),
    CityID BIGINT REFERENCES Cities(CityID),
    Type VARCHAR(32),
    Level INT DEFAULT 1,
    Inventory JSON,
    Prices JSON,
    Status VARCHAR(32)
);

CREATE TABLE Transactions (
    TransactionID BIGINT PRIMARY KEY,
    ShopID BIGINT REFERENCES Shops(ShopID),
    BuyerID BIGINT REFERENCES Players(PlayerID),
    SellerID BIGINT REFERENCES Players(PlayerID),
    Items JSON,
    Amount INT,
    TransactionTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Création des index
CREATE INDEX idx_players_alliance ON Players(AllianceID);
CREATE INDEX idx_heroes_player ON Heroes(PlayerID);
CREATE INDEX idx_legions_player ON Legions(PlayerID);
CREATE INDEX idx_cities_alliance ON Cities(AllianceID);
CREATE INDEX idx_shops_city ON Shops(CityID);