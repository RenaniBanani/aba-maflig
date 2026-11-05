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
-- אישורי הגעה (עמוד /rsvp). להדביק ב-SQL Editor → Run. אפשר להריץ שוב בלי נזק.
create table if not exists public.rsvp (
  id            bigint generated always as identity primary key,
  created_at    timestamptz not null default now(),
  event_id      text not null check (char_length(event_id) <= 40),
  name          text check (char_length(name) <= 60),
  ref           text check (char_length(ref) <= 40),
  status        text not null,
  pay_method    text check (pay_method in ('bit','paybox')),
  reason        text check (char_length(reason) <= 30),
  reason_other  text check (char_length(reason_other) <= 200),
  next_time     boolean,
  user_agent    text check (char_length(user_agent) <= 300)
);
-- yes = מגיע, no = לא מגיע, wait = רשימת המתנה (כשההפלגה מלאה)
alter table public.rsvp drop constraint if exists rsvp_status_check;
alter table public.rsvp add constraint rsvp_status_check check (status in ('yes','no','wait'));

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

-- כמה אבות אישרו הגעה. מחזיר מספר בלבד – בלי שמות – כדי שהעמוד יציג "נשארו X מקומות"
create or replace function public.rsvp_taken(p_event text)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::int from (
    select distinct on (coalesce(ref, name)) status
    from public.rsvp where event_id = p_event
    order by coalesce(ref, name), created_at desc
  ) t where status = 'yes';
$$;
revoke all on function public.rsvp_taken(text) from public;
grant execute on function public.rsvp_taken(text) to anon;

-- ===================================================================
-- קישורים קצרים (aba-maflig.banani.co.il/rsvp/?k7m2qx). להדביק ב-SQL Editor → Run.
create table if not exists public.invites (
  code        text primary key check (code ~ '^[a-z0-9]{4,12}$'),
  name        text check (char_length(name) <= 40),
  created_at  timestamptz not null default now()
);
alter table public.invites enable row level security;
revoke all on public.invites from anon, authenticated;

-- כלי השליחה שומר שם פרטי ליד הקוד
create or replace function public.make_invite(p_code text, p_name text)
returns void language sql security definer set search_path = public as $$
  insert into public.invites(code, name) values (p_code, nullif(left(trim(p_name), 40), ''))
  on conflict (code) do update set name = excluded.name;
$$;
-- הכרטיס מקבל רק את השם הפרטי של קוד שהוא כבר מכיר
create or replace function public.invite_name(p_code text)
returns text language sql stable security definer set search_path = public as $$
  select name from public.invites where code = p_code;
$$;
revoke all on function public.make_invite(text, text) from public;
revoke all on function public.invite_name(text) from public;
grant execute on function public.make_invite(text, text) to anon;
grant execute on function public.invite_name(text) to anon;
