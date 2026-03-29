const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();
router.use(auth);

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

module.exports = router;
