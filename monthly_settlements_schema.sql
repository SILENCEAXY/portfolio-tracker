-- ============================================
-- Portfolio Tracker - Monthly Settlements
-- ============================================

CREATE TABLE IF NOT EXISTS monthly_settlements (
    id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id         UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    year            INTEGER NOT NULL,
    month           INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    -- Realized P&L from closed trades in that month (in USD-equivalent for sorting; original currency stored)
    realized_pnl    NUMERIC(14,4) NOT NULL DEFAULT 0,
    realized_pct    NUMERIC(8,4) NOT NULL DEFAULT 0,
    -- Unrealized P&L from positions still open at month end
    unrealized_pnl  NUMERIC(14,4) NOT NULL DEFAULT 0,
    unrealized_pct  NUMERIC(8,4) NOT NULL DEFAULT 0,
    -- Total cost basis at settlement time
    cost_basis      NUMERIC(14,4) NOT NULL DEFAULT 0,
    -- Market value at settlement time
    market_value    NUMERIC(14,4) NOT NULL DEFAULT 0,
    -- HK and US splits (for display)
    hk_pnl          NUMERIC(14,4) NOT NULL DEFAULT 0,
    us_pnl          NUMERIC(14,4) NOT NULL DEFAULT 0,
    hk_mv           NUMERIC(14,4) NOT NULL DEFAULT 0,
    us_mv           NUMERIC(14,4) NOT NULL DEFAULT 0,
    -- Snapshot of holdings JSON (so we can show details even if positions are later closed)
    holdings_json   JSONB NOT NULL DEFAULT '[]'::jsonb,
    closed_json     JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- Number of closed trades in the month
    closed_count    INTEGER NOT NULL DEFAULT 0,
    -- Settlement timestamp
    settled_at      TIMESTAMPTZ DEFAULT now(),
    -- Free-form note
    notes           TEXT DEFAULT '',
    -- One settlement per user per month
    UNIQUE(user_id, year, month)
);

CREATE INDEX IF NOT EXISTS idx_settlements_user_period
    ON monthly_settlements(user_id, year DESC, month DESC);

-- Enable RLS
ALTER TABLE monthly_settlements ENABLE ROW LEVEL SECURITY;

-- Drop old policies (idempotent)
DROP POLICY IF EXISTS "Users can view own settlements"   ON monthly_settlements;
DROP POLICY IF EXISTS "Users can insert own settlements" ON monthly_settlements;
DROP POLICY IF EXISTS "Users can update own settlements" ON monthly_settlements;
DROP POLICY IF EXISTS "Users can delete own settlements" ON monthly_settlements;

CREATE POLICY "Users can view own settlements"
    ON monthly_settlements FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settlements"
    ON monthly_settlements FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settlements"
    ON monthly_settlements FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own settlements"
    ON monthly_settlements FOR DELETE
    USING (auth.uid() = user_id);
