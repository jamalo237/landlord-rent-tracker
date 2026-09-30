import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL
const supabaseServiceRole = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!supabaseUrl || !supabaseServiceRole) {
  console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the environment.')
  process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseServiceRole)

function genPassword(length = 12) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?'
  let pw = ''
  for (let i = 0; i < length; i++) pw += chars[Math.floor(Math.random() * chars.length)]
  return pw
}

async function main() {
  const timestamp = Date.now()
  const email = `landlord-test-${timestamp}@example.com`
  const password = genPassword(12)

  try {
    console.log('Creating user:', email)
    const res = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    })

    console.log('CREATE_USER_RES', JSON.stringify(res, null, 2))
    if (res.data && res.data.user) {
      console.log('CREATED', email, password)
    } else {
      console.error('Failed to create user:', res.error)
    }
  } catch (err) {
    console.error('ERR', err)
  }
}

main()
