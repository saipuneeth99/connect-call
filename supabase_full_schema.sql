-- ============================================================================
-- ConnectCall: Complete Unified Database Schema
-- Includes: Users, Call History (calls), Contact Requests, Realtime & Storage
-- Run this in your Supabase Dashboard: SQL Editor -> New Query -> Run
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. USERS TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  avatar_url TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ensure all columns exist in case table was created earlier
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ----------------------------------------------------------------------------
-- 2. CALL HISTORY TABLE (calls)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calls (
  id TEXT PRIMARY KEY,
  caller_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  caller_name TEXT,
  receiver_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_name TEXT,
  type TEXT NOT NULL,                      -- 'audio' or 'video'
  status TEXT NOT NULL,                    -- 'ended', 'rejected', 'missed', 'busy', 'completed'
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  ended_at TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ensure all columns exist in case table was created earlier
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS caller_name TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS receiver_name TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS status TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS ended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS duration_seconds INTEGER DEFAULT 0;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ----------------------------------------------------------------------------
-- 3. CONTACT REQUESTS TABLE (Private mutual connections)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contact_requests (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending',  -- 'pending', 'accepted', 'declined', 'cancelled'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT unique_sender_receiver UNIQUE (sender_id, receiver_id)
);

-- Ensure all columns exist in case table was created earlier
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ----------------------------------------------------------------------------
-- 4. PERFORMANCE INDEXES
-- ----------------------------------------------------------------------------
-- Users: fast case-insensitive search by email & lookup by name
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON public.users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_name ON public.users(name);

-- Calls: fast history retrieval ordered by start time
CREATE INDEX IF NOT EXISTS idx_calls_caller ON public.calls(caller_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_receiver ON public.calls(receiver_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_started_at ON public.calls(started_at DESC);

-- Contact requests: fast lookup for incoming, sent, and active contacts
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender ON public.contact_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver ON public.contact_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_status ON public.contact_requests(status);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver_status ON public.contact_requests(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender_status ON public.contact_requests(sender_id, status);

-- ----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) & POLICIES
-- ----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;

-- Idempotent policy creation (drop then re-create so running repeatedly is safe)
DROP POLICY IF EXISTS "Allow all access to users" ON public.users;
CREATE POLICY "Allow all access to users" 
ON public.users FOR ALL 
USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to calls" ON public.calls;
CREATE POLICY "Allow all access to calls" 
ON public.calls FOR ALL 
USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all access to contact_requests" ON public.contact_requests;
CREATE POLICY "Allow all access to contact_requests" 
ON public.contact_requests FOR ALL 
USING (true) WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- 6. REALTIME REPLICATION (For live instant UI updates on calls & requests)
-- ----------------------------------------------------------------------------
ALTER TABLE public.users REPLICA IDENTITY FULL;
ALTER TABLE public.calls REPLICA IDENTITY FULL;
ALTER TABLE public.contact_requests REPLICA IDENTITY FULL;

DO $$
BEGIN
  -- Add users to publication if not already present
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'users'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  END IF;

  -- Add calls to publication if not already present
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'calls'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
  END IF;

  -- Add contact_requests to publication if not already present
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'contact_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.contact_requests;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 7. AUTO-UPDATE TRIGGER (Keeps updated_at accurate on contact_requests)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_contact_requests_updated_at ON public.contact_requests;
CREATE TRIGGER trigger_contact_requests_updated_at
BEFORE UPDATE ON public.contact_requests
FOR EACH ROW
EXECUTE FUNCTION public.handle_updated_at();

-- ----------------------------------------------------------------------------
-- 8. STORAGE BUCKET FOR PROFILE AVATARS
-- ----------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public Access to Avatars" ON storage.objects;
CREATE POLICY "Public Access to Avatars" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Allow Upload to Avatars" ON storage.objects;
CREATE POLICY "Allow Upload to Avatars" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Allow Update to Avatars" ON storage.objects;
CREATE POLICY "Allow Update to Avatars" 
ON storage.objects FOR UPDATE 
USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Allow Delete from Avatars" ON storage.objects;
CREATE POLICY "Allow Delete from Avatars" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'avatars');
