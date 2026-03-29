const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();

// All seance routes are protected by JWT
router.use(auth);

/**
 * GET /api/seances
 * Returns all sessions, joined with module and filière names.
 * Optional query params:
 *   ?date=YYYY-MM-DD      → filter by date
 *   ?id_prof=1            → filter by professor (optional extra filter)
 */
router.get('/', async (req, res) => {
    const { date, id_prof } = req.query;

    let sql = `
    SELECT
      s.id_seance,
      DATE_FORMAT(s.date_seance, '%Y-%m-%d') AS date_seance,
      TIME_FORMAT(s.heure_debut, '%H:%i')    AS heure_debut,
      TIME_FORMAT(s.heure_fin,   '%H:%i')    AS heure_fin,
      s.id_prof,
      s.id_module,
      s.id_filiere,
      m.nom_module,
      f.nom_filiere,
      CONCAT(p.prenom, ' ', p.nom) AS nom_prof
    FROM Seance s
    JOIN Module      m ON m.id_module   = s.id_module
    JOIN Filiere     f ON f.id_filiere  = s.id_filiere
    JOIN Professeur  p ON p.id_prof     = s.id_prof
    WHERE 1=1
  `;
    const params = [];

    if (date) {
        sql += ' AND s.date_seance = ?';
        params.push(date);
    }
    if (id_prof) {
        sql += ' AND s.id_prof = ?';
        params.push(id_prof);
    }

    sql += ' ORDER BY s.date_seance DESC, s.heure_debut ASC';

    try {
        const [rows] = await db.execute(sql, params);
        return res.json(rows);
    } catch (err) {
        console.error('GET /seances error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * GET /api/seances/metadata
 * Returns available modules and filieres for creating a seance
 */
router.get('/metadata', async (req, res) => {
    try {
        const [modules] = await db.execute('SELECT * FROM Module');
        const [filieres] = await db.execute('SELECT * FROM Filiere');
        return res.json({ modules, filieres });
    } catch (err) {
        console.error('GET /seances/metadata error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * POST /api/seances
 * Body: { date_seance, heure_debut, heure_fin, id_module, id_filiere }
 * Creates a new session using the authenticated prof's ID.
 */
router.post('/', async (req, res) => {
    try {
        const { date_seance, heure_debut, heure_fin, id_module, id_filiere } = req.body;
        
        if (!date_seance || !heure_debut || !heure_fin || !id_module || !id_filiere) {
            return res.status(400).json({ message: 'Tous les champs sont requis.' });
        }

        const [result] = await db.execute(
            `INSERT INTO Seance (date_seance, heure_debut, heure_fin, id_prof, id_module, id_filiere)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [date_seance, heure_debut, heure_fin, req.user.id_prof, id_module, id_filiere]
        );

        return res.status(201).json({ 
            message: 'Séance créée avec succès.',
            id_seance: result.insertId 
        });
    } catch (err) {
        console.error('POST /seances error:', err);
        return res.status(500).json({ message: 'Erreur serveur lors de la création.' });
    }
});

/**
 * GET /api/seances/:id
 * Returns a single session by id.
 */
router.get('/:id', async (req, res) => {
    try {
        const [rows] = await db.execute(
            `SELECT s.*, m.nom_module, f.nom_filiere,
              CONCAT(p.prenom, ' ', p.nom) AS nom_prof
       FROM Seance s
       JOIN Module     m ON m.id_module  = s.id_module
       JOIN Filiere    f ON f.id_filiere = s.id_filiere
       JOIN Professeur p ON p.id_prof    = s.id_prof
       WHERE s.id_seance = ?`,
            [req.params.id]
        );
        if (rows.length === 0) {
            return res.status(404).json({ message: 'Séance introuvable.' });
        }
        return res.json(rows[0]);
    } catch (err) {
        console.error('GET /seances/:id error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

module.exports = router;
