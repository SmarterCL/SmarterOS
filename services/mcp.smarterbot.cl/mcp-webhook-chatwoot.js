import pino from 'pino'
const logger = pino({ level: process.env.LOG_LEVEL || 'info' })

// Handler básico para eventos de Chatwoot
// Referencia: https://www.chatwoot.com/developers/webhooks
export async function chatwootWebhookHandler(req, res) {
  try {
    const event = req.body?.event
    const payload = req.body
    logger.info({ event }, 'Chatwoot webhook recibido')

    switch (event) {
      case 'message_created': {
        // Aquí podrías: clasificar intención, enriquecer contacto, disparar n8n, etc.
        // Ejemplo: simplemente reconoce el mensaje
        return res.json({ ok: true })
      }
      case 'conversation_created': {
        return res.json({ ok: true })
      }
      case 'contact_updated': {
        return res.json({ ok: true })
      }
      default: {
        return res.json({ ok: true, note: 'event not handled' })
      }
    }
  } catch (err) {
    logger.error({ err }, 'webhook error')
    return res.status(500).json({ ok: false, error: err.message })
  }
}
