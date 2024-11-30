const express = require('express');
const mysql = require('mysql');
const WebSocket = require('ws');
const app = express();

// Configuration DB
const db = mysql.createPool({
    host: 'localhost',
    user: 'root',
    password: 'votre_mot_de_passe',
    database: 'mon_jeu_db',
    connectionLimit: 100
});

// Middleware pour parser le JSON
app.use(express.json());

// Gestionnaire WebSocket pour les actions en temps réel
const wss = new WebSocket.Server({ port: 8080 });

// Map pour garder trace des connexions actives
const activeConnections = new Map();

wss.on('connection', (ws, req) => {
    const playerId = req.headers['player-id'];
    activeConnections.set(playerId, ws);

    ws.on('message', async (message) => {
        const data = JSON.parse(message);
        
        switch(data.type) {
            case 'MOVE_LEGION':
                handleLegionMovement(data, ws);
                break;
            case 'START_BATTLE':
                handleBattle(data, ws);
                break;
            case 'ALLIANCE_ACTION':
                handleAllianceAction(data, ws);
                break;
            // Autres cas...
        }
    });

    ws.on('close', () => {
        activeConnections.delete(playerId);
    });
});

// Exemple de gestionnaire de mouvement de légion
async function handleLegionMovement(data, ws) {
    try {
        const query = `
            UPDATE Legions 
            SET Position = ?, 
                Status = 'MARCHING' 
            WHERE LegionID = ? AND PlayerID = ?
        `;
        
        db.query(query, [
            JSON.stringify(data.newPosition),
            data.legionId,
            data.playerId
        ]);

        // Notifier les joueurs proches
        broadcastToNearbyPlayers(data);
    } catch (error) {
        ws.send(JSON.stringify({
            type: 'ERROR',
            message: 'Mouvement impossible'
        }));
    }
}

// Fonction pour diffuser aux joueurs proches
function broadcastToNearbyPlayers(data) {
    // Logique pour déterminer les joueurs proches
    const nearbyPlayers = findNearbyPlayers(data.position);
    
    nearbyPlayers.forEach(playerId => {
        const connection = activeConnections.get(playerId);
        if (connection) {
            connection.send(JSON.stringify({
                type: 'NEARBY_MOVEMENT',
                data: data
            }));
        }
    });
}

// Routes HTTP pour les actions non temps réel
app.post('/api/login', async (req, res) => {
    // Logique de login
});

app.get('/api/player/:id/status', async (req, res) => {
    // Récupération status joueur
});

app.post('/api/alliance/create', async (req, res) => {
    // Création alliance
});

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Erreur serveur');
});

// Démarrage serveur
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
});