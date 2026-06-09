-- ArgusX: extensions and enums
-- Run first in Supabase SQL Editor

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE public.user_role AS ENUM ('customer', 'admin');
CREATE TYPE public.account_status AS ENUM ('active', 'offline', 'banned');
CREATE TYPE public.ride_status AS ENUM ('active', 'completed', 'cancelled', 'flagged');
CREATE TYPE public.threat_level AS ENUM ('NORMAL', 'WARNING', 'CRITICAL');
CREATE TYPE public.device_platform AS ENUM (
  'flutter_android',
  'flutter_ios',
  'flutter_web',
  'unknown'
);
