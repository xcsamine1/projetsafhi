const express = require('express');
const db = require('../config/db');
const auth = require('../middleware/auth');

const router = express.Router();
router.use(auth);

// Valid statut values (mirrors the MySQL ENUM)
const VALID_STATUTS = ['Present', 'Absent', 'Retard', 'Justifie'];

/**
 * GET /api/presence/:id_seance
 * Returns all attendance records for a given session.
 */
router.get('/:id_seance', async (req, res) => {
    const { id_seance } = req.params;

    try {
        const [rows] = await db.execute(
            `SELECT p.id_presence, p.id_seance, p.id_etudiant,
              p.statut, p.commentaire,
              e.nom, e.prenom
       FROM Presence p
       JOIN Etudiant e ON e.id_etudiant = p.id_etudiant
       WHERE p.id_seance = ?
       ORDER BY e.nom, e.prenom`,
            [id_seance]
        );
        return res.json(rows);
    } catch (err) {
        console.error('GET /presence/:id_seance error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * POST /api/presence
 * Create a new attendance record.
 * Body: { id_seance, id_etudiant, statut, commentaire? }
 */
router.post('/', async (req, res) => {
    const { id_seance, id_etudiant, statut, commentaire } = req.body;

    // Validation
    if (!id_seance || !id_etudiant || !statut) {
        return res.status(400).json({ message: 'id_seance, id_etudiant et statut sont requis.' });
    }
    if (!VALID_STATUTS.includes(statut)) {
        return res.status(400).json({
            message: `Statut invalide. Valeurs acceptées: ${VALID_STATUTS.join(', ')}`
        });
    }

    try {
        const [result] = await db.execute(
            `INSERT INTO Presence (id_seance, id_etudiant, statut, commentaire)
       VALUES (?, ?, ?, ?)`,
            [id_seance, id_etudiant, statut, commentaire || null]
        );

        // Return the new record
        const [rows] = await db.execute(
            'SELECT * FROM Presence WHERE id_presence = ?',
            [result.insertId]
        );
        return res.status(201).json(rows[0]);
    } catch (err) {
        // Duplicate entry (unique constraint on id_seance + id_etudiant)
        if (err.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Un enregistrement existe déjà pour cet étudiant dans cette séance. Utilisez PUT pour mettre à jour.'
            });
        }
        console.error('POST /presence error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * PUT /api/presence/:id
 * Update an existing attendance record.
 * Body: { statut?, commentaire? }
 */
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    const { statut, commentaire } = req.body;

    if (statut && !VALID_STATUTS.includes(statut)) {
        return res.status(400).json({
            message: `Statut invalide. Valeurs acceptées: ${VALID_STATUTS.join(', ')}`
        });
    }

    try {
        // Check it exists
        const [existing] = await db.execute(
            'SELECT * FROM Presence WHERE id_presence = ?',
            [id]
        );
        if (existing.length === 0) {
            return res.status(404).json({ message: 'Enregistrement introuvable.' });
        }

        // Build update query dynamically
        const updates = [];
        const params = [];

        if (statut !== undefined) {
            updates.push('statut = ?');
            params.push(statut);
        }
        if (commentaire !== undefined) {
            updates.push('commentaire = ?');
            params.push(commentaire);
        }

        if (updates.length === 0) {
            return res.status(400).json({ message: 'Aucun champ à mettre à jour.' });
        }

        params.push(id);
        await db.execute(
            `UPDATE Presence SET ${updates.join(', ')} WHERE id_presence = ?`,
            params
        );

        // Return updated record
        const [rows] = await db.execute(
            'SELECT * FROM Presence WHERE id_presence = ?',
            [id]
        );
        return res.json(rows[0]);
    } catch (err) {
        console.error('PUT /presence/:id error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * DELETE /api/presence/:id
 * Remove an attendance record.
 */
router.delete('/:id', async (req, res) => {
    try {
        const [result] = await db.execute(
            'DELETE FROM Presence WHERE id_presence = ?',
            [req.params.id]
        );
        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Enregistrement introuvable.' });
        }
        return res.json({ message: 'Supprimé avec succès.' });
    } catch (err) {
        console.error('DELETE /presence/:id error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

module.exports = router;
