const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();
router.use(auth);

/**
 * GET /api/filieres
 * Returns all filières.
 */
router.get('/', async (_req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM Filiere ORDER BY nom_filiere');
        return res.json(rows);
    } catch (err) {
        console.error('GET /filieres error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * POST /api/filieres
 * Body: { nom_filiere }
 * Creates a new filiere in the system.
 */
router.post('/', async (req, res) => {
    try {
        const { nom_filiere } = req.body;
        
        if (!nom_filiere || nom_filiere.trim().length === 0) {
            return res.status(400).json({ message: 'Le nom de la filière est requis.' });
        }

        const [result] = await db.execute(
            `INSERT INTO Filiere (nom_filiere) VALUES (?)`,
            [nom_filiere.trim()]
        );

        return res.status(201).json({ 
            message: 'Filière créée avec succès.',
            id_filiere: result.insertId 
        });
    } catch (err) {
        console.error('POST /filieres error:', err);
        return res.status(500).json({ message: 'Erreur serveur lors de la création de la filière.' });
    }
});

/**
 * DELETE /api/filieres/:id
 * Deletes a filière. Fails if students or seances are linked.
 */
router.delete('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const [students] = await db.execute(
            'SELECT COUNT(*) as count FROM Etudiant WHERE id_filiere = ?', [id]
        );
        if (students[0].count > 0) {
            return res.status(409).json({
                message: `Impossible de supprimer : ${students[0].count} étudiant(s) appartiennent à cette filière.`
            });
        }

        const [seances] = await db.execute(
            'SELECT COUNT(*) as count FROM Seance WHERE id_filiere = ?', [id]
        );
        if (seances[0].count > 0) {
            return res.status(409).json({
                message: `Impossible de supprimer : ${seances[0].count} séance(s) sont liées à cette filière.`
            });
        }

        const [result] = await db.execute('DELETE FROM Filiere WHERE id_filiere = ?', [id]);
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Filière introuvable.' });
        }
        return res.json({ message: 'Filière supprimée avec succès.' });
    } catch (err) {
        console.error('DELETE /filieres/:id error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

module.exports = router;

