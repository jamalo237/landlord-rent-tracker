const fs = require('fs')
const { createClient } = require('@supabase/supabase-js')

function loadEnv() {
  const env = {}
  try {
    const contents = fs.readFileSync('.env', 'utf8')
    contents.split(/\r?\n/).forEach((line) => {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) return
      const [key, ...rest] = line.split('=')
      env[key.trim()] = rest.join('=').trim()
    })
  } catch (err) {
    // ignore missing .env
  }
  return env
}

const env = loadEnv()
const supabaseUrl = env.VITE_SUPABASE_URL || process.env.VITE_SUPABASE_URL
const supabaseAnonKey = env.VITE_SUPABASE_ANON_KEY || process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY in .env')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseAnonKey)

async function run() {
  console.log('Supabase URL:', supabaseUrl)
  const tables = ['properties', 'units', 'tenants', 'payments']
  for (const table of tables) {
    const { data, error } = await supabase.from(table).select('id').limit(1)
    console.log(`TABLE ${table}:`, error ? `ERROR: ${error.message}` : `OK (${data?.length ?? 0} rows)`)
  }
}

run().catch((err) => {
  console.error('RUN_ERROR', err)
})
