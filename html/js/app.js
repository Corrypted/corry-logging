const app = document.getElementById('app');
const logList = document.getElementById('logList');
const closeBtn = document.getElementById('closeBtn');
const searchInput = document.getElementById('searchInput');
const pageText = document.getElementById('pageText');
const prevPageBtn = document.getElementById('prevPage');
const nextPageBtn = document.getElementById('nextPage');
let maxLogs = 200;
let levelsMap = {};
let searchTimer = null;
let isSearching = false;
let currentPage = 0;
let totalPages = 1;
let totalLogs = 0;

const getLevelInfo = (level) => {
    const key = String(level || 'INFO').toUpperCase();
    const info = levelsMap[key] || {};
    return {
        key,
        label: info.label || key.toLowerCase(),
        color: info.color || ''
    };
};

const buildLogItem = (entry) => {
    const item = document.createElement('div');
    const levelInfo = getLevelInfo(entry.level);
    const source = (entry.source || 'server').toLowerCase();
    const clientInfo = entry.clientInfo || null;
    const isClientLog = source === 'client' && clientInfo;
    item.className = 'log';
    if (isClientLog) {
        item.classList.add('expandable');
    }
    if (entry.id) {
        item.dataset.id = entry.id;
    }
    const levelStyle = levelInfo.color ? ` style="color: ${levelInfo.color}"` : '';
    const details = isClientLog
        ? `
            <div class="details">
                <div class="details-row">
                    <span class="details-label">Player</span>
                    <span class="details-value" data-copy="${clientInfo.name || 'Unknown'}">${clientInfo.name || 'Unknown'}</span>
                </div>
                <div class="details-row">
                    <span class="details-label">RP Name</span>
                    <span class="details-value" data-copy="${clientInfo.rpName || 'Unknown'}">${clientInfo.rpName || 'Unknown'}</span>
                </div>
                <div class="details-row">
                    <span class="details-label">ID</span>
                    <span class="details-value" data-copy="${clientInfo.id || ''}">${clientInfo.id || ''}</span>
                </div>
                <div class="details-row">
                    <span class="details-label">License</span>
                    <span class="details-value" data-copy="${clientInfo.license || ''}">${clientInfo.license || ''}</span>
                </div>
                <div class="details-row">
                    <span class="details-label">Citizen ID</span>
                    <span class="details-value" data-copy="${clientInfo.citizenId || ''}">${clientInfo.citizenId || ''}</span>
                </div>
            </div>
        `
        : '';
    item.innerHTML = `
        <div class="time">${entry.time || '--:--:--'}</div>
        <div class="level"${levelStyle}>${levelInfo.label}</div>
        <div class="source ${source}">${source}</div>
        <div class="message">${entry.message || ''}</div>
        <div class="menu">
            <button class="menu-toggle" aria-label="Actions">&#8942;</button>
            <div class="menu-dropdown">
                <button class="menu-item" data-action="copy">Copy</button>
                <button class="menu-item" data-action="delete">Delete</button>
            </div>
        </div>
        ${details}
    `;
    return item;
};

const setFooter = (text) => {
    pageText.textContent = text;
};

const setPagination = (page, pages, total) => {
    currentPage = page;
    totalPages = pages;
    totalLogs = total;
    prevPageBtn.disabled = isSearching || currentPage <= 0;
    nextPageBtn.disabled = isSearching || currentPage >= totalPages - 1;
};

const renderLogs = (logs, options = {}) => {
    const displayLogs = logs;
    logList.innerHTML = '';
    if (!displayLogs.length) {
        const levelInfo = getLevelInfo('INFO');
        const empty = document.createElement('div');
        empty.className = 'log';
        const levelStyle = levelInfo.color ? ` style="color: ${levelInfo.color}"` : '';
        empty.innerHTML = `
            <div class="time">--:--:--</div>
            <div class="level"${levelStyle}>${levelInfo.label}</div>
            <div class="source server">server</div>
            <div class="message">No logs available.</div>
        `;
        logList.appendChild(empty);
        setFooter(options.footer || 'No results found');
        return;
    }

    displayLogs.forEach((entry) => logList.appendChild(buildLogItem(entry)));
    if (options.footer) {
        setFooter(options.footer);
    }
};

const removeLogById = (id) => {
    if (!id) {
        return;
    }
    const nodes = logList.querySelectorAll(`.log[data-id="${id}"]`);
    nodes.forEach((node) => node.remove());
    if (!logList.children.length) {
        renderLogs([], { footer: pageText.textContent || 'No results found' });
    }
};

const appendLog = (entry) => {
    const first = logList.firstElementChild;
    if (first && first.querySelector('.message')?.textContent === 'No logs available.') {
        logList.innerHTML = '';
    }
    logList.insertBefore(buildLogItem(entry || {}), logList.firstChild);
    while (logList.children.length > maxLogs) {
        logList.removeChild(logList.lastElementChild);
    }
};

const requestSearch = (query) => {
    fetch(`https://${GetParentResourceName()}/search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ query })
    });
};

const clearSearch = () => {
    fetch(`https://${GetParentResourceName()}/clearSearch`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
};

const closeUi = () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
};

const copyText = (text) => {
    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).catch(() => {
            const textarea = document.createElement('textarea');
            textarea.value = text;
            textarea.style.position = 'fixed';
            textarea.style.opacity = '0';
            document.body.appendChild(textarea);
            textarea.focus();
            textarea.select();
            document.execCommand('copy');
            document.body.removeChild(textarea);
        });
        return;
    }

    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.focus();
    textarea.select();
    document.execCommand('copy');
    document.body.removeChild(textarea);
};

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'setVisible') {
        app.classList.toggle('hidden', !data.visible);
    }

    if (data.action === 'addLog') {
        if (!isSearching) {
            appendLog(data.log || {});
        }
    }

    if (data.action === 'setPage') {
        isSearching = false;
        renderLogs(data.logs || [], { footer: `Page ${data.page + 1} / ${data.totalPages} (${data.total})` });
        setPagination(data.page || 0, data.totalPages || 1, data.total || 0);
    }

    if (data.action === 'setSearchResults') {
        isSearching = true;
        const count = (data.logs || []).length;
        const label = data.query ? `Results for "${data.query}" (${count})` : `Results (${count})`;
        renderLogs(data.logs || [], { footer: label });
        setPagination(0, 1, count);
    }

    if (data.action === 'setConfig') {
        if (typeof data.maxLogs === 'number' && data.maxLogs > 0) {
            maxLogs = data.maxLogs;
        }
        if (data.levels && typeof data.levels === 'object') {
            levelsMap = data.levels;
        }
    }

    if (data.action === 'logDeleted') {
        removeLogById(data.id);
    }
});

closeBtn.addEventListener('click', closeUi);

const closeMenus = () => {
    logList.querySelectorAll('.menu.open').forEach((menu) => menu.classList.remove('open'));
};

logList.addEventListener('click', (event) => {
    const detailsValue = event.target.closest('.details-value');
    if (detailsValue) {
        event.preventDefault();
        event.stopPropagation();
        const value = detailsValue.dataset.copy || detailsValue.textContent || '';
        if (value) {
            copyText(value);
            fetch(`https://${GetParentResourceName()}/copyNotify`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ message: 'Copied to clipboard.' })
            });
        }
        return;
    }

    const toggle = event.target.closest('.menu-toggle');
    if (toggle) {
        event.preventDefault();
        const menu = toggle.closest('.menu');
        if (!menu) {
            return;
        }
        const isOpen = menu.classList.contains('open');
        closeMenus();
        if (!isOpen) {
            menu.classList.add('open');
        }
        return;
    }

    const actionButton = event.target.closest('.menu-item');
    if (actionButton) {
        const row = actionButton.closest('.log');
        if (!row || !row.dataset.id) {
            return;
        }
        const action = actionButton.dataset.action;
        if (action === 'copy') {
            const time = row.querySelector('.time')?.textContent || '';
            const level = row.querySelector('.level')?.textContent || '';
            const source = row.querySelector('.source')?.textContent || '';
            const message = row.querySelector('.message')?.textContent || '';
            const payload = `${time} | ${level} | ${source} | ${message}`.trim();
            copyText(payload);
        }
        if (action === 'delete') {
            fetch(`https://${GetParentResourceName()}/deleteLog`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify({ id: row.dataset.id })
            });
        }
        closeMenus();
        return;
    }

    const row = event.target.closest('.log.expandable');
    if (row) {
        row.classList.toggle('expanded');
    }
});

prevPageBtn.addEventListener('click', () => {
    if (isSearching || currentPage <= 0) {
        return;
    }
    fetch(`https://${GetParentResourceName()}/pagePrev`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ page: currentPage - 1 })
    });
});

nextPageBtn.addEventListener('click', () => {
    if (isSearching || currentPage >= totalPages - 1) {
        return;
    }
    fetch(`https://${GetParentResourceName()}/pageNext`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ page: currentPage + 1 })
    });
});

searchInput.addEventListener('input', () => {
    const value = searchInput.value.trim();
    if (searchTimer) {
        clearTimeout(searchTimer);
    }
    searchTimer = setTimeout(() => {
        if (value.length) {
            requestSearch(value);
        } else {
            clearSearch();
        }
    }, 200);
});

window.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        closeUi();
    }
    if (event.key === 'Escape') {
        closeMenus();
    }
});

window.addEventListener('click', (event) => {
    if (!event.target.closest('.menu')) {
        closeMenus();
    }
});
