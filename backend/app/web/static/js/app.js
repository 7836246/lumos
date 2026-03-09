/* ═══════════════════════════════════════════════════
   Lumos — Web App Logic
   ═══════════════════════════════════════════════════ */

const API = '/api/v1';

// ── Routing ──

function switchSection(id) {
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-link[data-section]').forEach(l => l.classList.remove('active'));
    const el = document.getElementById(id);
    if (el) el.classList.add('active');
    const link = document.querySelector(`[data-section="${id}"]`);
    if (link) link.classList.add('active');
    window.location.hash = id;
}

document.querySelectorAll('.nav-link[data-section]').forEach(l => {
    l.addEventListener('click', e => { e.preventDefault(); switchSection(l.dataset.section); });
});

window.addEventListener('hashchange', () => switchSection(location.hash.slice(1) || 'home'));
switchSection(location.hash.slice(1) || 'home');

// ── Input ──

const ta = document.getElementById('contract-input');
const cc = document.getElementById('char-count');
const ba = document.getElementById('btn-analyze');

ta && ta.addEventListener('input', () => {
    const n = ta.value.length;
    ba.disabled = n < 50;
    cc.textContent = n < 50 && n > 0 ? `${n} 字 (最少 50)` : `${n} 字`;
    cc.style.color = n > 0 && n < 50 ? 'var(--yellow)' : '';
});

// ── Analysis ──

let risks = [];

function startAnalysis() {
    const text = ta.value.trim();
    if (text.length < 50) return;
    risks = [];
    show('progress');
    progress(0, '提交中');

    document.getElementById('node-pills').innerHTML =
        '<span class="pill" id="n-extractor">条款提取</span>' +
        '<span class="pill" id="n-retriever">法规检索</span>' +
        '<span class="pill" id="n-reviewer">风险审查</span>';

    fetch(`${API}/contracts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, source: 'text_paste' }),
    })
        .then(r => r.json())
        .then(d => { progress(0.05, d.message); listenSSE(d.contract_id); })
        .catch(e => { show('input'); alert('提交失败: ' + e.message); });
}

function listenSSE(id) {
    const es = new EventSource(`${API}/contracts/${id}/stream`);

    es.addEventListener('node_start', e => {
        const d = JSON.parse(e.data);
        progress(d.progress, d.description);
        pill(d.node_name, 'active');
    });
    es.addEventListener('node_complete', e => {
        const d = JSON.parse(e.data);
        progress(d.progress, d.description);
        pill(d.node_name, 'done');
    });
    es.addEventListener('thinking', e => {
        const d = JSON.parse(e.data);
        progress(null, d.message);
    });
    es.addEventListener('risk_found', e => risks.push(JSON.parse(e.data)));
    es.addEventListener('summary', e => render(JSON.parse(e.data)));
    es.addEventListener('complete', () => {
        es.close();
        progress(1, '完成');
        setTimeout(() => show('result'), 500);
    });
    es.addEventListener('error', e => {
        es.close();
        try { alert('分析出错: ' + JSON.parse(e.data).message); } catch { }
        show('input');
    });
}

// ── UI helpers ──

function show(phase) {
    ['input', 'progress', 'result'].forEach(p =>
        document.getElementById(p + '-phase').style.display = p === phase ? 'block' : 'none'
    );
}

function progress(val, msg) {
    if (val !== null) {
        const pct = Math.round(val * 100);
        document.getElementById('ring-pct').textContent = pct + '%';
        document.getElementById('ring-fill').style.strokeDashoffset = 326.7 * (1 - val);
    }
    if (msg) document.getElementById('progress-msg').textContent = msg;
}

function pill(name, state) {
    const el = document.getElementById('n-' + name);
    if (el) el.className = 'pill ' + state;
}

function render(summary) {
    const c = color(summary.overall_level);
    const l = label(summary.overall_level);

    document.getElementById('score-card').innerHTML =
        `<div><span class="score-big" style="color:${c}">${summary.overall_score}</span>` +
        `<span class="score-sub" style="color:${c}">/100</span></div>` +
        `<div style="flex:1"><span class="score-tag" style="background:${c}15;color:${c}">${l}</span>` +
        `<div class="score-meta">共扫描 ${summary.total_clauses} 条条款，发现 ${summary.total_risks} 项风险</div></div>`;
    document.getElementById('score-card').style.cssText =
        `background:linear-gradient(135deg,${c}0a,${c}04);border:1px solid ${c}20`;

    document.getElementById('result-summary').textContent = summary.summary;

    const list = document.getElementById('risk-list');
    if (!risks.length) {
        list.innerHTML = '<div class="no-risk">未发现明显风险，合同整体合规</div>';
        return;
    }

    list.innerHTML = risks.map((r, i) => {
        const rc = color(r.level);
        return `<div class="risk-item" onclick="this.classList.toggle('open')">
            <div class="risk-head">
                <div class="risk-dot" style="background:${rc}"></div>
                <div class="risk-info">
                    <h4>${r.title || '风险条目'}</h4>
                    <span style="color:${rc}">评分 ${r.score}/100</span>
                </div>
                <span class="risk-chevron">▾</span>
            </div>
            <div class="risk-body">
                ${r.original_clause ? block('原始条文', r.original_clause) : ''}
                ${block('白话解读', r.explanation || '')}
                ${r.legal_basis ? block('法律依据', r.legal_basis) : ''}
                ${r.negotiation_tip ? block('谈判话术', r.negotiation_tip, true) : ''}
            </div>
        </div>`;
    }).join('');
}

function block(title, text, tip) {
    return `<div class="risk-block"><div class="risk-block-title">${title}</div>` +
        `<div class="risk-block-content${tip ? ' tip' : ''}">${text}</div></div>`;
}

function resetAnalysis() {
    ta.value = ''; cc.textContent = '0 字'; ba.disabled = true;
    risks = []; show('input');
}

function color(lv) {
    return { high: '#f87171', medium: '#fbbf24', low: '#34d399', safe: '#60a5fa' }[lv] || '#fbbf24';
}
function label(lv) {
    return { high: '高危', medium: '警惕', low: '关注', safe: '合规' }[lv] || '警惕';
}

// ── Admin ──

async function checkHealth() {
    const h = document.getElementById('s-health');
    h.textContent = '检测中'; h.className = 'val loading';
    try {
        const r = await fetch(`${API}/health`);
        const d = await r.json();
        h.textContent = '运行正常'; h.className = 'val ok';
        document.getElementById('s-version').textContent = 'v' + d.version;
        document.getElementById('s-env').textContent = d.environment;
    } catch {
        h.textContent = '连接失败'; h.className = 'val err';
    }
}

function saveModelConfig() {
    alert('当前版本请编辑 backend/.env 文件配置模型参数，后续将支持在线热更新。');
}
function saveSecurityConfig() {
    alert('当前版本请编辑 backend/.env 文件配置安全参数。');
}

checkHealth();
