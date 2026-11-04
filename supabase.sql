-- אבא מפליג: טבלת תשובות לשאלון
-- להדביק ב-Supabase: SQL Editor → New query → Run

create table if not exists public.responses (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  age           text check (char_length(age) <= 20),
  kids_count    smallint check (kids_count between 0 and 6),
  kids_ages     smallint[] check (cardinality(kids_ages) <= 6),
  area          text check (char_length(area) <= 30),
  city          text check (char_length(city) <= 60),
  nights        text check (char_length(nights) <= 20),
  talk          text check (char_length(talk) <= 20),
  fit           smallint not null check (fit between 1 and 5),
  draw          text[] check (cardinality(draw) <= 6),
  draw_other    text check (char_length(draw_other) <= 160),
  topics        text[] check (cardinality(topics) <= 6),
  topics_other  text check (char_length(topics_other) <= 160),
  pref_when     text check (char_length(pref_when) <= 30),
  format        text check (char_length(format) <= 30),
  block         text[] check (cardinality(block) <= 5),
  optin         boolean not null default false,
  name          text check (char_length(name) <= 60),
  phone         text check (phone is null or phone ~ '^0[0-9]{1,2}-?[0-9]{7}$'),
  source        text check (char_length(source) <= 60),
  utm           jsonb,
  user_agent    text check (char_length(user_agent) <= 300),
  constraint optin_needs_contact check (not optin or (name is not null and phone is not null))
);

-- אבטחה: מבקרים יכולים רק להוסיף שורה. אף אחד מבחוץ לא יכול לקרוא, לערוך או למחוק.
alter table public.responses enable row level security;

drop policy if exists "anon can insert" on public.responses;
create policy "anon can insert" on public.responses
  for insert to anon with check (true);

revoke all on public.responses from anon;
grant insert on public.responses to anon;

-- תצוגה נוחה לרשימת ההרשמה המוקדמת (נגישה רק לך, מתוך לוח הבקרה של Supabase)
create or replace view public.early_list
with (security_invoker = true) as
  select created_at, name, phone, area, city, kids_count, fit, pref_when, format
  from public.responses where optin order by created_at desc;
revoke all on public.early_list from anon, authenticated;

-- סיכום מהיר: כמה ענו, ממוצע "כמה זה מדבר אליך", כמה נרשמו
create or replace view public.summary
with (security_invoker = true) as
  select count(*) as responses,
         round(avg(fit)::numeric, 2) as avg_fit,
         count(*) filter (where fit >= 4) as fit_4_or_5,
         count(*) filter (where optin) as early_signups
  from public.responses;
revoke all on public.summary from anon, authenticated;

-- ===================================================================
-- אישורי הגעה (עמוד /rsvp). להדביק ב-SQL Editor → Run, פעם אחת.
create table if not exists public.rsvp (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  event_id      text not null check (char_length(event_id) <= 40),
  name          text check (char_length(name) <= 60),
  ref           text check (char_length(ref) <= 40),
  status        text not null check (status in ('yes','no')),
  pay_method    text check (pay_method in ('bit','paybox')),
  reason        text check (char_length(reason) <= 30),
  reason_other  text check (char_length(reason_other) <= 200),
  next_time     boolean,
  user_agent    text check (char_length(user_agent) <= 300)
);
alter table public.rsvp enable row level security;
drop policy if exists "anon can insert" on public.rsvp;
create policy "anon can insert" on public.rsvp for insert to anon with check (true);
revoke all on public.rsvp from anon;
grant insert on public.rsvp to anon;

-- התשובה האחרונה של כל אחד (אם מישהו שינה דעה – רואים רק את האחרונה)
create or replace view public.rsvp_latest
with (security_invoker = true) as
  select distinct on (event_id, coalesce(ref, name)) *
  from public.rsvp order by event_id, coalesce(ref, name), created_at desc;
revoke all on public.rsvp_latest from anon, authenticated;
