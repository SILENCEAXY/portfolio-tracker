-- ============================================
-- Portfolio Tracker - Holdings History
-- ============================================

-- 1. Holdings history table (已平倉記錄)
CREATE TABLE IF NOT EXISTS holdings_history (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    symbol      TEXT NOT NULL,
    name        TEXT DEFAULT '',
    market      TEXT NOT NULL CHECK (market IN ('HK', 'US')),
    buy_price   NUMERIC(12,4) NOT NULL,
    sell_price  NUMERIC(12,4) NOT NULL,
    quantity    INTEGER NOT NULL,
    buy_date    DATE NOT NULL,
    sell_date   DATE NOT NULL,
    pnl         NUMERIC(14,4) NOT NULL,
    pnl_pct     NUMERIC(8,4) NOT NULL,
    notes       TEXT DEFAULT '',
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. Indexes
CREATE INDEX IF NOT EXISTS idx_history_user_id ON holdings_history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_user_sell_date ON holdings_history(user_id, sell_date DESC);

-- 3. Enable RLS
ALTER TABLE holdings_history ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
DROP POLICY IF EXISTS "Users can view own history" ON holdings_history;
DROP POLICY IF EXISTS "Users can insert own history" ON holdings_history;
DROP POLICY IF EXISTS "Users can delete own history" ON holdings_history;

CREATE POLICY "Users can view own history"
    ON holdings_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history"
    ON holdings_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own history"
    ON holdings_history FOR DELETE
    USING (auth.uid() = user_id);
