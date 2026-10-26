// ════════════════════════════════════════════════════════════════
// HiFives — Edge Function « hifives-push » : notifications push (Web Push + VAPID)
//
// À créer dans Supabase > Edge Functions > Deploy a new function > Via Editor,
// nom : hifives-push, coller ce fichier, Deploy (laisser « Verify JWT » activé).
//
// Appelée chaque minute par la tâche planifiée (migration 019) :
//   1. rappel du défi sponsorisé du jour à 18 h (à ceux qui ne l'ont pas encore relevé) ;
//   2. envoi des notifications en attente, une seule notification par personne (regroupées),
//      jamais entre 22 h et 8 h (heure de Paris), au plus une toutes les 5 minutes par personne.
// GET ?key : renvoie la clé publique VAPID (utilisée par l'appli pour s'abonner).
//
// Aucune dépendance externe : chiffrement aes128gcm (RFC 8291) et signature VAPID (RFC 8292)
// avec WebCrypto. Les clés VAPID sont générées au premier appel et gardées dans push_config,
// table lisible uniquement côté serveur. SUPABASE_URL et SUPABASE_SERVICE_ROLE_KEY sont fournis
// automatiquement par Supabase à la fonction.
// ════════════════════════════════════════════════════════════════

const APP_URL = 'https://hifives5.github.io/';
const SUBJECT = 'https://hifives5.github.io';
const DAILY_HOUR = 18;          // rappel du défi du jour
const QUIET_FROM = 22, QUIET_TO = 8;   // pas de notification la nuit
const MIN_GAP_MS = 5 * 60 * 1000;      // anti-rafale par personne

const env = (k) => (globalThis.Deno ? globalThis.Deno.env.get(k) : globalThis.process?.env[k]);
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type, x-client-info',
};
const json = (o, status = 200) => new Response(JSON.stringify(o), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

// ── Outils binaires
const enc = new TextEncoder();
const b64u = (buf) => btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
const unb64u = (s) => Uint8Array.from(atob(s.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - s.length % 4) % 4)), (c) => c.charCodeAt(0));
const concat = (...parts) => {
  const out = new Uint8Array(parts.reduce((n, p) => n + p.length, 0));
  let i = 0;
  for (const p of parts) { out.set(p, i); i += p.length; }
  return out;
};

// ── Base de données (API REST, clé serveur)
async function db(path, opts = {}) {
  const key = env('SUPABASE_SERVICE_ROLE_KEY');
  const res = await fetch(`${env('SUPABASE_URL')}/rest/v1/${path}`, {
    ...opts,
    headers: { apikey: key, Authorization: 'Bearer ' + key, 'Content-Type': 'application/json', ...(opts.headers || {}) },
  });
  if (!res.ok) throw new Error(`${opts.method || 'GET'} ${path.split('?')[0]} → ${res.status} ${await res.text()}`);
  const t = await res.text();
  return t ? JSON.parse(t) : null;
}

// ── Clés VAPID (générées une fois, gardées côté serveur)
let vapid = null;
async function getVapid() {
  if (vapid) return vapid;
  let rows = await db('push_config?key=eq.vapid&select=value');
  if (!rows.length) {
    const kp = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
    const value = {
      jwk: await crypto.subtle.exportKey('jwk', kp.privateKey),
      publicKey: b64u(await crypto.subtle.exportKey('raw', kp.publicKey)),
    };
    await db('push_config?on_conflict=key', { method: 'POST', headers: { Prefer: 'resolution=ignore-duplicates' }, body: JSON.stringify({ key: 'vapid', value }) });
    rows = await db('push_config?key=eq.vapid&select=value');   // relu : en cas d'appels simultanés, une seule paire gagne
  }
  vapid = rows[0].value;
  return vapid;
}
async function vapidAuth(endpoint) {
  const v = await getVapid();
  const head = b64u(enc.encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const body = b64u(enc.encode(JSON.stringify({ aud: new URL(endpoint).origin, exp: Math.floor(Date.now() / 1000) + 12 * 3600, sub: SUBJECT })));
  const key = await crypto.subtle.importKey('jwk', v.jwk, { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  const sig = await crypto.subtle.sign({ name: 'ECDSA', hash: 'SHA-256' }, key, enc.encode(head + '.' + body));
  return `vapid t=${head}.${body}.${b64u(sig)}, k=${v.publicKey}`;
}

// ── Chiffrement du message (RFC 8291, aes128gcm)
async function hkdf(salt, ikm, info, len) {
  const k = await crypto.subtle.importKey('raw', ikm, 'HKDF', false, ['deriveBits']);
  return new Uint8Array(await crypto.subtle.deriveBits({ name: 'HKDF', hash: 'SHA-256', salt, info }, k, len * 8));
}
async function encrypt(sub, text) {
  const uaPub = unb64u(sub.p256dh), auth = unb64u(sub.auth);
  const eph = await crypto.subtle.generateKey({ name: 'ECDH', namedCurve: 'P-256' }, true, ['deriveBits']);
  const asPub = new Uint8Array(await crypto.subtle.exportKey('raw', eph.publicKey));
  const uaKey = await crypto.subtle.importKey('raw', uaPub, { name: 'ECDH', namedCurve: 'P-256' }, false, []);
  const shared = new Uint8Array(await crypto.subtle.deriveBits({ name: 'ECDH', public: uaKey }, eph.privateKey, 256));
  const ikm = await hkdf(auth, shared, concat(enc.encode('WebPush: info\0'), uaPub, asPub), 32);
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const cek = await hkdf(salt, ikm, enc.encode('Content-Encoding: aes128gcm\0'), 16);
  const nonce = await hkdf(salt, ikm, enc.encode('Content-Encoding: nonce\0'), 12);
  const key = await crypto.subtle.importKey('raw', cek, 'AES-GCM', false, ['encrypt']);
  const ct = new Uint8Array(await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, key, concat(enc.encode(text), new Uint8Array([2]))));
  return concat(salt, new Uint8Array([0, 0, 16, 0]), new Uint8Array([asPub.length]), asPub, ct);   // en-tête : sel, taille 4096, clé
}
async function sendPush(sub, msg) {
  const res = await fetch(sub.endpoint, {
    method: 'POST',
    headers: {
      Authorization: await vapidAuth(sub.endpoint), 'Content-Encoding': 'aes128gcm',
      'Content-Type': 'application/octet-stream', TTL: '86400', Urgency: 'normal',
    },
    body: await encrypt(sub, JSON.stringify(msg)),
  });
  return res.status;
}

// ── Textes (mêmes formulations que la cloche de l'appli)
const PREF = { comment: 'comment', hi5: 'hi5', badge: 'progress', level: 'progress', soulmate: 'progress', invite: 'invite', daily: 'daily' };
function line(n) {
  const who = n.actor?.handle || "Quelqu'un";
  const t = n.topic?.title ? n.topic.title.replace(/^Top 5 /, 'ton top 5 ') : 'ton top';
  const d = n.data || {};
  switch (n.kind) {
    case 'comment': return `💬 ${who} a commenté ${t}${d.body ? ` : « ${d.body} »` : ''}`;
    case 'hi5': { const c = d.count || 1; return `✋ ${who}${c > 1 ? ` et ${c - 1} autre${c > 2 ? 's' : ''}` : ''} ${c > 1 ? 'ont' : 'a'} fait un high five sur ${t}`; }
    case 'badge': return `${d.emoji || '🏅'} Nouveau badge : ${d.label || ''} (+${d.points || 0} pts)`;
    case 'level': return `🎉 Niveau ${d.level} débloqué ! Va voir ce que tu gagnes`;
    case 'invite': return `🤝 ${who} a fait ${n.topic?.title ? n.topic.title.replace(/^Top 5 /, 'son top 5 ') : 'son top'} grâce à ton lien${d.pct != null ? ` : compatibles à ${d.pct} %` : ''}`;
    case 'soulmate': return `💞 Radar : ${who} est ton âme sœur à ${d.pct} %`;
    case 'daily': return `⭐ ${d.text || "Le défi du jour t'attend !"}`;
    default: return 'Du nouveau sur HiFives';
  }
}
const parisHour = () => +new Intl.DateTimeFormat('fr-FR', { timeZone: 'Europe/Paris', hour: 'numeric', hourCycle: 'h23' }).format(new Date());
const parisDate = () => new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Paris' }).format(new Date());   // AAAA-MM-JJ
const prefOn = (p, kind) => ((p && p.notif_prefs) || {})[PREF[kind]] !== false;

// 1. Rappel du défi du jour (une fois par jour et par personne abonnée qui ne l'a pas relevé)
async function daily() {
  const h = parisHour();
  if (h < DAILY_HOUR || h >= QUIET_FROM) return 0;
  const now = new Date().toISOString(), today = parisDate();
  const ch = await db(`sponsored_challenges?select=topic_id,bonus_points,topics(title)&starts_at=lte.${now}&ends_at=gt.${now}&order=starts_at.desc&limit=1`);
  if (!ch.length || !ch[0].topics) return 0;
  const c = ch[0];
  const users = [...new Set((await db('push_subscriptions?select=user_id')).map((s) => s.user_id))];
  if (!users.length) return 0;
  const ids = users.join(',');
  const [profs, done, already] = await Promise.all([
    db(`profiles?select=id,notif_prefs&id=in.(${ids})`),
    db(`tops?select=user_id&topic_id=eq.${c.topic_id}&user_id=in.(${ids})`),
    db(`notifications?select=user_id&kind=eq.daily&data->>date=eq.${today}&user_id=in.(${ids})`),
  ]);
  const skip = new Set([...done, ...already].map((x) => x.user_id));
  const rows = profs.filter((p) => !skip.has(p.id) && prefOn(p, 'daily')).map((p) => ({
    user_id: p.id, kind: 'daily', topic_id: c.topic_id,
    data: { date: today, text: `Défi sponsorisé du jour : ${c.topics.title} (+${50 + (c.bonus_points || 0)} pts). À toi de jouer !` },
  }));
  if (rows.length) await db('notifications', { method: 'POST', body: JSON.stringify(rows) });
  return rows.length;
}

// 2. Envoi des notifications en attente : une seule par personne, regroupée
async function sendPending() {
  const h = parisHour();
  if (h >= QUIET_FROM || h < QUIET_TO) return { quiet: true, sent: 0 };
  const since = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const list = await db(`notifications?select=id,user_id,kind,data,topic_id,read_at,actor:profiles!notifications_actor_id_fkey(handle),topic:topics(title)`
    + `&pushed_at=is.null&created_at=gte.${since}&order=created_at.asc&limit=500`);
  if (!list.length) return { sent: 0 };
  const users = [...new Set(list.map((n) => n.user_id))].join(',');
  const [subs, profs] = await Promise.all([
    db(`push_subscriptions?select=id,user_id,endpoint,p256dh,auth,last_push_at&user_id=in.(${users})`),
    db(`profiles?select=id,notif_prefs&id=in.(${users})`),
  ]);
  const profOf = Object.fromEntries(profs.map((p) => [p.id, p]));
  const done = [];
  let sent = 0;
  for (const u of new Set(list.map((n) => n.user_id))) {
    const mine = list.filter((n) => n.user_id === u);
    const uSubs = subs.filter((s) => s.user_id === u);
    // Envoyée il y a moins de 5 min : on garde pour le prochain regroupement
    if (uSubs.some((s) => s.last_push_at && Date.now() - new Date(s.last_push_at).getTime() < MIN_GAP_MS)) continue;
    done.push(...mine.map((n) => n.id));
    const items = mine.filter((n) => !n.read_at && prefOn(profOf[u], n.kind));
    if (!items.length || !uSubs.length) continue;
    const last = items[items.length - 1];
    const msg = items.length === 1
      ? { title: 'HiFives', body: line(last), url: last.kind === 'daily' && last.topic_id ? `${APP_URL}?t=${last.topic_id}` : `${APP_URL}?n=1`, tag: 'hifives-' + last.kind }
      : { title: `HiFives · ${items.length} nouveautés`, body: items.slice(-3).reverse().map(line).join('\n'), url: `${APP_URL}?n=1`, tag: 'hifives' };
    for (const s of uSubs) {
      let status = 0;
      try { status = await sendPush(s, msg); } catch (e) { status = 0; }
      if (status === 404 || status === 410) await db(`push_subscriptions?id=eq.${s.id}`, { method: 'DELETE' });   // abonnement expiré
      else if (status >= 200 && status < 300) { sent++; await db(`push_subscriptions?id=eq.${s.id}`, { method: 'PATCH', body: JSON.stringify({ last_push_at: new Date().toISOString() }) }); }
    }
  }
  for (let i = 0; i < done.length; i += 100) {
    await db(`notifications?id=in.(${done.slice(i, i + 100).join(',')})`, { method: 'PATCH', body: JSON.stringify({ pushed_at: new Date().toISOString() }) });
  }
  return { sent, processed: done.length };
}

async function handle(req) {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  try {
    if (new URL(req.url).searchParams.has('key')) return json({ publicKey: (await getVapid()).publicKey });
    const d = await daily();
    return json({ daily: d, ...(await sendPending()) });
  } catch (e) {
    return json({ error: String((e && e.message) || e) }, 500);
  }
}

if (globalThis.Deno) globalThis.Deno.serve(handle);
export { handle, encrypt, vapidAuth, line };
