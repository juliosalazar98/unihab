const prisma = require('../config/prisma')

/**
 * Crea una notificación para un usuario.
 * @param {number} usuarioId  — receptor
 * @param {string} titulo
 * @param {string} mensaje
 * @param {string} tipo       — TipoNotificacion enum
 */
const crearNotificacion = async (usuarioId, titulo, mensaje, tipo = 'GENERAL') => {
  try {
    return await prisma.notificacion.create({
      data: { usuarioId, titulo, mensaje, tipo },
    })
  } catch (e) {
    console.error('[Notificacion] Error al crear:', e.message)
  }
}

module.exports = { crearNotificacion }