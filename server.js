const http = require('http');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ROOT = path.join(process.env.HOME, '.local/state/claude-orch');
const THREADS_DIR = path.join(ROOT, 'threads');
const PORT = process.env.PORT || 4729;

function safeRead(p) { try { return fs.readFileSync(p, 'utf8').trim(); } catch { return null; } }
function pidAlive(pid) {
  if (!pid) return false;
  try { process.kill(Number(pid), 0); return true; } catch { return false; }
}

function parseLog(filePath) {
  const result = {
    events: 0, steps: 0, toolCalls: 0, toolsByName: {}, tokens: { input:0, output:0, reasoning:0, cacheRead:0, cacheWrite:0 },
    cost: 0, lastTimestamp: null, firstTimestamp: null, lastText: null, lastTool: null,
    recentTools: [], recentTexts: [], errors: []
  };
  if (!fs.existsSync(filePath)) return result;
  let lines;
  try { lines = fs.readFileSync(filePath, 'utf8').split(/\n/); } catch { return result; }
  for (const raw of lines) {
    const line = raw.trim();
    if (!line) continue;
    let o;
    try { o = JSON.parse(line); } catch { continue; }
    result.events++;
    const ts = o.timestamp;
    if (typeof ts === 'number') {
      if (result.firstTimestamp === null || ts < result.firstTimestamp) result.firstTimestamp = ts;
      if (result.lastTimestamp === null || ts > result.lastTimestamp) result.lastTimestamp = ts;
    }
    const part = o.part || {};
    if (o.type === 'step_start') result.steps++;
    if (o.type === 'step_finish') {
      const t = part.tokens || {};
      result.tokens.input += t.input || 0;
      result.tokens.output += t.output || 0;
      result.tokens.reasoning += t.reasoning || 0;
      result.tokens.cacheRead += (t.cache && t.cache.read) || 0;
      result.tokens.cacheWrite += (t.cache && t.cache.write) || 0;
      result.cost += part.cost || 0;
    }
    if (o.type === 'tool_use') {
      result.toolCalls++;
      const name = part.tool || 'unknown';
      result.toolsByName[name] = (result.toolsByName[name] || 0) + 1;
      const st = (part.state && part.state.status) || '';
      result.lastTool = { name, status: st, ts };
      result.recentTools.push({ name, status: st, ts });
      if (result.recentTools.length > 12) result.recentTools.shift();
      if (st && st !== 'completed') result.errors.push({ name, status: st, ts });
    }
    if (o.type === 'text') {
      const txt = part.text || '';
      result.lastText = txt;
      result.recentTexts.push({ text: txt.slice(0, 400), ts });
      if (result.recentTexts.length > 6) result.recentTexts.shift();
    }
  }
  return result;
}

function gitInfo(wt) {
  try {
    const branch = execSync(`git -C ${JSON.stringify(wt)} branch --show-current`, { encoding:'utf8', timeout:3000 }).trim();
    let dirty = '';
    try { dirty = execSync(`git -C ${JSON.stringify(wt)} status --porcelain`, { encoding:'utf8', timeout:3000 }).trim(); } catch {}
    return { branch, dirtyCount: dirty ? dirty.split('\n').length : 0 };
  } catch { return { branch: null, dirtyCount: 0 }; }
}

function collectThreads() {
  const out = [];
  if (!fs.existsSync(THREADS_DIR)) return out;
  for (const name of fs.readdirSync(THREADS_DIR)) {
    const d = path.join(THREADS_DIR, name);
    if (!fs.statSync(d).isDirectory()) continue;
    if (!fs.existsSync(path.join(d, 'pid'))) continue;
    const pid = safeRead(path.join(d, 'pid'));
    const started = Number(safeRead(path.join(d, 'started')) || 0);
    const endedRaw = safeRead(path.join(d, 'ended'));
    const ended = endedRaw ? Number(endedRaw) : null;
    const exitRaw = safeRead(path.join(d, 'exit'));
    const model = safeRead(path.join(d, 'model'));
    const worktree = safeRead(path.join(d, 'worktree'));
    const session = safeRead(path.join(d, 'session'));
    const stderr = safeRead(path.join(d, 'stderr.log'));
    const prompt = safeRead(path.join(d, 'prompt.md'));
    const alive = pidAlive(pid);
    let state = 'killed';
    if (alive) state = 'running';
    else if (exitRaw !== null) state = (exitRaw === '0' ? 'done' : `failed:${exitRaw}`);
    else state = 'killed';
    const now = Math.floor(Date.now() / 1000);
    const end = (state === 'running') ? now : (ended || now);
    const elapsedSec = started ? Math.max(0, end - started) : 0;
    const log = parseLog(path.join(d, 'log.jsonl'));
    const gi = worktree ? gitInfo(worktree) : { branch: null, dirtyCount: 0 };
    // last activity: prefer log timestamp else started
    const lastActivity = log.lastTimestamp ? new Date(log.lastTimestamp).toISOString() : (started ? new Date(started*1000).toISOString() : null);
    // stall detection: running but no log update in > 5min
    let stalled = false;
    if (state === 'running' && log.lastTimestamp) {
      const ageSec = (Date.now() - log.lastTimestamp) / 1000;
      if (ageSec > 300) stalled = true;
    }
    out.push({
      name, pid, state, alive, exitCode: exitRaw, started, ended, elapsedSec,
      elapsedMin: Math.floor(elapsedSec / 60),
      model, worktree, session, branch: gi.branch, dirtyCount: gi.dirtyCount,
      log, lastActivity, stalled,
      stderr: stderr ? stderr.slice(-1500) : '',
      prompt: prompt ? prompt.slice(0, 2000) : ''
    });
  }
  // sort running first then by started desc
  out.sort((a,b) => {
    const ra = a.state==='running'?0:1, rb=b.state==='running'?0:1;
    if (ra!==rb) return ra-rb;
    return (b.started||0)-(a.started||0);
  });
  return out;
}

function heartbeat() {
  const hbPid = safeRead(path.join(ROOT, 'heartbeat.pid'));
  const cmdFile = '/proc/' + hbPid + '/cmdline';
  let cmd = '';
  try { cmd = fs.readFileSync(cmdFile,'utf8').replace(/\0/g,' ').trim(); } catch {}
  const alive = pidAlive(hbPid);
  // interval & status file
  const status = safeRead(path.join(ROOT, 'status'));
  return { pid: hbPid, alive, cmd, status };
}

function collectState() {
  const threads = collectThreads();
  const totals = threads.reduce((acc,t) => {
    acc.input += t.log.tokens.input;
    acc.output += t.log.tokens.output;
    acc.cacheRead += t.log.tokens.cacheRead;
    acc.cost += t.log.cost;
    acc.toolCalls += t.log.toolCalls;
    acc.steps += t.log.steps;
    return acc;
  }, { input:0, output:0, cacheRead:0, cost:0, toolCalls:0, steps:0 });
  return {
    generatedAt: new Date().toISOString(),
    status: heartbeat().status,
    heartbeat: { pid: heartbeat().pid, alive: heartbeat().alive, cmd: heartbeat().cmd },
    totals,
    threadCount: threads.length,
    runningCount: threads.filter(t=>t.state==='running').length,
    threads
  };
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (url.pathname === '/api/state') {
    const data = collectState();
    res.writeHead(200, { 'Content-Type':'application/json', 'Cache-Control':'no-store' });
    res.end(JSON.stringify(data));
    return;
  }
  if (url.pathname === '/api/thread/' ) {}
  // static
  let file = url.pathname === '/' ? '/index.html' : url.pathname;
  const full = path.join(__dirname, 'public', file);
  if (!full.startsWith(path.join(__dirname,'public'))) { res.writeHead(403); res.end(); return; }
  fs.readFile(full, (err, buf) => {
    if (err) { res.writeHead(404); res.end('not found'); return; }
    const ext = path.extname(full).toLowerCase();
    const mime = { '.html':'text/html', '.js':'application/javascript', '.css':'text/css', '.json':'application/json' }[ext] || 'application/octet-stream';
    res.writeHead(200, { 'Content-Type': mime });
    res.end(buf);
  });
});

server.listen(PORT, () => {
  console.log(`Agent orchestration dashboard listening on http://localhost:${PORT}`);
});