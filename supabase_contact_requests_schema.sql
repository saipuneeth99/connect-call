-- ============================================================================
-- ConnectCall: Contact Requests & Private Mutual Contacts Schema
-- Run this in your Supabase SQL Editor: Dashboard -> SQL Editor -> New Query
-- ============================================================================

-- 1. Create Contact Requests Table
CREATE TABLE IF NOT EXISTS public.contact_requests (
  id TEXT PRIMARY KEY,
  sender_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  receiver_id TEXT NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'cancelled'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT unique_sender_receiver UNIQUE (sender_id, receiver_id)
);

-- 2. Performance Indexes for fast queries
CREATE INDEX IF NOT EXISTS idx_contact_requests_sender ON public.contact_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_receiver ON public.contact_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_contact_requests_status ON public.contact_requests(status);
CREATE INDEX IF NOT EXISTS idx_users_email_lower ON public.users(LOWER(email));

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.contact_requests ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policy: Allow all operations (or customize per auth.uid)
CREATE POLICY "Allow all access to contact_requests" 
ON public.contact_requests 
FOR ALL 
USING (true) 
WITH CHECK (true);
