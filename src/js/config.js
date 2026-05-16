// ⚠️ 請填入你的 Supabase 專案資訊（在 Supabase Dashboard → Settings → API 取得）
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const db = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
