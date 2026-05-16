// ⚠️ 請填入你的 Supabase 專案資訊（在 Supabase Dashboard → Settings → API 取得）
const SUPABASE_URL = 'https://jdiemmwmewsfqkiongde.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkaWVtbXdtZXdzZnFraW9uZ2RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4OTk3MzYsImV4cCI6MjA5NDQ3NTczNn0.jB4JvsnBjXZ5NmwQ9vpilM9QS_xPRhw61UG74BNWVZU';

const db = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
