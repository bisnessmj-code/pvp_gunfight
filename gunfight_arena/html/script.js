// ================================
// GUNFIGHT ARENA - SCRIPT.JS (VERSION FINALE CORRIGÉE - SANS CONSOLE.LOGS)
// Fix focus NUI : libération uniquement depuis le jeu, pas depuis le lobby
// ================================

// ================================
// GLOBAL VARIABLES
// ================================
let currentZoneData = [];
let lobbyLeaderboardCache = [];

// ================================
// EVENT LISTENER - NUI MESSAGES
// ================================
window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'show':
            if (data.zones && data.zones.length > 0) {
                currentZoneData = data.zones;
            }
            showUI();
            break;
        case 'showStats':
            showStats(data.stats);
            break;
        case 'showPersonalStats':
            showPersonalStats(data.stats);
            break;
        case 'showGlobalLeaderboard':
            showGlobalLeaderboard(data.stats);
            break;
        case 'showLobbyScoreboard':
            displayLobbyLeaderboard(data.stats);
            break;
        case 'killFeed':
            addKillFeedMessage(data.message);
            break;
        case 'updateZonePlayers':
            updateZonePlayers(data.zones);
            break;
        case 'clearKillFeed':
            clearKillFeed();
            break;
        // default:
        //     console.log("Action inconnue:", data.action); // Ligne supprimée
    }
});

// ================================
// DOM READY - BUTTON LISTENERS
// ================================
document.addEventListener('DOMContentLoaded', () => {
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', () => {
            closeUI();
        });
    }

    const statsCloseBtn = document.getElementById('stats-close-btn');
    if (statsCloseBtn) {
        statsCloseBtn.addEventListener('click', () => {
            closeStatsUI();
        });
    }

    const personalStatsBtn = document.getElementById('personal-stats-btn');
    if (personalStatsBtn) {
        personalStatsBtn.addEventListener('click', () => {
            // console.log("Demande stats personnelles"); // Ligne supprimée
            postNUIMessage('getPersonalStats', {});
        });
    }

    const viewFullBtn = document.getElementById('view-full-leaderboard');
    if (viewFullBtn) {
        viewFullBtn.addEventListener('click', () => {
            // console.log("Ouverture classement complet"); // Ligne supprimée
            postNUIMessage('getGlobalLeaderboard', {});
        });
    }

    const personalStatsCloseBtn = document.getElementById('personal-stats-close-btn');
    if (personalStatsCloseBtn) {
        personalStatsCloseBtn.addEventListener('click', () => {
            closePersonalStatsUI();
        });
    }

    const globalLeaderboardCloseBtn = document.getElementById('global-leaderboard-close-btn');
    if (globalLeaderboardCloseBtn) {
        globalLeaderboardCloseBtn.addEventListener('click', () => {
            closeGlobalLeaderboardUI();
        });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            const arenaUI = document.getElementById('arena-ui');
            const statsUI = document.getElementById('stats-ui');
            const personalStatsUI = document.getElementById('personal-stats-ui');
            const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
            
            if (arenaUI && arenaUI.style.display === 'flex') {
                closeUI();
            } else if (statsUI && statsUI.style.display === 'flex') {
                closeStatsUI();
            } else if (personalStatsUI && personalStatsUI.style.display === 'flex') {
                closePersonalStatsUI();
            } else if (globalLeaderboardUI && globalLeaderboardUI.style.display === 'flex') {
                closeGlobalLeaderboardUI();
            }
        }
    });
});

// ================================
// ZONE SELECTION UI
// ================================
function showUI() {
    const arenaUI = document.getElementById('arena-ui');
    const zoneList = document.getElementById('zone-list');
    
    if (!arenaUI || !zoneList) {
        // console.error("Elements UI non trouvés"); // Ligne supprimée
        return;
    }

    zoneList.innerHTML = "";

    currentZoneData.forEach((zone, index) => {
        const card = document.createElement('div');
        card.className = "zone-card";
        card.setAttribute("data-zone", zone.zone);
        card.style.animationDelay = `${index * 0.1}s`;

        const maxPlayers = zone.maxPlayers || 15;
        const currentPlayers = zone.players || 0;
        const isFull = currentPlayers >= maxPlayers;

        card.innerHTML = `
            <img class="zone-image" src="${zone.image || 'images/default.png'}" alt="${zone.label || 'Zone ' + zone.zone}">
            <div class="zone-info">
                <div class="zone-text">${zone.label || 'Zone ' + zone.zone}</div>
                <div class="zone-players">
                    <span class="players-count">${currentPlayers}/${maxPlayers}</span>
                    <span class="zone-status ${isFull ? 'full' : ''}">${isFull ? 'FULL' : 'ACTIVE'}</span>
                </div>
            </div>
        `;

        if (!isFull) {
            card.addEventListener('click', () => {
                selectZone(zone.zone);
            });
        } else {
            card.style.opacity = '0.5';
            card.style.cursor = 'not-allowed';
        }

        zoneList.appendChild(card);
    });

    arenaUI.style.display = 'flex';
    // console.log("Chargement du classement lobby sidebar..."); // Ligne supprimée
    postNUIMessage('getLobbyScoreboard', {});
}

function closeUI() {
    const arenaUI = document.getElementById('arena-ui');
    if (arenaUI) {
        arenaUI.style.display = 'none';
    }
    
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(() => {
        // console.log("✓ Lobby fermé, focus libéré"); // Ligne supprimée
    }).catch(err => {
        // console.error("Erreur lors de la fermeture du lobby:", err); // Ligne supprimée
    });
}

function selectZone(zoneNumber) {
    // console.log("Zone sélectionnée:", zoneNumber); // Ligne supprimée
    
    fetch(`https://${GetParentResourceName()}/zoneSelected`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ zone: zoneNumber })
    }).then(() => {
        // console.log("Sélection de zone envoyée"); // Ligne supprimée
        closeUI();
    }).catch(err => {
        // console.error("Erreur lors de la sélection de la zone:", err); // Ligne supprimée
    });
}

// ================================
// UPDATE ZONE PLAYERS COUNT
// ================================
function updateZonePlayers(zones) {
    // console.log("Mise à jour des zones:", zones); // Ligne supprimée
    currentZoneData = zones;

    const arenaUI = document.getElementById('arena-ui');
    if (arenaUI && arenaUI.style.display === 'flex') {
        zones.forEach((zone) => {
            const card = document.querySelector(`.zone-card[data-zone="${zone.zone}"]`);
            if (card) {
                const maxPlayers = zone.maxPlayers || 15;
                const currentPlayers = zone.players || 0;
                const isFull = currentPlayers >= maxPlayers;

                const playersCount = card.querySelector('.players-count');
                const status = card.querySelector('.zone-status');

                if (playersCount) {
                    playersCount.textContent = `${currentPlayers}/${maxPlayers}`;
                }

                if (status) {
                    status.textContent = isFull ? 'FULL' : 'ACTIVE';
                    status.classList.toggle('full', isFull);
                }

                if (isFull) {
                    card.style.opacity = '0.5';
                    card.style.cursor = 'not-allowed';
                    card.onclick = null;
                } else {
                    card.style.opacity = '1';
                    card.style.cursor = 'pointer';
                    card.onclick = () => selectZone(zone.zone);
                }
            }
        });
    }
}

// ================================
// LEADERBOARD UI (EN JEU - Touche G)
// ================================
function showStats(stats) {
    const statsUI = document.getElementById('stats-ui');
    const statsList = document.getElementById('stats-list');
    
    if (!statsUI || !statsList) {
        // console.error("Elements stats non trouvés"); // Ligne supprimée
        return;
    }

    statsList.innerHTML = "";

    stats.forEach((item, index) => {
        const row = document.createElement('div');
        row.className = "stats-row";
        row.style.animationDelay = `${index * 0.05}s`;

        const rank = index + 1;
        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="stats-col rank-col">
                <div class="rank-badge">${rank}</div>
            </div>
            <div class="stats-col player-col">${item.player || 'Inconnu'}</div>
            <div class="stats-col kills-col">${item.kills || 0}</div>
            <div class="stats-col deaths-col">${item.deaths || 0}</div>
            <div class="stats-col kd-col">${kdValue.toFixed(2)}</div>
        `;

        statsList.appendChild(row);
    });

    statsUI.style.display = 'flex';
}

function closeStatsUI() {
    const statsUI = document.getElementById('stats-ui');
    if (statsUI) {
        statsUI.style.display = 'none';
    }
    
    fetch(`https://${GetParentResourceName()}/closeStatsUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(() => {
        // console.log("✓ Leaderboard fermé (en jeu), focus libéré"); // Ligne supprimée
    }).catch(err => {
        // console.error("Erreur lors de la fermeture du leaderboard:", err); // Ligne supprimée
    });
}

// ================================
// PERSONAL STATS UI (DEPUIS LE LOBBY)
// ================================
function showPersonalStats(stats) {
    // console.log("Affichage des stats personnelles:", stats); // Ligne supprimée
    
    const personalStatsUI = document.getElementById('personal-stats-ui');
    if (!personalStatsUI) {
        // console.error("Element 'personal-stats-ui' non trouvé"); // Ligne supprimée
        return;
    }

    const playerNameEl = document.getElementById('personal-player-name');
    if (playerNameEl) {
        playerNameEl.textContent = stats.player || "VOTRE PROFIL";
    }

    const kdValue = parseFloat(stats.kd) || 0;

    const elements = {
        'personal-kills': stats.kills || 0,
        'personal-deaths': stats.deaths || 0,
        'personal-kd': kdValue.toFixed(2),
        'personal-streak': stats.best_streak || 0,
        'personal-headshots': stats.headshots || 0,
        'personal-playtime': formatPlaytime(stats.total_playtime || 0)
    };

    for (const [id, value] of Object.entries(elements)) {
        const el = document.getElementById(id);
        if (el) {
            el.textContent = value;
        }
    }

    const sessionKills = document.getElementById('session-kills');
    if (sessionKills) sessionKills.textContent = stats.session_kills || 0;

    const sessionDeaths = document.getElementById('session-deaths');
    if (sessionDeaths) sessionDeaths.textContent = stats.session_deaths || 0;

    const currentStreak = document.getElementById('current-streak');
    if (currentStreak) currentStreak.textContent = stats.current_streak || 0;

    personalStatsUI.style.display = 'flex';
}

function closePersonalStatsUI() {
    const personalStatsUI = document.getElementById('personal-stats-ui');
    if (personalStatsUI) {
        personalStatsUI.style.display = 'none';
    }
    
    fetch(`https://${GetParentResourceName()}/closePersonalStatsUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(() => {
        // console.log("✓ Stats personnelles fermées, focus reste actif (lobby)"); // Ligne supprimée
    }).catch(err => {
        // console.error("Erreur lors de la fermeture des stats personnelles:", err); // Ligne supprimée
    });
}

// ================================
// GLOBAL LEADERBOARD UI (DEPUIS LE LOBBY)
// ================================
function showGlobalLeaderboard(stats) {
    // console.log("Affichage du classement global:", stats); // Ligne supprimée
    
    const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
    const leaderboardList = document.getElementById('global-leaderboard-list');
    
    if (!globalLeaderboardUI || !leaderboardList) {
        // console.error("Elements de classement global non trouvés"); // Ligne supprimée
        return;
    }

    leaderboardList.innerHTML = "";

    stats.forEach((item) => {
        const row = document.createElement('div');
        row.className = "stats-row";
        row.style.animationDelay = `${item.rank * 0.05}s`;

        const kdValue = parseFloat(item.kd) || 0;

        row.innerHTML = `
            <div class="stats-col rank-col">
                <div class="rank-badge">${item.rank}</div>
            </div>
            <div class="stats-col player-col">${item.player || 'Inconnu'}</div>
            <div class="stats-col kills-col">${item.kills || 0}</div>
            <div class="stats-col deaths-col">${item.deaths || 0}</div>
            <div class="stats-col headshots-col">${item.headshots || 0}</div>
            <div class="stats-col streak-col">${item.best_streak || 0}</div>
            <div class="stats-col kd-col">${kdValue.toFixed(2)}</div>
        `;

        leaderboardList.appendChild(row);
    });

    globalLeaderboardUI.style.display = 'flex';
}

function closeGlobalLeaderboardUI() {
    const globalLeaderboardUI = document.getElementById('global-leaderboard-ui');
    if (globalLeaderboardUI) {
        globalLeaderboardUI.style.display = 'none';
    }
    
    fetch(`https://${GetParentResourceName()}/closeGlobalLeaderboardUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(() => {
        // console.log("✓ Classement global fermé, focus reste actif (lobby)"); // Ligne supprimée
    }).catch(err => {
        // console.error("Erreur lors de la fermeture du classement global:", err); // Ligne supprimée
    });
}

// ================================
// LOBBY LEADERBOARD SIDEBAR
// ================================
function displayLobbyLeaderboard(stats) {
    // console.log("Affichage lobby leaderboard:", stats); // Ligne supprimée
    const lobbyList = document.getElementById('lobby-leaderboard-list');
    if (!lobbyList) return;

    lobbyLeaderboardCache = stats;
    lobbyList.innerHTML = '';

    const top10 = stats.slice(0, 10);

    if (top10.length === 0) {
        lobbyList.innerHTML = `
            <div class="leaderboard-loading">
                <p style="text-align: center; color: var(--text-secondary);">
                    Aucun classement disponible.<br>
                    Soyez le premier à jouer !
                </p>
            </div>
        `;
        return;
    }

    top10.forEach((player) => {
        const entry = document.createElement('div');
        entry.className = 'lobby-leaderboard-entry';
        entry.style.animationDelay = `${player.rank * 0.05}s`;

        const kdValue = parseFloat(player.kd) || 0;

        entry.innerHTML = `
            <div class="lobby-rank">${player.rank}</div>
            <div class="lobby-player-info">
                <div class="lobby-player-name">${player.player || 'Inconnu'}</div>
                <div class="lobby-player-stats">
                    <div class="lobby-stat">
                        <span class="lobby-stat-label">K:</span>
                        <span class="lobby-stat-value">${player.kills || 0}</span>
                    </div>
                    <div class="lobby-stat">
                        <span class="lobby-stat-label">D:</span>
                        <span class="lobby-stat-value">${player.deaths || 0}</span>
                    </div>
                </div>
            </div>
            <div class="lobby-kd">${kdValue.toFixed(2)}</div>
        `;

        lobbyList.appendChild(entry);
    });

    // console.log(`Lobby leaderboard affiché: ${top10.length} entrées`); // Ligne supprimée
}

// ================================
// KILL FEED
// ================================
function addKillFeedMessage(message) {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (!killfeedUI) {
        // console.error("Element killfeed-ui non trouvé"); // Ligne supprimée
        return;
    }

    const messageDiv = document.createElement('div');
    messageDiv.className = 'killfeed-message';

    let iconHTML = '';
    if (message.headshot) {
        iconHTML = `<div class="kill-icon headshot">💀</div>`;
    } else {
        iconHTML = `<div class="kill-icon">⚔️</div>`;
    }

    let multiplierHTML = '';
    if (message.multiplier && message.multiplier > 1) {
        multiplierHTML = `<div class="kill-multiplier">x${message.multiplier}</div>`;
    }

    messageDiv.innerHTML = `
        ${iconHTML}
        <div class="kill-text">
            <span class="kill-killer">${message.killer}</span>
            <span> a éliminé </span>
            <span class="kill-victim">${message.victim}</span>
        </div>
        ${multiplierHTML}
    `;

    killfeedUI.appendChild(messageDiv);

    setTimeout(() => {
        if (messageDiv.parentNode) {
            messageDiv.remove();
        }
    }, 5000);
}

function clearKillFeed() {
    const killfeedUI = document.getElementById('killfeed-ui');
    if (killfeedUI) {
        killfeedUI.innerHTML = '';
    }
}

// ================================
// UTILITY FUNCTIONS
// ================================
function formatPlaytime(seconds) {
    if (seconds < 60) {
        return seconds + 's';
    } else if (seconds < 3600) {
        return Math.floor(seconds / 60) + 'min';
    } else {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return hours + 'h' + (minutes > 0 ? ' ' + minutes + 'min' : '');
    }
}

function postNUIMessage(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(err => { /* console.error(`Erreur lors de l'envoi du message ${action}:`, err) */ }); // Ligne supprimée
}

function GetParentResourceName() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '' || window.location.hostname === '127.0.0.1') {
        return 'gunfight_arena';
    }
    
    const pathArray = window.location.pathname.split('/');
    const resourceIndex = pathArray.findIndex(part => part === 'html') - 1;
    if (resourceIndex >= 0 && pathArray[resourceIndex]) {
        return pathArray[resourceIndex];
    }
    
    return 'gunfight_arena';
}

// // ================================
// // CONSOLE INFO (Bloc entier supprimé)
// // ================================
// console.log('%c🎮 Gunfight Arena UI Loaded (VERSION 3.0)', 'color: #00fff7; font-size: 16px; font-weight: bold;');
// console.log('%c✓ PED au lobby + Spawn aléatoire', 'color: #00ff88; font-size: 12px;');
// console.log('Resource Name:', GetParentResourceName());