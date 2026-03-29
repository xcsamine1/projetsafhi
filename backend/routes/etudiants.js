const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();
router.use(auth);

/**
 * GET /api/etudiants/byFiliere/:id_filiere
 * Returns all students belonging to a filière.
 */
router.get('/byFiliere/:id_filiere', async (req, res) => {
    const { id_filiere } = req.params;

    try {
        const [rows] = await db.execute(
            `SELECT e.id_etudiant, e.nom, e.prenom, e.id_filiere, f.nom_filiere
       FROM Etudiant e
       JOIN Filiere f ON f.id_filiere = e.id_filiere
       WHERE e.id_filiere = ?
       ORDER BY e.nom, e.prenom`,
            [id_filiere]
        );
        return res.json(rows);
    } catch (err) {
        console.error('GET /etudiants/byFiliere error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * GET /api/etudiants
 * Returns all students (optionally used by admin).
 */
router.get('/', async (req, res) => {
    try {
        const [rows] = await db.execute(
            `SELECT e.*, f.nom_filiere
       FROM Etudiant e
       JOIN Filiere f ON f.id_filiere = e.id_filiere
       ORDER BY e.nom, e.prenom`
        );
        return res.json(rows);
    } catch (err) {
        console.error('GET /etudiants error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * POST /api/etudiants
 * Body: { nom, prenom, id_filiere }
 * Creates a new student in the system.
 */
router.post('/', async (req, res) => {
    try {
        const { nom, prenom, id_filiere } = req.body;
        
        if (!nom || !prenom || !id_filiere) {
            return res.status(400).json({ message: 'Tous les champs (nom, prenom, id_filiere) sont requis.' });
        }

        const [result] = await db.execute(
            `INSERT INTO Etudiant (nom, prenom, id_filiere) VALUES (?, ?, ?)`,
            [nom.trim(), prenom.trim(), id_filiere]
        );

        return res.status(201).json({ 
            message: 'Étudiant créé avec succès.',
            id_etudiant: result.insertId 
        });
    } catch (err) {
        console.error('POST /etudiants error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

module.exports = router;
