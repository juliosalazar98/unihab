const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')
const obtenerNotificaciones = async (req, res) => {
  try {
    const notificaciones = await prisma.notificacion.findMany({
      where:   { usuarioId: req.usuario.id },
      orderBy: { creadoEn: 'desc' },
    })
    const noLeidas = notificaciones.filter(n => !n.leido).length
    return ok(res, { notificaciones, noLeidas }, 'Notificaciones obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener notificaciones', 500)
  }
}
const marcarTodasLeidas = async (req, res) => {
  try {
    await prisma.notificacion.updateMany({
      where: { usuarioId: req.usuario.id, leido: false },
      data:  { leido: true },
    })
    return ok(res, null, 'Todas marcadas como leídas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al marcar notificaciones', 500)
  }
}
const marcarLeida = async (req, res) => {
  try {
    const id    = parseInt(req.params.id)
    const notif = await prisma.notificacion.findUnique({ where: { id } })

    if (!notif)                             return error(res, 'Notificación no encontrada', 404)
    if (notif.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    const actualizada = await prisma.notificacion.update({
      where: { id },
      data:  { leido: true },
    })
    return ok(res, actualizada, 'Notificación leída')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al marcar notificación', 500)
  }
}
const eliminarNotificacion = async (req, res) => {
  try {
    const id    = parseInt(req.params.id)
    const notif = await prisma.notificacion.findUnique({ where: { id } })

    if (!notif)                             return error(res, 'Notificación no encontrada', 404)
    if (notif.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    await prisma.notificacion.delete({ where: { id } })
    return ok(res, null, 'Notificación eliminada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar notificación', 500)
  }
}
const coSolicitud = async (req, res) => {
  try {
    const usuarioId  = req.usuario.id
    const { inmuebleId, roommateId } = req.body

    if (!inmuebleId || !roommateId) {
      return error(res, 'inmuebleId y roommateId son requeridos', 400)
    }
    const inmueble = await prisma.inmueble.findUnique({
      where:  { id: parseInt(inmuebleId) },
      select: { id: true, titulo: true, tipo: true },
    })
    if (!inmueble)                    return error(res, 'Inmueble no encontrado', 404)
    if (inmueble.tipo !== 'COMPARTIDO') {
      return error(res, 'La co-solicitud solo aplica para inmuebles compartidos', 400)
    }
    const match = await prisma.matchConvivencia.findFirst({
      where: {
        estado: 'ACEPTADO',
        OR: [
          { solicitanteId: usuarioId, receptorId: parseInt(roommateId) },
          { solicitanteId: parseInt(roommateId), receptorId: usuarioId },
        ],
      },
    })
    if (!match) return error(res, 'Solo puedes enviar co-solicitudes a roommates confirmados', 400)
    const remitente = await prisma.usuario.findUnique({
      where:  { id: usuarioId },
      select: { nombre: true },
    })

    const co = await prisma.coSolicitud.upsert({
      where: {
        remitenteId_receptorId_inmuebleId: {
          remitenteId: usuarioId,
          receptorId: parseInt(roommateId),
          inmuebleId: parseInt(inmuebleId),
        },
      },
      update: { estado: 'PENDIENTE' },
      create: {
        remitenteId: usuarioId,
        receptorId: parseInt(roommateId),
        inmuebleId: parseInt(inmuebleId),
        estado: 'PENDIENTE',
      },
    })

    await crearNotificacion(
      parseInt(roommateId),
      '¡Propuesta de alquiler!',
      `${remitente.nombre} te invitó a postular juntos al inmueble compartido "${inmueble.titulo}". Revisá "Mis Solicitudes" para aceptar o rechazar.`,
      'CO_SOLICITUD',
    )

    return ok(res, co, 'Invitación enviada a tu roommate')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar co-solicitud', 500)
  }
}

const responderCoSolicitud = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const { accion } = req.body

    if (!['ACEPTAR', 'RECHAZAR'].includes(accion)) {
      return error(res, 'Acción inválida. Usá ACEPTAR o RECHAZAR', 400)
    }

    const co = await prisma.coSolicitud.findUnique({
      where: { id },
      include: {
        inmueble:  { select: { id: true, titulo: true, propietarioId: true } },
        remitente: { select: { id: true, nombre: true } },
        receptor:  { select: { id: true, nombre: true } },
      },
    })

    if (!co) return error(res, 'Invitación no encontrada', 404)
    if (co.receptorId !== req.usuario.id) return error(res, 'No autorizado', 403)
    if (co.estado !== 'PENDIENTE') return error(res, 'Esta invitación ya fue respondida', 400)

    if (accion === 'RECHAZAR') {
      await prisma.coSolicitud.update({
        where: { id },
        data:  { estado: 'RECHAZADA' },
      })
      await crearNotificacion(
        co.remitenteId,
        'Invitación rechazada',
        `${co.receptor.nombre} no aceptó postular contigo a "${co.inmueble.titulo}".`,
        'CO_SOLICITUD',
      )
      return ok(res, null, 'Invitación rechazada')
    }

    await prisma.coSolicitud.update({
      where: { id },
      data:  { estado: 'ACEPTADA' },
    })

    for (const arrendatarioId of [co.remitenteId, co.receptorId]) {
      await prisma.solicitud.upsert({
        where: {
          arrendatarioId_inmuebleId: {
            arrendatarioId,
            inmuebleId: co.inmuebleId,
          },
        },
        update: {
          creadoEn: new Date(),
          atendida: false,
          estado: 'PENDIENTE',
          coSolicitudId: co.id,
        },
        create: {
          arrendatarioId,
          inmuebleId: co.inmuebleId,
          coSolicitudId: co.id,
        },
      })
    }

    await crearNotificacion(
      co.inmueble.propietarioId,
      '¡Nueva solicitud conjunta!',
      `${co.remitente.nombre} y ${co.receptor.nombre} quieren alquilar juntos tu inmueble "${co.inmueble.titulo}".`,
      'CO_SOLICITUD_PROPIETARIO',
    )

    await crearNotificacion(
      co.remitenteId,
      '¡Invitación aceptada!',
      `${co.receptor.nombre} aceptó postular contigo a "${co.inmueble.titulo}". La solicitud ya fue enviada al propietario.`,
      'CO_SOLICITUD',
    )

    return ok(res, null, 'Solicitud conjunta enviada al propietario')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al responder la invitación', 500)
  }
}

const misCoSolicitudes = async (req, res) => {
  try {
    const recibidas = await prisma.coSolicitud.findMany({
      where: { receptorId: req.usuario.id, estado: 'PENDIENTE' },
      include: {
        remitente: { select: { id: true, nombre: true, fotoPerfil: true } },
        inmueble: {
          select: {
            id: true, titulo: true, zona: true, precio: true,
            imagenes: { take: 1, select: { url: true } },
            propietario: { select: { nombre: true } },
          },
        },
      },
      orderBy: { creadoEn: 'desc' },
    })

    return ok(res, recibidas, 'Invitaciones obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener invitaciones', 500)
  }
}

module.exports = {
  obtenerNotificaciones,
  marcarTodasLeidas,
  marcarLeida,
  eliminarNotificacion,
  coSolicitud,
  responderCoSolicitud,
  misCoSolicitudes,
}