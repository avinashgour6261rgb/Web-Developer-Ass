/*
# Auth helpers: profile trigger, view counter, admin seed

1. Functions
- `handle_new_user()` trigger: auto-creates a `profiles` row whenever a new auth user signs up, defaulting role to 'customer' (or the role supplied in raw_app_meta_data).
- `increment_views(row_id uuid)`: atomically bumps a property's view counter.

2. Triggers
- `on_auth_user_created` on `auth.users` AFTER INSERT → calls handle_new_user().

3. Admin seed
- Creates a demo admin auth user (admin@maison.re / admin123) with app_metadata.role = 'admin' and a matching profile row, so the admin panel is reachable immediately.
- bcrypt password hash generated with pgcrypto crypt(gen_salt('bf')).
*/

-- Ensure pgcrypto is available for crypt()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Profile auto-create on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name)
  VALUES (
    NEW.id,
    COALESCE((NEW.raw_app_meta_data ->> 'role'), 'customer'),
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(NEW.email, '@', 1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- View counter
CREATE OR REPLACE FUNCTION public.increment_views(row_id uuid)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.properties SET views = views + 1 WHERE id = row_id;
$$;

-- Demo admin user (idempotent: only insert if email not taken)
INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at, last_sign_in_at,
  confirmation_token, recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@maison.re',
  crypt('admin123', gen_salt('bf')),
  now(),
  '{"role":"admin"}'::jsonb,
  '{"full_name":"Maison Admin"}'::jsonb,
  now(), now(), now(),
  '', ''
WHERE NOT EXISTS (SELECT 1 FROM auth.users WHERE email = 'admin@maison.re');

-- Ensure profile exists for the admin
INSERT INTO public.profiles (id, role, full_name)
SELECT id, 'admin', 'Maison Admin' FROM auth.users WHERE email = 'admin@maison.re'
ON CONFLICT (id) DO UPDATE SET role = 'admin', full_name = 'Maison Admin';
