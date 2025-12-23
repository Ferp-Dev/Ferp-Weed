// --- DATA & CONFIG ---
const INDOOR_LEVEL_REQ = 15;
const INDOOR_UNLOCK_COST = 999;

const INDOOR_UPGRADES = [
    { id: 'led_lights', label: 'Full Spectrum LED', desc: '+20% Growth Speed Indoors', cost: 5, icon: 'fa-lightbulb' },
    { id: 'carbon_filter', label: 'Carbon Filter', desc: '-50% Police Raid Chance', cost: 4, icon: 'fa-fan' },
    { id: 'hydroponics', label: 'Hydroponics System', desc: 'No Water Needed + Max Quality', cost: 8, icon: 'fa-water' },
    { id: 'auto_trimmer', label: 'Auto-Trimmer', desc: 'Instant Harvest Indoors', cost: 6, icon: 'fa-scissors' }
];

const PERKS_DB = {
    'yield_boost': { id: 'yield_boost', label: 'Bountiful Harvest', desc: 'Increases harvest amount. (Max 5)', cat: 'production', cost: 1, reqLevel: 1, effects: { p: 0.05, g: 0.05, r: 0 } },
    'growth_speed': { id: 'growth_speed', label: 'Accelerated Growth', desc: 'Reduces growth time. (Max 5)', cat: 'production', cost: 1, reqLevel: 3, effects: { p: 0, g: 0.1, r: -0.02 } },
    'resilience': { id: 'resilience', label: 'Natural Resistance', desc: 'Less water/fert consumption. (Max 3)', cat: 'production', cost: 2, reqLevel: 5, effects: { p: 0, g: 0, r: 0.15 } },
    'master_grower': { id: 'master_grower', label: 'Master Grower', desc: 'Never dies from lack of water. (Unique)', cat: 'production', cost: 5, reqLevel: 10, effects: { p: 0, g: 0.1, r: 0.3 } },
    'seeding_chance': { id: 'seeding_chance', label: 'Controlled Pollination', desc: 'Male seed chance. (Max 5)', cat: 'reproduction', cost: 1, reqLevel: 2, effects: { p: -0.05, g: 0.05, r: 0 } },
    'fertility': { id: 'fertility', label: 'Fertility', desc: 'Increases max seeds. (Max 3)', cat: 'reproduction', cost: 2, reqLevel: 4, effects: { p: 0, g: 0.1, r: 0 } },
    'female_seed_chance': { id: 'female_seed_chance', label: 'Feminization', desc: 'Female seed chance. (Max 3)', cat: 'reproduction', cost: 2, reqLevel: 6, effects: { p: 0.05, g: 0, r: 0.05 } },
    'negotiator': { id: 'negotiator', label: 'Salesmanship', desc: 'Increases sell price. (Max 5)', cat: 'sales', cost: 1, reqLevel: 3, effects: { p: 0, g: 0, r: 0 } },
    'fast_seller': { id: 'fast_seller', label: 'Fast Flow', desc: 'Reduces customer wait. (Max 3)', cat: 'sales', cost: 2, reqLevel: 5, effects: { p: 0, g: 0, r: 0 } },
    'bulk_seller': { id: 'bulk_seller', label: 'Wholesale', desc: 'Double sale chance. (Max 3)', cat: 'sales', cost: 2, reqLevel: 7, effects: { p: 0, g: 0, r: 0 } },
    'stress_relief': { id: 'stress_relief', label: 'Inner Peace', desc: 'Removes more stress. (Max 3)', cat: 'effects', cost: 1, reqLevel: 1, effects: { p: 0.1, g: 0, r: 0 } },
    'swiftness': { id: 'swiftness', label: 'Swift Feet', desc: 'Increases run speed. (Max 2)', cat: 'effects', cost: 4, reqLevel: 2, effects: { p: 0.1, g: 0, r: 0 } },
    'iron_lungs': { id: 'iron_lungs', label: 'Iron Lungs', desc: "Underwater breath. (Max 3)", cat: 'effects', cost: 2, reqLevel: 3, effects: { p: 0.1, g: 0, r: 0 } },
    'endurance': { id: 'endurance', label: 'Marathoner', desc: 'Temp infinite stamina. (Max 3)', cat: 'effects', cost: 2, reqLevel: 4, effects: { p: 0.1, g: 0, r: 0 } },
    'night_vision': { id: 'night_vision', label: 'Cat Eyes', desc: 'Temp night vision. (Unique)', cat: 'effects', cost: 4, reqLevel: 5, effects: { p: 0.1, g: 0, r: 0 } },
    'shadow': { id: 'shadow', label: 'Shadow Steps', desc: 'Less walking noise. (Max 3)', cat: 'effects', cost: 3, reqLevel: 6, effects: { p: 0.1, g: 0, r: 0 } },
    'stone_skin': { id: 'stone_skin', label: 'Stone Skin', desc: 'Armor bonus. (Max 3)', cat: 'effects', cost: 3, reqLevel: 7, effects: { p: 0.1, g: 0, r: 0.1 } },
    'vitality': { id: 'vitality', label: 'Vitality', desc: 'Health regeneration. (Max 3)', cat: 'effects', cost: 3, reqLevel: 8, effects: { p: 0.1, g: 0, r: 0.1 } },
    'strength': { id: 'strength', label: 'Brute Force', desc: 'Melee damage. (Max 3)', cat: 'effects', cost: 3, reqLevel: 9, effects: { p: 0.1, g: 0, r: 0 } },
};

const MASTERY_DB = {
    5: [{ id: 'm5q', label: 'Stability', desc: 'Min Quality 60%', cat: 'quality' }, { id: 'm5p', label: 'Metabolism', desc: '-40% Water', cat: 'production' }, { id: 'm5r', label: 'Immunity I', desc: 'Basic Resistance', cat: 'resistance' }],
    10: [{ id: 'm10q', label: 'Terpenes', desc: 'Sell x1.5', cat: 'quality' }, { id: 'm10p', label: 'Hydroponics', desc: 'Allows Indoor', cat: 'production' }, { id: 'm10r', label: 'Survivor', desc: 'No drought death', cat: 'resistance' }],
    15: [{ id: 'm15q', label: 'Legend', desc: '+Reputation', cat: 'quality' }, { id: 'm15p', label: 'Cloning', desc: 'Recover Seed', cat: 'production' }, { id: 'm15r', label: 'Immortal', desc: 'Never dies', cat: 'resistance' }]
};

// --- STATE ---
let strains = [];
let activeStrain = null;
let userProgress = {};
let indoorProgress = [];
let isIndoorUnlocked = false;
let currentFilter = 'all';

// --- NUI UTILS ---
async function fetchNui(eventName, data = {}) {
    const options = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    };
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'ferp-weed';
    try {
        const resp = await fetch(`https://${resourceName}/${eventName}`, options);
        return await resp.json();
    } catch (err) {
        console.error(`NUI Call Error ${eventName}:`, err);
        // MOCK DATA for browser
        if (eventName === 'ferp-weed:getStrainData') {
            return [
                { id: 8821, name: "Purple Haze V2", citizenid: "USER1", level: 16, points: 15, unlocked: { q1: 1 }, indoor_unlocked: true, indoor_upgrades: ['led_lights'] },
                { id: 4022, name: "Lemon Kush", citizenid: "USER1", level: 5, points: 2, unlocked: {}, indoor_unlocked: false, indoor_upgrades: [] }
            ];
        }
        if (eventName === 'ferp-weed:checkVpn') return true;
        return { success: true };
    }
}

// --- APP LOGIC ---

function init() {
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.action === 'open') {
            // Re-fetch data on open
            fetchData();
        }
    });

    // Notify Laptop
    if (window.appReady) window.appReady();

    // Initial Fetch checks
    fetchNui('ferp-weed:checkVpn').then(hasVpn => {
        const isBrowser = !window.invokeNative;
        if (!hasVpn && !isBrowser) {
            showScreen('vpn-screen');
        } else {
            fetchData();
        }
    });

    // Event Listeners
    document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentFilter = btn.getAttribute('data-filter');
            renderGenetics();
        });
    });

    document.querySelectorAll('.nav-btn[data-tab]').forEach(btn => {
        btn.addEventListener('click', () => {
            const tab = btn.getAttribute('data-tab');
            document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            switchTab(tab);
        });
    });

    document.getElementById('btn-back').addEventListener('click', () => {
        showScreen('list-view');
    });

    document.getElementById('btn-rename-trigger').addEventListener('click', () => {
        document.getElementById('rename-input').value = activeStrain.name;
        toggleRename(true);
    });

    document.getElementById('btn-cancel-rename').addEventListener('click', () => toggleRename(false));
    document.getElementById('btn-save-rename').addEventListener('click', handleRenameSubmit);
}

function fetchData() {
    fetchNui('ferp-weed:getStrainData').then(data => {
        // Always render, even if data is null (default to empty array)
        strains = data || [];
        renderStrainList();
        showScreen('list-view');


    }).catch(err => {
        console.error('[WeedLab] Fetch Error:', err);
        // On error, still show empty UI to avoid black screen
        strains = [];
        renderStrainList();
        showScreen('list-view');
    });
}

function showScreen(screenId) {
    document.querySelectorAll('.weed-lab-container').forEach(el => el.classList.add('hidden'));
    document.getElementById(screenId).classList.remove('hidden');
    // Important: ensure display flex is set if not handled by CSS class toggle properly (hidden overrides)
}

function renderStrainList() {
    const grid = document.getElementById('strain-grid');
    grid.innerHTML = '';

    // Update Header Count
    const countEl = document.getElementById('total-strains-count');
    if (countEl) countEl.textContent = strains.length;

    // Update Best Level
    const bestLvlEl = document.getElementById('best-strain-lvl');
    if (bestLvlEl) {
        const maxLevel = strains.length > 0 ? Math.max(...strains.map(s => s.level)) : 0;
        bestLvlEl.textContent = maxLevel;
    }

    strains.forEach(strain => {
        const card = document.createElement('div');
        card.className = 'strain-card';
        card.innerHTML = `
            <div class="card-top">
                <div class="card-icon"><i class="fa-solid fa-cannabis"></i></div>
                <div class="strain-lvl-badge">LVL ${strain.level}</div>
            </div>
            <div>
                <h3>${strain.name}</h3>
                <div class="meta">
                    <span>PTS: ${strain.points}</span>
                    <span>#${strain.id}</span>
                </div>
            </div>
        `;
        card.onclick = () => openStrain(strain);
        grid.appendChild(card);
    });
}

function openStrain(strain) {
    activeStrain = strain;
    userProgress = strain.unlocked || {};
    indoorProgress = strain.indoor_upgrades || [];
    isIndoorUnlocked = strain.indoor_unlocked || false;

    // Update Sidebar
    document.getElementById('strain-name-display').textContent = strain.name;
    document.getElementById('strain-id-display').textContent = `#${strain.id}`;
    document.getElementById('pts-val-display').textContent = `${strain.points} PTS`;

    // Rename visibility
    const renameIcon = document.getElementById('btn-rename-trigger');
    if (strain.level >= 5 && !strain.renamed) renameIcon.classList.remove('hidden');
    else renameIcon.classList.add('hidden');

    // Indoor Lock Icon
    const indoorLock = document.getElementById('indoor-lock-icon');
    if (strain.level < INDOOR_LEVEL_REQ) indoorLock.classList.remove('hidden');
    else indoorLock.classList.add('hidden');

    showScreen('details-view');
    switchTab('evolution');
}

function switchTab(tabName) {
    document.querySelectorAll('.tab-pane').forEach(el => el.classList.add('hidden'));
    document.getElementById(`tab-${tabName}`).classList.remove('hidden');

    if (tabName === 'evolution') renderEvolution();
    if (tabName === 'genetics') renderGenetics();
    if (tabName === 'indoor') renderIndoor();
}


// --- RENDERERS ---

function renderEvolution() {
    document.getElementById('level-circle-display').textContent = activeStrain.level;
    document.getElementById('points-val-display').textContent = activeStrain.points;

    // Stats Calc
    let stats = { p: 1.0, g: 1.0, r: 0.0 };
    Object.keys(userProgress).forEach(uid => {
        const lvl = userProgress[uid];
        if (lvl > 0 && PERKS_DB[uid] && PERKS_DB[uid].effects) {
            if (PERKS_DB[uid].effects.p) stats.p += (PERKS_DB[uid].effects.p * lvl);
            if (PERKS_DB[uid].effects.g) stats.g += (PERKS_DB[uid].effects.g * lvl);
            if (PERKS_DB[uid].effects.r) stats.r += (PERKS_DB[uid].effects.r * lvl);
        }
    });

    document.getElementById('stat-p-val').textContent = `${Math.round(stats.p * 50)}%`;
    document.getElementById('stat-p-bar').style.width = `${(stats.p - 0.5) * 100}%`;

    document.getElementById('stat-g-val').textContent = `x${stats.g.toFixed(2)}`;
    document.getElementById('stat-g-bar').style.width = `${(stats.g - 0.5) * 100}%`;

    document.getElementById('stat-r-val').textContent = `${Math.round(stats.r * 100)}%`;
    document.getElementById('stat-r-bar').style.width = `${stats.r * 100}%`;

    // Mastery
    const container = document.getElementById('mastery-container');
    container.innerHTML = '';
    [5, 10, 15].forEach(tier => {
        const opts = MASTERY_DB[tier];
        const chosen = opts.find(o => userProgress[o.id]);
        const isUnlocked = activeStrain.level >= tier;

        const row = document.createElement('div');
        row.className = 'mastery-row';

        let choicesHtml = '';
        opts.forEach(opt => {
            let status = '';
            if (!isUnlocked) status = 'locked';
            else if (chosen && chosen.id !== opt.id) status = 'blocked';
            else if (chosen && chosen.id === opt.id) status = 'selected';
            const icons = { quality: 'fa-bolt', production: 'fa-seedling', resistance: 'fa-shield-halved' };

            choicesHtml += `
                <div class="choice-card ${status} ${opt.cat}" onclick="handleUnlock('${opt.id}', 0, 'mastery')">
                    <div class="choice-name"><i class="fa-solid ${icons[opt.cat]}" style="margin-right: 5px; font-size: 10px;"></i> ${opt.label}</div>
                    <div class="choice-desc">${opt.desc}</div>
                </div>
            `;
        });

        row.innerHTML = `
            <div class="tier-indicator ${isUnlocked ? 'active' : ''}">
                ${tier} <span>LVL</span>
            </div>
            <div class="tier-choices">
                ${choicesHtml}
            </div>
        `;
        container.appendChild(row);
    });
}

function renderGenetics() {
    const grid = document.getElementById('genetics-grid');
    grid.innerHTML = '';

    Object.values(PERKS_DB).forEach(perk => {
        if (currentFilter !== 'all' && perk.cat !== currentFilter) return;

        const currentLevel = userProgress[perk.id] || 0;
        const isOwned = currentLevel > 0;
        let maxLevel = perk.label.includes('(Unique)') ? 1 : (perk.desc.includes('Max 5') ? 5 : (perk.desc.includes('Max 3') ? 3 : 2));
        const isMaxed = currentLevel >= maxLevel;
        const reqMet = activeStrain.level >= (perk.reqLevel || 0);
        const canAfford = activeStrain.points >= perk.cost;

        const div = document.createElement('div');
        let nodeClass = 'perk-node';
        if (isOwned) nodeClass += ' unlocked active-glow';
        else if (!reqMet) nodeClass += ' unavailable';
        else nodeClass += ' locked';
        div.className = nodeClass;

        const icons = { production: 'fa-seedling', reproduction: 'fa-dna', sales: 'fa-hand-holding-dollar', effects: 'fa-magic' };

        let btnContent = '';
        let btnDisabled = false;
        let btnClass = 'btn-buy';
        let onClickAction = `handleUnlock('${perk.id}', ${perk.cost})`;

        if (isMaxed) {
            btnContent = '<i class="fa-solid fa-check"></i> Maxed';
            btnClass = 'btn-owned';
            onClickAction = '';
        } else if (!reqMet) {
            btnContent = `Requires LVL ${perk.reqLevel}`;
            btnDisabled = true;
        } else if (canAfford) {
            btnContent = isOwned ? `Evolve (${perk.cost} PTS)` : `Buy (${perk.cost} PTS)`;
        } else {
            btnContent = 'Missing Points';
            btnDisabled = true;
        }

        const lvlBadge = isOwned ? `<div class="status-badge">LVL ${currentLevel}</div>` : '';

        div.innerHTML = `
            ${lvlBadge}
            <div>
                <div class="perk-icon"><i class="fa-solid ${icons[perk.cat]}"></i></div>
                <h5>${perk.label}</h5>
                <p>${perk.desc}</p>
            </div>
            <div class="perk-action">
                <button class="${btnClass}" ${btnDisabled ? 'disabled' : ''} onclick="${onClickAction}">${btnContent}</button>
            </div>
        `;
        grid.appendChild(div);
    });
}

function renderIndoor() {
    const container = document.getElementById('indoor-content');
    container.innerHTML = '';

    if (activeStrain.level < INDOOR_LEVEL_REQ) {
        container.innerHTML = `
            <div class="lock-screen">
                <i class="fa-solid fa-lock"></i>
                <h2>Restricted Access</h2>
                <p>This technology requires advanced strain knowledge.</p>
                <div class="req-badge">Requires Level ${INDOOR_LEVEL_REQ}</div>
            </div>
        `;
        return;
    }

    if (!isIndoorUnlocked) {
        const canAfford = activeStrain.points >= INDOOR_UNLOCK_COST;
        container.innerHTML = `
            <div class="unlock-screen">
                <div class="content">
                    <i class="fa-solid fa-house-medical"></i>
                    <h2>Indoor Grow Kit</h2>
                    <p>Unlock the ability to plant <strong>${activeStrain.name}</strong> inside private properties, away from police eyes and protected from weather.</p>
                    <button class="btn-unlock-indoor" ${!canAfford ? 'disabled' : ''} onclick="handleUnlock('indoor_setup', ${INDOOR_UNLOCK_COST}, 'indoor_unlock')">
                        ${!canAfford ? `Missing Points (${INDOOR_UNLOCK_COST})` : `Install Kit (${INDOOR_UNLOCK_COST} PTS)`}
                    </button>
                </div>
            </div>
        `;
        return;
    }

    // Unlocked
    let upgradesHtml = '';
    INDOOR_UPGRADES.forEach(up => {
        const isOwned = indoorProgress.includes(up.id);
        const canAfford = activeStrain.points >= up.cost;

        let actionBtn = '';
        if (isOwned) {
            actionBtn = `<div class="badge"><i class="fa-solid fa-check"></i> Installed</div>`;
        } else {
            actionBtn = `<button ${!canAfford ? 'disabled' : ''} onclick="handleUnlock('${up.id}', ${up.cost}, 'indoor_upgrade')">Install (${up.cost})</button>`;
        }

        upgradesHtml += `
            <div class="upgrade-card ${isOwned ? 'owned' : ''}">
                <div class="up-icon"><i class="fa-solid ${up.icon}"></i></div>
                <div class="up-info">
                    <h4>${up.label}</h4>
                    <p>${up.desc}</p>
                </div>
                <div class="up-action">${actionBtn}</div>
            </div>
        `;
    });

    container.innerHTML = `
        <div class="indoor-panel">
            <div class="status-row">
                <div class="status-card active">
                    <div class="icon"><i class="fa-solid fa-check-circle"></i></div>
                    <div>
                        <div class="label">Status</div>
                        <div class="val">Operational</div>
                    </div>
                </div>
                <div class="status-card">
                    <div class="icon"><i class="fa-solid fa-plug"></i></div>
                    <div>
                        <div class="label">Upgrades</div>
                        <div class="val">${indoorProgress.length} / ${INDOOR_UPGRADES.length}</div>
                    </div>
                </div>
            </div>
            <div class="section-title">Infrastructure</div>
            <div class="upgrades-grid">
                ${upgradesHtml}
            </div>
        </div>
    `;
}

// --- ACTIONS ---

function handleUnlock(itemId, cost, type = 'perk') {
    if (!activeStrain || activeStrain.points < cost) return;

    // Optimistic Update
    activeStrain.points -= cost;
    if (type === 'indoor_unlock') isIndoorUnlocked = true;
    else if (type === 'indoor_upgrade') indoorProgress.push(itemId);
    else if (type === 'mastery') { /* Mastery update logic needed if generic handle doesn't suffice */ }
    else {
        // Perk
        userProgress[itemId] = (userProgress[itemId] || 0) + 1;
    }

    // Server Call
    fetchNui('ferp-weed:unlockPerk', {
        strainId: activeStrain.id,
        perkId: itemId,
        type: type
    }).then(res => {
        if (!res || !res.success) {
            // Revert on failure (simplified, usually would reload data)
            console.error('Unlock failed');
            fetchData();
        } else {
            renderStrainUI(activeStrain); // Re-render current view
        }
    });

    renderStrainUI(activeStrain); // Immediate generic re-render
}

function renderStrainUI() {
    // Determine active tab and re-render
    const activeBtn = document.querySelector('.nav-btn[data-tab].active');
    const tab = activeBtn ? activeBtn.getAttribute('data-tab') : 'evolution';
    switchTab(tab);

    // Update Sidebar Points
    document.getElementById('pts-val-display').textContent = `${activeStrain.points} PTS`;
}

function toggleRename(show) {
    const container = document.getElementById('rename-container');
    const nameDisplay = document.getElementById('strain-name-display');
    const pen = document.getElementById('btn-rename-trigger');

    if (show) {
        container.classList.remove('hidden');
        nameDisplay.classList.add('hidden');
        pen.classList.add('hidden');
    } else {
        container.classList.add('hidden');
        nameDisplay.classList.remove('hidden');
        if (activeStrain.level >= 5 && !activeStrain.renamed) pen.classList.remove('hidden');
    }
}

function handleRenameSubmit() {
    const input = document.getElementById('rename-input');
    const newName = input.value;
    if (!newName || newName.length < 5) return;

    fetchNui('ferp-weed:renameStrain', {
        strainId: activeStrain.id,
        newName: newName
    }).then(res => {
        if (res && res.success) {
            activeStrain.name = newName;
            activeStrain.renamed = true;
            toggleRename(false);
            openStrain(activeStrain); // Refresh sidebar & content
        }
    });
}

// Start
init();
