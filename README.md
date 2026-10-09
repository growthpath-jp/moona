# Moona

生理の記録と、パートナーの携帯へのプッシュ通知を行うWebアプリ（PWA）です。「つきのしらせ」（試作版）をもとにした製品版です。
iPhone（iOS 16.4以降）はホーム画面に追加すると通知を受け取れます。

## 構成

| 部品 | 場所 |
|---|---|
| アプリの画面 | `docs/`（GitHub Pages で公開） |
| サーバーの処理 | `supabase/functions/api/index.ts`（Supabase Edge Function「api」、JWT検証なし・独自の端末鍵で認証） |
| データベース | `supabase/migrations/`（全テーブルRLS有効・ポリシーなし。サーバーの処理だけが読み書き） |
| 定時通知 | Supabase の pg_cron（毎朝8時） |

## 新しい環境に立ち上げる手順

1. Supabase で新しいプロジェクトを作る（東京リージョン推奨）
2. `supabase/migrations/0001_init.sql` を実行
3. 通知用の鍵（VAPID）と cron 用の秘密の値を作り、`public.app_secrets` に入れる
   （`vapid_public` / `vapid_private` / `vapid_subject`（mailto:〜） / `cron_secret`）
4. `supabase/functions/api/index.ts` を Edge Function「api」としてデプロイ（JWT検証はオフ）
5. `0002_cron.sql` の `<PROJECT_REF>` を書き換えて実行
6. `docs/index.html` の `const API = ...` をそのプロジェクトのURLにする
7. GitHub Pages を main ブランチの `/docs` から公開

秘密の値はこのリポジトリには入れません。

## クレジット

日本語の折り返し（`docs/phrase.js`）は [BudouX](https://github.com/google/budoux)（Apache License 2.0）のモデルを使っています。
