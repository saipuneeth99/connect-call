-- ============================================================================
-- ConnectCall: Complete Unified Database Schema
-- Includes: Users, Real-Time Calls (calls), Mutual Contacts (contact_requests),
--           Storage Buckets (avatars), Performance Indexes & Realtime Replication
--
-- Instructions:
-- 1. Go to your Supabase Dashboard (https://supabase.com/dashboard)
-- 2. Open SQL Editor -> New Query
-- 3. Paste this entire file and click "Run"
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. USERS TABLE
-- Stores user profiles, presence status, and push notification tokens
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  avatar_url TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMP WITH TIME ZONE DEFAULT now(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  fcm_token TEXT,
  voip_token TEXT
);

-- Ensure all columns exist idempotently if table already existed
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS voip_token TEXT;

-- ----------------------------------------------------------------------------
-- 2. CALLS TABLE
-- Stores both active calls (ringing, connected) and call history (missed, ended)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.calls (
  id TEXT PRIMARY KEY,
  caller_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  caller_name TEXT,
  receiver_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_name TEXT,
  type TEXT NOT NULL,                      -- 'audio' or 'video'
  status TEXT NOT NULL,                    -- 'calling', 'ringing', 'connecting', 'connected', 'ended', 'rejected', 'missed', 'busy', 'failed'
  started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  answered_at TIMESTAMP WITH TIME ZONE,
  ended_at TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Ensure all columns exist idempotently
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS caller_name TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS receiver_name TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS type TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS status TEXT;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS started_at TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS answered_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS ended_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS duration_seconds INTEGER DEFAULT 0;
ALTER TABLE public.calls ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ----------------------------------------------------------------------------
-- 3. CONTACT REQUESTS TABLE
-- Manages mutual connections: sending, accepting, and managing private contacts
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

-- Ensure all columns exist idempotently
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT now();
ALTER TABLE public.contact_requests ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT now();

-- ----------------------------------------------------------------------------
-- 4. PERFORMANCE & LOOKUP INDEXES
-- ----------------------------------------------------------------------------
-- Fast user search by lowercase email & name
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON public.users(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_users_name ON public.users(name);

-- Fast call signaling & history lookup
CREATE INDEX IF NOT EXISTS idx_calls_caller ON public.calls(caller_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_receiver ON public.calls(receiver_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_started_at ON public.calls(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_calls_active_receiver ON public.calls(receiver_id, status, started_at DESC);

-- Fast contact request querying
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender ON public.contact_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver ON public.contact_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_status ON public.contact_requests(status);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver_status ON public.contact_requests(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender_status ON public.contact_requests(sender_id, status);

-- ----------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) & PERMISSIVE POLICIES
-- Allows authenticated and anon keys used in the app to access necessary rows
-- ----------------------------------------------------------------------------
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;

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
-- 6. REALTIME REPLICATION (Instant updates across devices)
-- ----------------------------------------------------------------------------
ALTER TABLE public.users REPLICA IDENTITY FULL;
ALTER TABLE public.calls REPLICA IDENTITY FULL;
ALTER TABLE public.contact_requests REPLICA IDENTITY FULL;

DO $$
BEGIN
  -- Publish users table for presence and profile changes
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'users'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
  END IF;

  -- Publish calls table for incoming call detection & state transitions
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'calls'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.calls;
  END IF;

  -- Publish contact_requests table for real-time contact requests & status
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'contact_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.contact_requests;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 7. AUTO-UPDATE TRIGGER (Maintains updated_at on contact_requests)
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
-- 8. HELPER CLEANUP FUNCTION (Expires stale ringing calls > 2 minutes old)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.expire_stale_ringing_calls()
RETURNS void AS $$
BEGIN
  UPDATE public.calls
  SET status = 'missed', ended_at = now()
  WHERE status = 'ringing' AND started_at < (now() - interval '2 minutes');
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- 9. STORAGE BUCKET FOR USER AVATARS
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
