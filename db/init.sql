# Phase 1: Supabase schema for Safetech Control Center

-- Enums and tables
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('admin','controller','viewer');
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY,
  email text UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'viewer',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_no text UNIQUE NOT NULL,
  project_name text,
  location text,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS trailers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plate_no text UNIQUE NOT NULL,
  trailer_type text CHECK (trailer_type IN ('A-Frame','Flatbed','Truck Head')),
  supplier_id uuid REFERENCES suppliers(id) ON DELETE SET NULL,
  status text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dispatch_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trailer_id uuid REFERENCES trailers(id) ON DELETE SET NULL,
  project_no text,
  do_no text,
  shift text,
  diesel_status boolean DEFAULT false,
  driver_status boolean DEFAULT false,
  dn_status boolean DEFAULT false,
  leaving_status boolean DEFAULT false,
  remarks text,
  log_date date,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fleet_status (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trailer_id uuid REFERENCES trailers(id) ON DELETE SET NULL,
  status_text text,
  site_location text,
  driver_name text,
  driver_phone text,
  status_timestamp timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS deliveries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_no text,
  project_name text,
  location text,
  trailer_id uuid REFERENCES trailers(id) ON DELETE SET NULL,
  element_type text,
  element_count integer,
  dn_no text,
  volume_cum numeric,
  weight_tons numeric,
  remarks text,
  delivery_date date,
  created_at timestamptz DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_trailers_plate_no ON trailers(plate_no);
CREATE INDEX IF NOT EXISTS idx_dispatch_log_trailer_id ON dispatch_log(trailer_id);
CREATE INDEX IF NOT EXISTS idx_fleet_status_trailer_id ON fleet_status(trailer_id);

-- Enable RLS
ALTER TABLE dispatch_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE fleet_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE trailers ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Policies (admin full, controller write for specific tables, viewer read-only)

CREATE POLICY dispatch_admin_full ON dispatch_log
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY dispatch_controller_write ON dispatch_log
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')));

CREATE POLICY dispatch_view ON dispatch_log
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('viewer','controller','admin')));

CREATE POLICY fleet_admin_full ON fleet_status
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY fleet_controller_write ON fleet_status
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')));

CREATE POLICY fleet_view ON fleet_status
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('viewer','controller','admin')));

CREATE POLICY deliveries_admin_full ON deliveries
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY deliveries_controller_write ON deliveries
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('controller','admin')));

CREATE POLICY deliveries_view ON deliveries
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role IN ('viewer','controller','admin')));

CREATE POLICY trailers_admin_only ON trailers
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY suppliers_admin_only ON suppliers
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY projects_admin_only ON projects
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY users_admin_full ON users
  FOR ALL
  USING (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'));

CREATE POLICY users_self_select ON users
  FOR SELECT
  USING (id = auth.uid());

-- Bootstrap example (run after creating auth user):
-- INSERT INTO users (id, email, role) VALUES ('<AUTH_UID>', 'laudalelo9525@gmail.com', 'admin');
