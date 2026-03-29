const express = require('express');
const jwt = require('jsonwebtoken');

const router = express.Router();

/**
 * JWT Authentication Middleware
 * 
 * Reads the 'Authorization: Bearer <token>' header,
 * verifies the JWT signature, and attaches the decoded
 * payload to `req.user` for downstream handlers.
 * 
 * Usage: router.use(auth) — protects all routes in a router.
 */
const auth = (req, res, next) => {
    const header = req.headers['authorization'];

    // Header must be: "Bearer <token>"
    if (!header || !header.startsWith('Bearer ')) {
        return res.status(401).json({ message: 'Jeton d\'authentification manquant.' });
    }

    const token = header.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        // Attach professor id + email to request for use in route handlers
        req.user = decoded;
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ message: 'Session expirée. Veuillez vous reconnecter.' });
        }
        return res.status(401).json({ message: 'Jeton invalide.' });
    }
};

module.exports = auth;
