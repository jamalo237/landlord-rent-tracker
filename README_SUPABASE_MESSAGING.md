# Supabase Messaging + OpenAI Summary Edge Function

## What this adds
- `threads`, `thread_members`, `messages`, `thread_summaries` tables
- RLS so only thread members can read messages and summaries
- Edge Function at `functions/summarizeThread/index.js` to summarize a thread using OpenAI

## Setup

1. Run the SQL in Supabase SQL Editor:
   - `supabase_messaging_schema.sql`

2. Add Supabase secrets in your project settings:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE`

3. Add OpenAI secret:
   - `OPENAI_API_KEY`

4. Deploy the Edge Function with Supabase CLI:

```bash
supabase functions deploy summarizeThread
```

5. Call the function from your app:

POST `/functions/v1/summarizeThread`

Body:
```json
{
  "thread_id": "<thread_uuid>",
  "max_messages": 50
}
```

## Notes
- The function uses the Supabase service role key to read messages and write summaries.
- It uses `gpt-4.1-mini` to generate a concise thread summary.
- You can modify the prompt or model name in `functions/summarizeThread/index.js`.
