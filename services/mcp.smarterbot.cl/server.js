import express from 'express'
import morgan from 'morgan'
import pino from 'pino'
import { googleContactsLookup } from './mcp-tool-google-contacts.js'
import { chatwootWebhookHandler } from './mcp-webhook-chatwoot.js'

const app = express()
const logger = pino({ level: process.env.LOG_LEVEL || 'info' })

app.use(express.json({ limit: '1mb' }))
app.use(morgan('tiny'))

app.get('/health', (req, res) => res.json({ ok: true }))

// MCP Tools
app.post('/tools/google.contacts.lookup', async (req, res) => {
  try {
    const { phone, email, name } = req.body || {}
    if (!phone && !email && !name) {
      return res.status(400).json({ error: 'phone, email o name requerido' })
    }
    const result = await googleContactsLookup({ phone, email, name })
    return res.json({ ok: true, data: result })
  } catch (err) {
    logger.error({ err }, 'google.contacts.lookup failed')
    return res.status(500).json({ ok: false, error: err.message })
  }
})

// Chatwoot ↔ MCP webhook
app.post('/webhook/chatwoot', chatwootWebhookHandler)

const port = process.env.PORT || 3100
app.listen(port, () => {
  logger.info({ port }, 'MCP Server listening')
})
