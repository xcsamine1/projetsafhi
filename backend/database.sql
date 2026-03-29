-- =============================================================
--  Attendance Management Database Schema + Seed Data
--  Compatible with: MySQL 8+ / MariaDB 10.4+
-- =============================================================

CREATE DATABASE IF NOT EXISTS attendance_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE attendance_db;

-- ─── Tables ───────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS Filiere (
  id_filiere   INT AUTO_INCREMENT PRIMARY KEY,
  nom_filiere  VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS Professeur (
  id_prof   INT AUTO_INCREMENT PRIMARY KEY,
  nom       VARCHAR(100) NOT NULL,
  prenom    VARCHAR(100) NOT NULL,
  email     VARCHAR(150) NOT NULL UNIQUE,
  password  VARCHAR(255) NOT NULL   -- bcrypt hash
);

CREATE TABLE IF NOT EXISTS Module (
  id_module   INT AUTO_INCREMENT PRIMARY KEY,
  nom_module  VARCHAR(150) NOT NULL
);

CREATE TABLE IF NOT EXISTS Etudiant (
  id_etudiant  INT AUTO_INCREMENT PRIMARY KEY,
  nom          VARCHAR(100) NOT NULL,
  prenom       VARCHAR(100) NOT NULL,
  id_filiere   INT NOT NULL,
  FOREIGN KEY (id_filiere) REFERENCES Filiere(id_filiere)
);

CREATE TABLE IF NOT EXISTS Seance (
  id_seance    INT AUTO_INCREMENT PRIMARY KEY,
  date_seance  DATE NOT NULL,
  heure_debut  TIME NOT NULL,
  heure_fin    TIME NOT NULL,
  id_prof      INT NOT NULL,
  id_module    INT NOT NULL,
  id_filiere   INT NOT NULL,
  FOREIGN KEY (id_prof)    REFERENCES Professeur(id_prof),
  FOREIGN KEY (id_module)  REFERENCES Module(id_module),
  FOREIGN KEY (id_filiere) REFERENCES Filiere(id_filiere)
);

CREATE TABLE IF NOT EXISTS Presence (
  id_presence  INT AUTO_INCREMENT PRIMARY KEY,
  id_seance    INT NOT NULL,
  id_etudiant  INT NOT NULL,
  statut       ENUM('Present','Absent','Retard','Justifie') NOT NULL DEFAULT 'Absent',
  commentaire  TEXT,
  FOREIGN KEY (id_seance)   REFERENCES Seance(id_seance),
  FOREIGN KEY (id_etudiant) REFERENCES Etudiant(id_etudiant),
  UNIQUE KEY uq_seance_etudiant (id_seance, id_etudiant)
);

-- ─── Seed Data ────────────────────────────────────────────────────────────────

INSERT INTO Filiere (nom_filiere) VALUES
  ('Informatique L1'),
  ('Informatique L2'),
  ('Mathématiques L1');

-- Password for all test professors: "password123"
-- bcrypt hash generated with 10 rounds
INSERT INTO Professeur (nom, prenom, email, password) VALUES
  ('Benali',  'Ahmed',  'ahmed.benali@univ.ma',   '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'),
  ('Laroui',  'Karima', 'karima.laroui@univ.ma',  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy');

INSERT INTO Module (nom_module) VALUES
  ('Algorithmique'),
  ('Base de Données'),
  ('Réseaux Informatiques'),
  ('Mathématiques Discrètes');

INSERT INTO Etudiant (nom, prenom, id_filiere) VALUES
  -- Filière 1
  ('Bouazza',  'Karim',   1),
  ('Laroui',   'Sara',    1),
  ('Amrani',   'Youssef', 1),
  ('Tazi',     'Nadia',   1),
  ('Chraibi',  'Omar',    1),
  ('Bensalem', 'Fatima',  1),
  -- Filière 2
  ('Ouali',    'Hassan',  2),
  ('Naciri',   'Leila',   2),
  ('Berrada',  'Amine',   2),
  ('Fassi',    'Rim',     2),
  -- Filière 3
  ('Sekkat',   'Mehdi',   3),
  ('Alami',    'Zineb',   3);

INSERT INTO Seance (date_seance, heure_debut, heure_fin, id_prof, id_module, id_filiere) VALUES
  (CURDATE(),              '08:00:00', '10:00:00', 1, 1, 1),
  (CURDATE(),              '10:00:00', '12:00:00', 1, 2, 2),
  (DATE_SUB(CURDATE(), INTERVAL 1 DAY), '14:00:00', '16:00:00', 1, 3, 1),
  (DATE_ADD(CURDATE(), INTERVAL 1 DAY), '08:00:00', '10:00:00', 1, 1, 3);

INSERT INTO Presence (id_seance, id_etudiant, statut) VALUES
  (1, 1, 'Present'),
  (1, 2, 'Absent'),
  (1, 3, 'Retard'),
  (1, 4, 'Justifie'),
  (1, 5, 'Present');
