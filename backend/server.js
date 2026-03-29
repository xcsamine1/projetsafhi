/**
 * Express server entry point for the Attendance Management API.
 * 
 * Start with:
 *   npm run dev   (development, with auto-reload)
 *   npm start     (production)
 */

require('dotenv').config();

const express = require('express');
const cors = require('cors');

// Route handlers
const authRoutes = require('./routes/auth');
const seancesRoutes = require('./routes/seances');
const etudiantsRoutes = require('./routes/etudiants');
const presenceRoutes = require('./routes/presence');

const app = express();
const PORT = process.env.PORT || 8080;

// ─── Middleware ────────────────────────────────────────────────────────────────

// Allow all origins (restrict in production)
app.use(cors());

// Parse JSON request bodies
app.use(express.json());

// Request logger (useful for development)
app.use((req, _res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// ─── Routes ───────────────────────────────────────────────────────────────────

app.use('/api/auth', authRoutes);
app.use('/api/seances', seancesRoutes);
app.use('/api/etudiants', etudiantsRoutes);
app.use('/api/presence', presenceRoutes);
app.use('/api/filieres', require('./routes/filieres'));

// Health check
app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── 404 handler ──────────────────────────────────────────────────────────────

app.use((_req, res) => {
    res.status(404).json({ message: 'Route introuvable.' });
});

// ─── Global error handler ─────────────────────────────────────────────────────

app.use((err, _req, res, _next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ message: 'Erreur serveur interne.' });
});

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
    console.log(`📋 Health check: http://localhost:${PORT}/api/health`);
});
