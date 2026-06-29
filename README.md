# Portfolio Tracker

港股 + 美股 持倉追蹤工具，多裝置雲端同步。

## 線上使用
👉 https://silenceaxy.github.io/

## 架構
```
GitHub Pages (前端, repo 根目錄)
  ↓
Cloudflare Worker (報價 API)
  ↓
騰訊財經 (港股/美股即時報價)
  +
Supabase (雲端資料庫 + 認證)
```

## 部署結構
- `/worker/` — Cloudflare Worker (報價反代)
- `/index.html` — GitHub Pages 靜態網站 (根目錄)

## 本地開發
1. 進入 `worker/`，用 wrangler 部署：
   ```
   npx wrangler deploy
   ```
2. 修改 `docs/index.html` 的 CONFIG 後推 GitHub
