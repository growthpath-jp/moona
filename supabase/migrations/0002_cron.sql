-- daily reminders at 08:00 JST (23:00 UTC). Replace <PROJECT_REF> with the Supabase project ref.
-- The secret itself lives only in public.app_secrets (never in this repository).
select cron.schedule('tsuki-daily-reminders', '0 23 * * *', $$
  select net.http_post(
    url := 'https://<PROJECT_REF>.supabase.co/functions/v1/api',
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object('action','cron','secret',(select value from public.app_secrets where key='cron_secret')))
$$);
