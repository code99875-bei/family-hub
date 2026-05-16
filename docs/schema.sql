-- ============================================================
-- Family Hub — Supabase Schema
-- 使用方式：在 Supabase SQL Editor 執行此檔案
-- ============================================================

-- 1. 成員資料表（固定清單）
CREATE TABLE IF NOT EXISTS family_members (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  role TEXT,
  color TEXT NOT NULL,
  display_order INT DEFAULT 0
);

INSERT INTO family_members VALUES
  ('bei',     '貝',   '我',   '#5BB8E8', 1),
  ('qun',     '群',   '先生', '#7B5EA7', 2),
  ('az',      'AZ',   '兒子', '#1A3A6B', 3),
  ('emma',    'Emma', '女兒', '#F4A7B9', 4),
  ('grandpa', '爺爺', '公公', '#2D6A2D', 5),
  ('grandma', '阿嬤', '婆婆', '#6AAB5E', 6),
  ('uncle',   '叔叔', '其他', '#E8943A', 7)
ON CONFLICT (id) DO NOTHING;

-- 2. 使用者 ↔ 成員對應
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  member_id TEXT REFERENCES family_members(id) NOT NULL,
  display_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. 行事曆事件
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  date DATE NOT NULL,
  start_time TIME,
  end_time TIME,
  depart_time TIME,
  return_time TIME,
  notes TEXT,
  members TEXT[] NOT NULL DEFAULT '{}',  -- array of member IDs
  -- 重複設定
  recurrence_type TEXT DEFAULT 'none',   -- none / daily / weekly / monthly
  recurrence_days INT[],                 -- weekly: 0=Sun...6=Sat
  recurrence_day_of_month INT,           -- monthly: 幾號
  recurrence_end DATE,                   -- 重複結束日
  -- 單次覆蓋
  parent_event_id UUID REFERENCES calendar_events(id) ON DELETE CASCADE,
  is_cancelled BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. 家計簿收入
CREATE TABLE IF NOT EXISTS family_income (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  amount NUMERIC NOT NULL,
  source TEXT NOT NULL,  -- '貝的固定撥款' / '群的撥款'
  notes TEXT,
  auto_generated BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. 家計簿支出
CREATE TABLE IF NOT EXISTS family_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT NOT NULL,
  payment_method TEXT NOT NULL,  -- 現金 / 轉帳 / 刷卡
  notes TEXT,
  recorded_by TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. 個人帳戶
CREATE TABLE IF NOT EXISTS personal_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,              -- 'bank' / 'cash'
  initial_balance NUMERIC DEFAULT 0,
  is_emergency BOOLEAN DEFAULT FALSE,
  display_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. 個人收支紀錄
CREATE TABLE IF NOT EXISTS personal_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  amount NUMERIC NOT NULL,
  type TEXT NOT NULL,              -- 'income' / 'expense'
  payment_method TEXT NOT NULL,   -- 現金 / 轉帳 / 信用卡刷卡
  account_id UUID REFERENCES personal_accounts(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. 分期付款計畫
CREATE TABLE IF NOT EXISTS personal_installments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  total_amount NUMERIC NOT NULL,
  installment_amount NUMERIC NOT NULL,
  total_periods INT NOT NULL,
  start_ym TEXT NOT NULL,           -- YYYY-MM，起始月份
  account_id UUID REFERENCES personal_accounts(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'active',     -- active / completed
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. 每期付款紀錄（建立分期計畫時自動產生）
CREATE TABLE IF NOT EXISTS personal_installment_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installment_id UUID REFERENCES personal_installments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  period_index INT NOT NULL,        -- 第幾期（0-based）
  ym TEXT NOT NULL,                 -- YYYY-MM
  amount NUMERIC NOT NULL,
  status TEXT DEFAULT 'pending',    -- pending / paid
  paid_date DATE,
  transaction_id UUID REFERENCES personal_transactions(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- personal_transactions 新增帳戶轉移欄位
ALTER TABLE personal_transactions
  ADD COLUMN IF NOT EXISTS transfer_group_id UUID;

-- ============================================================
-- updated_at 自動更新 trigger
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calendar_events_updated_at
  BEFORE UPDATE ON calendar_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================
-- RLS 政策
-- ============================================================
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_income ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_transactions ENABLE ROW LEVEL SECURITY;

-- family_members: 所有登入者可讀
CREATE POLICY "family_members_read" ON family_members
  FOR SELECT TO authenticated USING (true);

-- user_profiles: 只能讀寫自己的
CREATE POLICY "user_profiles_select" ON user_profiles
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "user_profiles_insert" ON user_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_profiles_update" ON user_profiles
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- calendar_events: 所有登入者可讀寫（家庭共用）
CREATE POLICY "calendar_events_select" ON calendar_events
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "calendar_events_insert" ON calendar_events
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "calendar_events_update" ON calendar_events
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "calendar_events_delete" ON calendar_events
  FOR DELETE TO authenticated USING (true);

-- family_income / family_expenses: 家庭共用
CREATE POLICY "family_income_select" ON family_income
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "family_income_insert" ON family_income
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "family_income_update" ON family_income
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "family_income_delete" ON family_income
  FOR DELETE TO authenticated USING (true);

CREATE POLICY "family_expenses_select" ON family_expenses
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "family_expenses_insert" ON family_expenses
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "family_expenses_update" ON family_expenses
  FOR UPDATE TO authenticated USING (true);
CREATE POLICY "family_expenses_delete" ON family_expenses
  FOR DELETE TO authenticated USING (true);

-- personal_accounts / personal_transactions / installments: 僅自己可見
CREATE POLICY "personal_accounts_own" ON personal_accounts
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "personal_transactions_own" ON personal_transactions
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "installments_own" ON personal_installments
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "installment_payments_own" ON personal_installment_payments
  FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 授權 anon / authenticated 存取
-- ============================================================
GRANT ALL ON family_members TO anon, authenticated;
GRANT ALL ON user_profiles TO anon, authenticated;
GRANT ALL ON calendar_events TO anon, authenticated;
GRANT ALL ON family_income TO anon, authenticated;
GRANT ALL ON family_expenses TO anon, authenticated;
GRANT ALL ON personal_accounts TO anon, authenticated;
GRANT ALL ON personal_transactions TO anon, authenticated;
GRANT ALL ON personal_installments TO anon, authenticated;
GRANT ALL ON personal_installment_payments TO anon, authenticated;

-- 通知 PostgREST 重新載入 schema
NOTIFY pgrst, 'reload schema';
