/**
 * Cloudflare Worker: qt-proxy
 * Portfolio Tracker 報價代理 (港股 + 美股)
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey'
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders, status: 204 });
    }

    if (url.pathname === '/api/health') {
      return Response.json(
        { status: 'ok', service: 'qt-proxy', version: '1.1.0' },
        { headers: corsHeaders }
      );
    }

    if (url.pathname === '/api/quote') {
      return handleQuote(url, corsHeaders);
    }

    return Response.json(
      { error: 'Not Found' },
      { status: 404, headers: corsHeaders }
    );
  }
};

async function handleQuote(url, corsHeaders) {
  try {
    const symbolsRaw = url.searchParams.get('symbols') || '';
    const holdingsRaw = url.searchParams.get('holdings') || '';

    // 收集 holdings 與對應的 tencent symbols
    // 用 market+symbol 作為去重 key，保留 holdings list 對應回 id
    const holdings = [];
    if (holdingsRaw) {
      try { holdings.push(...JSON.parse(holdingsRaw)); } catch {}
    }

    // 去重 tencent symbols (避免重複打 API)，但保留每筆 id 的 mapping
    const tsToIds = {}; // tencentSymbol -> [id, id, ...]
    const tencentSymbols = [];
    for (const h of holdings) {
      const ts = toTencentSymbol(h);
      if (!tsToIds[ts]) {
        tsToIds[ts] = [];
        tencentSymbols.push(ts);
      }
      tsToIds[ts].push(h.id);
    }

    if (tencentSymbols.length === 0 && symbolsRaw) {
      tencentSymbols.push(...symbolsRaw.split(',').map(s => s.trim()).filter(Boolean));
    }

    if (tencentSymbols.length === 0) {
      return Response.json(
        { error: 'Missing symbols or holdings parameter' },
        { status: 400, headers: corsHeaders }
      );
    }

    const qtUrl = 'https://qt.gtimg.cn/q=' + tencentSymbols.join(',');
    const resp = await fetch(qtUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; StockTracker/1.0)',
        'Referer': 'https://stockapp.finance.qq.com/'
      }
    });

    if (!resp.ok) {
      return Response.json(
        { error: 'Upstream error: ' + resp.status },
        { status: 502, headers: corsHeaders }
      );
    }

    const raw = await resp.text();
    const results = {};
    const lines = raw.split('\n').filter(l => l.trim());

    // 解析每行，每個 tencent symbol 對應到所有 holdings id
    for (const line of lines) {
      const parsed = parseTencentLine(line);
      if (parsed) {
        const ids = tsToIds[parsed.symbol] || [];
        if (ids.length === 0) {
          // 沒有對應 holdings (只用 symbols 呼叫的情況)
          results[parsed.symbol] = { ok: true, data: parsed };
        } else {
          for (const id of ids) {
            results[id] = { ok: true, data: parsed };
          }
        }
      }
    }

    // 為每個 holding id 補上 fallback (避免缺漏)
    for (const ts of tencentSymbols) {
      const ids = tsToIds[ts] || [];
      for (const id of ids) {
        if (!results[id]) {
          results[id] = { ok: false, error: 'No data' };
        }
      }
    }

    return Response.json(
      { source: 'tencent-finance', results },
      { headers: corsHeaders }
    );
  } catch (e) {
    return Response.json(
      { error: 'Proxy error: ' + e.message },
      { status: 500, headers: corsHeaders }
    );
  }
}

function toTencentSymbol(h) {
  if (h.market === 'HK') return 'hk' + h.symbol.padStart(5, '0');
  return 'us' + h.symbol.toUpperCase();
}

function parseTencentLine(line) {
  const m = line.match(/v_(\w+)="([^"]+)"/);
  if (!m) return null;

  const symbol = m[1];
  const data = m[2].split('~');
  if (data.length < 36) return null;

  const toFloat = (v, d = 0) => {
    try { return parseFloat(v); } catch { return d; }
  };

  return {
    symbol: symbol,
    name: data[1],
    price: toFloat(data[3]),
    prevClose: toFloat(data[4]),
    open: toFloat(data[5]),
    volume: toFloat(data[6]),
    change: toFloat(data[31]),
    changePct: toFloat(data[32]),
    high: toFloat(data[33]),
    low: toFloat(data[34]),
    currency: symbol.startsWith('hk') ? 'HKD' : 'USD',
    time: data[30] || ''
  };
}
