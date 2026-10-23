// NOVAPLAY provider — Oshada's private catalog, served by the
// nova-catalog Cloudflare Worker. Written for the Zangetsu/WatchApp
// provider contract (see providers/_template.js).
//
// Catalog entries come from his admin dashboard:
//   - direct MP4 entries play their stored URL as-is;
//   - Facebook entries are added by VIDEO ID only. The worker resolves
//     and caches a source URL (+ expiry) at save time. This provider
//     serves the cached URL while it is valid and calls the worker's
//     /refresh ONLY after it has expired — the fresh link then replaces
//     the stored one server-side (his exact rule for NovaPlay).
//
// The catalog app key is a low-value, revocable key (same one the
// Kotlin NovaPlay app carries). In this public repo it stays a
// placeholder; the build injects the real key from a CI secret.

var SOURCE_ID = 'nova';
var BASE = 'https://nova-catalog.oshadakalindu.workers.dev';
var APP_KEY = '__NOVAPLAY_APP_KEY__';

function getInfo() {
  return { name: 'NovaPlay', lang: 'en', baseUrl: BASE,
           logo: '', type: 'movie', version: '1.0.0' };
}

var _cache = { at: 0, items: null };

function _catalog(force) {
  var now = Date.now();
  if (!force && _cache.items && now - _cache.at < 30000) {
    return Promise.resolve(_cache.items);
  }
  return fetch(BASE + '/catalog', { headers: { 'X-App-Key': APP_KEY } })
    .then(function (r) {
      var d = JSON.parse(r.body || '{}');
      _cache = { at: now, items: d.items || [] };
      return _cache.items;
    });
}

function _card(it) {
  return {
    id: it.id, title: it.title,
    url: 'nova://' + it.id,
    cover: it.poster || it.backdrop || '',
    type: 'movie', sourceId: SOURCE_ID
  };
}

function search(query, page, opts) {
  var q = String(query || '').toLowerCase();
  return _catalog(false).then(function (items) {
    return items.filter(function (it) {
      return q === '' || String(it.title || '').toLowerCase().indexOf(q) !== -1;
    }).map(_card);
  });
}

// Home rows: the whole library first (the app uses the first section
// for the hero), then Movies / Series splits.
function getHome(opts) {
  return _catalog(false).then(function (items) {
    var all = items.map(_card);
    var movies = items.filter(function (i) { return i.type !== 'series'; }).map(_card);
    var series = items.filter(function (i) { return i.type === 'series'; }).map(_card);
    var out = [];
    if (all.length) out.push({ title: 'My Library', items: all });
    if (movies.length) out.push({ title: 'Movies', items: movies });
    if (series.length) out.push({ title: 'Series', items: series });
    return out;
  });
}

function _find(items, id) {
  for (var i = 0; i < items.length; i++) {
    if (items[i].id === id) return items[i];
  }
  return null;
}

function _episodesOf(it) {
  if (it.type === 'series') {
    return (it.episodes || []).map(function (e, i) {
      return {
        id: it.id + '_e' + i,
        title: e.title || ('Episode ' + (e.n || (i + 1))),
        number: parseInt(e.n, 10) || (i + 1),
        url: 'nova://' + it.id + '/e/' + i
      };
    });
  }
  return [{ id: it.id + '_e0', title: it.title, number: 1, url: 'nova://' + it.id }];
}

function getDetail(url) {
  var id = String(url || '').replace('nova://', '').split('/')[0];
  return _catalog(false).then(function (items) {
    var it = _find(items, id);
    if (!it) return null;
    return {
      id: it.id, title: it.title, url: 'nova://' + it.id,
      cover: it.backdrop || it.poster || '',
      description: it.overview || '',
      status: 'completed', genres: [], studios: [],
      type: 'movie', sourceId: SOURCE_ID,
      episodes: _episodesOf(it)
    };
  });
}

function getEpisodes(seriesUrl) {
  return getDetail(seriesUrl).then(function (d) {
    return d ? d.episodes : [];
  });
}

function _source(u) {
  return { url: u, quality: '', container: 'mp4',
           headers: {}, kind: 'raw', audioLang: '', subtitles: [] };
}

function getVideoSources(epUrl) {
  var m = /^nova:\/\/([^\/]+)(?:\/e\/(\d+))?$/.exec(String(epUrl || ''));
  if (!m) return [];
  var id = m[1];
  var epIdx = (m[2] === undefined) ? null : parseInt(m[2], 10);
  return _catalog(false).then(function (items) {
    var it = _find(items, id);
    if (!it) return [];
    var t = (epIdx === null) ? it : (it.episodes || [])[epIdx];
    if (!t) return [];
    if (!t.fb_id) {
      return t.url ? [_source(t.url)] : [];
    }
    var now = Math.floor(Date.now() / 1000);
    if (t.url && (t.url_exp || 0) > now + 60) {
      return [_source(t.url)];  // cached link still valid — no refresh
    }
    // Expired (or never resolved): pull a fresh link; the worker
    // replaces its stored copy, and we update the local cache too.
    var body = { id: id };
    if (epIdx !== null) body.ep = epIdx;
    return fetch(BASE + '/refresh', {
      method: 'POST',
      headers: { 'X-App-Key': APP_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function (r) {
      var d = JSON.parse(r.body || '{}');
      if (d.url) {
        t.url = d.url;
        t.url_exp = d.url_exp || 0;
        return [_source(d.url)];
      }
      return t.url ? [_source(t.url)] : [];
    }).catch(function () {
      return t.url ? [_source(t.url)] : [];
    });
  });
}
