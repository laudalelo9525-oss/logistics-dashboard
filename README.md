# Safetech Control Center — Phase 1 scaffold

This branch adds the initial scaffold for the frontend (Vite + React + TypeScript + Tailwind) and the Supabase DB initialization SQL (db/init.sql).

Next steps (Phase 2):
- Implement Supabase Auth + role-based routing
- Seed admin user (laudalelo9525@gmail.com) in Supabase users table after creating the auth user

Local run:
1. npm install
2. Create .env file from .env.example and add VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
3. npm run dev

Apply DB schema:
- Open Supabase SQL editor and run db/init.sql
- After creating the Supabase auth user for admin, insert the mapping into users table (see bootstrap comment in db/init.sql)
