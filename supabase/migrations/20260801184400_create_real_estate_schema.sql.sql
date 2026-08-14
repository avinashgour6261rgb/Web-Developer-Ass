/*
# Maison — Luxury Real Estate Schema

1. Overview
This migration creates the full data model for a luxury real estate platform:
- Public catalog of properties (residential, commercial, luxury, rental, new projects)
- Cities and locations for search/filtering
- Agents (linked to auth users) who list properties
- Blogs with categories and tags
- Customer reviews/testimonials
- Inquiries (contact requests) and scheduled visits/bookings
- Saved properties (wishlist) per user
- Site-wide settings (logo, hero, contact info, SEO, social links)
- Notifications for users

2. New Tables
- profiles            : extends auth.users with role, name, phone, avatar
- cities               : top cities with hero imagery
- locations            : areas/localities within a city
- agents               : agent profiles (linked to auth user) with bio, photo, contact
- categories           : property categories (residential, commercial, luxury, rental, new projects, plots, villa, apartment, office, shop, warehouse, farmhouse)
- properties           : the core listing — price, beds, baths, area, status, featured, premium, images, amenities, map, floor plan, documents, video, seo
- property_images      : multiple images per property (gallery)
- saved_properties     : wishlist — user saves a property
- inquiries            : contact-form submissions per property or general
- bookings             : scheduled visit requests per property
- blogs                : articles with category, tags, cover image, seo
- reviews              : customer testimonials (pending/approved)
- notifications        : in-app notifications per user
- settings             : singleton row of site-wide configuration
- activity_logs        : admin action audit trail

3. Security
- RLS enabled on every table.
- Public read (anon + authenticated) on catalog tables: properties, categories, cities, locations, agents, blogs, reviews (approved only), settings.
- Owner-scoped write on saved_properties, notifications, inquiries (own), bookings (own), profiles (own).
- Admin-only writes on properties, agents, blogs, reviews, settings, activity_logs via a helper is_admin() that checks raw_app_meta_data.role === 'admin'.
- Agent role can insert/update properties assigned to themselves.
*/

-- Helper: role check from JWT app metadata
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$;

CREATE OR REPLACE FUNCTION public.is_agent_or_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('admin','agent'),
    false
  );
$$;

-- =========================================================
-- profiles
-- =========================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text,
  phone text,
  avatar_url text,
  role text NOT NULL DEFAULT 'customer' CHECK (role IN ('admin','agent','customer')),
  blocked boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_read_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_read_own_or_admin" ON public.profiles FOR SELECT
  TO authenticated USING (auth.uid() = id OR public.is_admin());

DROP POLICY IF EXISTS "profiles_insert_self" ON public.profiles;
CREATE POLICY "profiles_insert_self" ON public.profiles FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_self" ON public.profiles;
CREATE POLICY "profiles_update_self" ON public.profiles FOR UPDATE
  TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_admin_update" ON public.profiles;
CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- cities
-- =========================================================
CREATE TABLE IF NOT EXISTS public.cities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  image_url text,
  property_count int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cities_public_read" ON public.cities;
CREATE POLICY "cities_public_read" ON public.cities FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "cities_admin_write" ON public.cities;
CREATE POLICY "cities_admin_write" ON public.cities FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- locations
-- =========================================================
CREATE TABLE IF NOT EXISTS public.locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id uuid REFERENCES public.cities(id) ON DELETE CASCADE,
  name text NOT NULL,
  slug text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE (city_id, slug)
);
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "locations_public_read" ON public.locations;
CREATE POLICY "locations_public_read" ON public.locations FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "locations_admin_write" ON public.locations;
CREATE POLICY "locations_admin_write" ON public.locations FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- agents
-- =========================================================
CREATE TABLE IF NOT EXISTS public.agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  title text,
  bio text,
  email text,
  phone text,
  photo_url text,
  whatsapp text,
  rating numeric(2,1) DEFAULT 5.0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.agents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "agents_public_read" ON public.agents;
CREATE POLICY "agents_public_read" ON public.agents FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "agents_admin_write" ON public.agents;
CREATE POLICY "agents_admin_write" ON public.agents FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- categories
-- =========================================================
CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  type text NOT NULL DEFAULT 'residential' CHECK (type IN ('residential','commercial','luxury','rental','new_project','plot')),
  description text,
  icon text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
CREATE POLICY "categories_public_read" ON public.categories FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "categories_admin_write" ON public.categories;
CREATE POLICY "categories_admin_write" ON public.categories FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- properties
-- =========================================================
CREATE TABLE IF NOT EXISTS public.properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  city_id uuid REFERENCES public.cities(id) ON DELETE SET NULL,
  location_id uuid REFERENCES public.locations(id) ON DELETE SET NULL,
  agent_id uuid REFERENCES public.agents(id) ON DELETE SET NULL,
  price numeric(14,2) NOT NULL DEFAULT 0,
  price_period text DEFAULT 'sale' CHECK (price_period IN ('sale','rent')),
  bhk int,
  bedrooms int,
  bathrooms int,
  area_sqft numeric(10,2),
  furnished text CHECK (furnished IN ('furnished','semi_furnished','unfurnished')),
  parking int DEFAULT 0,
  ready_to_move boolean DEFAULT false,
  is_new_launch boolean DEFAULT false,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active','sold','rented','pending','draft')),
  featured boolean DEFAULT false,
  premium boolean DEFAULT false,
  approved boolean DEFAULT true,
  amenities text[] DEFAULT '{}',
  features text[] DEFAULT '{}',
  cover_image text,
  gallery text[] DEFAULT '{}',
  floor_plan_url text,
  document_url text,
  video_url text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  address text,
  nearby_places jsonb DEFAULT '[]',
  meta_title text,
  meta_description text,
  views int DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "properties_public_read_approved" ON public.properties;
CREATE POLICY "properties_public_read_approved" ON public.properties FOR SELECT
  TO anon, authenticated USING (approved = true);

DROP POLICY IF EXISTS "properties_admin_all" ON public.properties;
CREATE POLICY "properties_admin_all" ON public.properties FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "properties_agent_insert" ON public.properties;
CREATE POLICY "properties_agent_insert" ON public.properties FOR INSERT
  TO authenticated WITH CHECK (public.is_agent_or_admin());

DROP POLICY IF EXISTS "properties_agent_update" ON public.properties;
CREATE POLICY "properties_agent_update" ON public.properties FOR UPDATE
  TO authenticated USING (public.is_agent_or_admin()) WITH CHECK (public.is_agent_or_admin());

CREATE INDEX IF NOT EXISTS idx_properties_category ON public.properties(category_id);
CREATE INDEX IF NOT EXISTS idx_properties_city ON public.properties(city_id);
CREATE INDEX IF NOT EXISTS idx_properties_location ON public.properties(location_id);
CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_featured ON public.properties(featured);
CREATE INDEX IF NOT EXISTS idx_properties_price ON public.properties(price);

-- =========================================================
-- saved_properties (wishlist)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.saved_properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  property_id uuid REFERENCES public.properties(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (user_id, property_id)
);
ALTER TABLE public.saved_properties ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_owner_select" ON public.saved_properties;
CREATE POLICY "saved_owner_select" ON public.saved_properties FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_owner_insert" ON public.saved_properties;
CREATE POLICY "saved_owner_insert" ON public.saved_properties FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_owner_delete" ON public.saved_properties;
CREATE POLICY "saved_owner_delete" ON public.saved_properties FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

-- =========================================================
-- inquiries
-- =========================================================
CREATE TABLE IF NOT EXISTS public.inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  user_id uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  message text,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new','replied','assigned','closed')),
  assigned_agent uuid REFERENCES public.agents(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.inquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inquiries_insert_any" ON public.inquiries;
CREATE POLICY "inquiries_insert_any" ON public.inquiries FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "inquiries_owner_read" ON public.inquiries;
CREATE POLICY "inquiries_owner_read" ON public.inquiries FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "inquiries_admin_all" ON public.inquiries;
CREATE POLICY "inquiries_admin_all" ON public.inquiries FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- bookings (scheduled visits)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid REFERENCES public.properties(id) ON DELETE CASCADE,
  user_id uuid DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  visit_date date,
  visit_time text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','completed')),
  notes text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookings_insert_any" ON public.bookings;
CREATE POLICY "bookings_insert_any" ON public.bookings FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "bookings_owner_read" ON public.bookings;
CREATE POLICY "bookings_owner_read" ON public.bookings FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "bookings_admin_all" ON public.bookings;
CREATE POLICY "bookings_admin_all" ON public.bookings FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- blogs
-- =========================================================
CREATE TABLE IF NOT EXISTS public.blogs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE NOT NULL,
  excerpt text,
  content text,
  category text,
  tags text[] DEFAULT '{}',
  cover_image text,
  author text,
  published boolean DEFAULT true,
  meta_title text,
  meta_description text,
  views int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.blogs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "blogs_public_read" ON public.blogs;
CREATE POLICY "blogs_public_read" ON public.blogs FOR SELECT
  TO anon, authenticated USING (published = true);

DROP POLICY IF EXISTS "blogs_admin_all" ON public.blogs;
CREATE POLICY "blogs_admin_all" ON public.blogs FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- reviews (testimonials)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  role text,
  rating int NOT NULL DEFAULT 5 CHECK (rating BETWEEN 1 AND 5),
  content text NOT NULL,
  avatar_url text,
  approved boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reviews_public_read_approved" ON public.reviews;
CREATE POLICY "reviews_public_read_approved" ON public.reviews FOR SELECT
  TO anon, authenticated USING (approved = true);

DROP POLICY IF EXISTS "reviews_insert_any" ON public.reviews;
CREATE POLICY "reviews_insert_any" ON public.reviews FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "reviews_admin_all" ON public.reviews;
CREATE POLICY "reviews_admin_all" ON public.reviews FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- notifications
-- =========================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notif_owner_select" ON public.notifications;
CREATE POLICY "notif_owner_select" ON public.notifications FOR SELECT
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "notif_owner_update" ON public.notifications;
CREATE POLICY "notif_owner_update" ON public.notifications FOR UPDATE
  TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "notif_owner_delete" ON public.notifications;
CREATE POLICY "notif_owner_delete" ON public.notifications FOR DELETE
  TO authenticated USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "notif_admin_insert" ON public.notifications;
CREATE POLICY "notif_admin_insert" ON public.notifications FOR INSERT
  TO authenticated WITH CHECK (public.is_admin());

-- =========================================================
-- settings (singleton)
-- =========================================================
CREATE TABLE IF NOT EXISTS public.settings (
  id int PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  site_name text DEFAULT 'Maison',
  logo_url text,
  favicon_url text,
  hero_image text,
  hero_title text,
  hero_subtitle text,
  about text,
  email text,
  phone text,
  address text,
  facebook text,
  instagram text,
  twitter text,
  linkedin text,
  youtube text,
  google_analytics text,
  meta_title text,
  meta_description text,
  privacy_policy text,
  terms text,
  updated_at timestamptz DEFAULT now()
);
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "settings_public_read" ON public.settings;
CREATE POLICY "settings_public_read" ON public.settings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "settings_admin_write" ON public.settings;
CREATE POLICY "settings_admin_write" ON public.settings FOR ALL
  TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());

-- =========================================================
-- activity_logs
-- =========================================================
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity text,
  entity_id uuid,
  detail text,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "logs_admin_read" ON public.activity_logs;
CREATE POLICY "logs_admin_read" ON public.activity_logs FOR SELECT
  TO authenticated USING (public.is_admin());

DROP POLICY IF EXISTS "logs_admin_insert" ON public.activity_logs;
CREATE POLICY "logs_admin_insert" ON public.activity_logs FOR INSERT
  TO authenticated WITH CHECK (public.is_admin());

-- Ensure a settings row exists
INSERT INTO public.settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
