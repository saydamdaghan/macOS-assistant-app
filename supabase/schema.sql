-- Asistan — Kırıkkale / kişisel iş + öğrenci uygulaması
-- Bu dosyayı yeni Supabase projenizin SQL Editor'üne yapıştırıp çalıştırın.
-- Service role anahtarını uygulamaya KOYMAYIN. Sadece Project URL + anon/publishable key yeter.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Profiller
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default 'Kullanıcı',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- İş alanı
-- ---------------------------------------------------------------------------
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  client text,
  description text,
  status text not null default 'aktif' check (status in ('aktif', 'tamamlandi', 'iptal')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid references public.jobs (id) on delete set null,
  title text not null,
  description text,
  status text not null default 'devam' check (status in ('devam', 'tamamlandi', 'beklemede')),
  completion numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  project_id uuid not null references public.projects (id) on delete cascade,
  title text not null,
  notes text,
  status text not null default 'bekliyor' check (status in ('bekliyor', 'yapiliyor', 'bitti')),
  priority text not null default 'orta' check (priority in ('dusuk', 'orta', 'yuksek')),
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  job_id uuid not null references public.jobs (id) on delete cascade,
  title text,
  amount numeric not null default 0,
  due_date date,
  paid_at timestamptz,
  status text not null default 'bekliyor' check (status in ('bekliyor', 'odendi', 'gecikti')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Ortak: hedefler, notlar, takvim, hatırlatıcılar
-- ---------------------------------------------------------------------------
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('work', 'student')),
  title text not null,
  detail text,
  progress numeric not null default 0,
  target numeric not null default 100,
  deadline date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('work', 'student')),
  title text not null,
  content text not null default '',
  category text not null default 'genel' check (category in ('genel', 'ders', 'hoca')),
  related_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  mode text not null check (mode in ('work', 'student')),
  title text not null,
  detail text,
  event_date date not null,
  event_time time,
  created_at timestamptz not null default now()
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  fire_at timestamptz not null,
  related_type text,
  related_id uuid,
  is_sent boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Öğrenci alanı
-- ---------------------------------------------------------------------------
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  code text,
  name text not null,
  credits numeric not null default 5,
  semester text not null,
  year int not null,
  instructor text,
  midterm_weight numeric not null default 40,
  final_weight numeric not null default 60,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.course_meetings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  day_of_week int not null check (day_of_week between 1 and 7),
  start_time time not null,
  end_time time not null,
  location text
);

create table if not exists public.assessments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid not null references public.courses (id) on delete cascade,
  kind text not null check (kind in ('vize', 'final', 'butunleme', 'quiz', 'odev', 'proje')),
  name text not null,
  score numeric,
  max_score numeric not null default 100,
  weight numeric not null default 0,
  exam_date date,
  created_at timestamptz not null default now()
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_id uuid references public.courses (id) on delete set null,
  title text not null,
  detail text,
  due_date date,
  status text not null default 'bekliyor' check (status in ('bekliyor', 'yapiliyor', 'teslim', 'gecikti')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.lecturers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  email text,
  office text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scholarships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  organization text,
  amount numeric,
  deadline date,
  status text not null default 'basvuru' check (status in ('basvuru', 'inceleme', 'kabul', 'red')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- İndeksler
-- ---------------------------------------------------------------------------
create index if not exists jobs_user_idx on public.jobs (user_id);
create index if not exists projects_user_idx on public.projects (user_id);
create index if not exists tasks_project_idx on public.tasks (project_id);
create index if not exists payments_job_idx on public.payments (job_id);
create index if not exists goals_user_mode_idx on public.goals (user_id, mode);
create index if not exists notes_user_mode_idx on public.notes (user_id, mode);
create index if not exists courses_user_idx on public.courses (user_id);
create index if not exists assessments_course_idx on public.assessments (course_id);
create index if not exists assignments_user_idx on public.assignments (user_id);
create index if not exists scholarships_user_idx on public.scholarships (user_id);

-- ---------------------------------------------------------------------------
-- updated_at
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles', 'jobs', 'projects', 'tasks', 'payments',
    'goals', 'notes', 'courses', 'assignments', 'lecturers', 'scholarships'
  ]
  loop
    execute format(
      'drop trigger if exists trg_%s_updated on public.%I;
       create trigger trg_%s_updated before update on public.%I
       for each row execute function public.touch_updated_at();',
      t, t, t, t
    );
  end loop;
end;
$$;

-- İş açılınca otomatik proje
create or replace function public.create_project_for_job()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.projects (user_id, job_id, title, description)
  values (new.user_id, new.id, new.title, new.description);
  return new;
end;
$$;

drop trigger if exists trg_job_creates_project on public.jobs;
create trigger trg_job_creates_project
after insert on public.jobs
for each row execute function public.create_project_for_job();

-- Görev değişince proje tamamlanma yüzdesi
create or replace function public.refresh_project_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  pid uuid;
  total int;
  done int;
begin
  pid := coalesce(new.project_id, old.project_id);
  select count(*)::int, count(*) filter (where status = 'bitti')::int
    into total, done
  from public.tasks
  where project_id = pid;

  update public.projects
  set completion = case when total = 0 then 0 else round((done::numeric / total) * 100, 1) end,
      status = case
        when total > 0 and done = total then 'tamamlandi'
        else 'devam'
      end,
      updated_at = now()
  where id = pid;

  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_task_completion on public.tasks;
create trigger trg_task_completion
after insert or update or delete on public.tasks
for each row execute function public.refresh_project_completion();

-- Geciken ödemeleri işaretle (okuma anında da uygulama tarafında hesaplanır)
create or replace function public.mark_overdue_payments()
returns void
language sql
security definer
set search_path = public
as $$
  update public.payments
  set status = 'gecikti'
  where status = 'bekliyor'
    and due_date is not null
    and due_date < current_date;
$$;

-- ---------------------------------------------------------------------------
-- Yeni kullanıcı profili
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', 'Kullanıcı')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.projects enable row level security;
alter table public.tasks enable row level security;
alter table public.payments enable row level security;
alter table public.goals enable row level security;
alter table public.notes enable row level security;
alter table public.calendar_events enable row level security;
alter table public.reminders enable row level security;
alter table public.courses enable row level security;
alter table public.course_meetings enable row level security;
alter table public.assessments enable row level security;
alter table public.assignments enable row level security;
alter table public.lecturers enable row level security;
alter table public.scholarships enable row level security;

-- Güvenli fonksiyonlar public şemada security definer; execute'u kısıtla
revoke all on function public.create_project_for_job() from public, anon, authenticated;
revoke all on function public.refresh_project_completion() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.mark_overdue_payments() from public, anon;
grant execute on function public.mark_overdue_payments() to authenticated;

do $$
declare
  tbl text;
begin
  foreach tbl in array array[
    'profiles', 'jobs', 'projects', 'tasks', 'payments',
    'goals', 'notes', 'calendar_events', 'reminders',
    'courses', 'course_meetings', 'assessments',
    'assignments', 'lecturers', 'scholarships'
  ]
  loop
    execute format('drop policy if exists %I_select on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_insert on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_update on public.%I', tbl, tbl);
    execute format('drop policy if exists %I_delete on public.%I', tbl, tbl);

    if tbl = 'profiles' then
      execute 'create policy profiles_select on public.profiles for select to authenticated using (id = auth.uid())';
      execute 'create policy profiles_insert on public.profiles for insert to authenticated with check (id = auth.uid())';
      execute 'create policy profiles_update on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid())';
    else
      execute format(
        'create policy %I_select on public.%I for select to authenticated using (user_id = auth.uid())',
        tbl, tbl
      );
      execute format(
        'create policy %I_insert on public.%I for insert to authenticated with check (user_id = auth.uid())',
        tbl, tbl
      );
      execute format(
        'create policy %I_update on public.%I for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())',
        tbl, tbl
      );
      execute format(
        'create policy %I_delete on public.%I for delete to authenticated using (user_id = auth.uid())',
        tbl, tbl
      );
    end if;
  end loop;
end;
$$;
