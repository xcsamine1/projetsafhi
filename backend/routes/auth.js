const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const router = express.Router();

/**
 * POST /api/auth/register
 * Body: { nom, prenom, email, password }
 */
router.post('/register', async (req, res) => {
    const { nom, prenom, email, password } = req.body;

    if (!nom || !prenom || !email || !password) {
        return res.status(400).json({ message: 'Tous les champs sont requis (nom, prenom, email, password).' });
    }

    try {
        // Check if email already exists
        const [existing] = await db.execute('SELECT id_prof FROM Professeur WHERE email = ?', [email]);
        if (existing.length > 0) {
            return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Insert into database
        const [result] = await db.execute(
            'INSERT INTO Professeur (nom, prenom, email, password) VALUES (?, ?, ?, ?)',
            [nom, prenom, email, hashedPassword]
        );

        return res.status(201).json({
            message: 'Professeur créé avec succès.',
            professeurId: result.insertId
        });
    } catch (err) {
        console.error('Register error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

/**
 * POST /api/auth/login
 * Body: { email, password }
 * Returns: { token, professeur }
 */
router.post('/login', async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: 'Email et mot de passe requis.' });
    }

    try {
        // Find professor by email
        const [rows] = await db.execute(
            'SELECT * FROM Professeur WHERE email = ?',
            [email]
        );

        if (rows.length === 0) {
            return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
        }

        const prof = rows[0];

        // Verify password (bcrypt)
        const isValid = await bcrypt.compare(password, prof.password);
        if (!isValid) {
            return res.status(401).json({ message: 'Email ou mot de passe incorrect.' });
        }

        // Sign JWT
        const token = jwt.sign(
            { id_prof: prof.id_prof, email: prof.email },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        // Return token + professor (without password)
        return res.json({
            token,
            professeur: {
                id_prof: prof.id_prof,
                nom: prof.nom,
                prenom: prof.prenom,
                email: prof.email,
            },
        });
    } catch (err) {
        console.error('Login error:', err);
        return res.status(500).json({ message: 'Erreur serveur.' });
    }
});

module.exports = router;
