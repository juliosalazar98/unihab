const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')
const cloudinary = require('cloudinary').v2
const crearReporte = async (req, res) => {
  const { inmuebleId, motivo, comentario } = req.body
  const reportanteId = req.usuario.id

  if (!inmuebleId || !motivo?.trim()) {
    return error(res, 'inmuebleId y motivo son requeridos', 400)
  }

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(inmuebleId) }
    })
    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)

    const reporte = await prisma.reporte.create({
      data: {
        inmuebleId: parseInt(inmuebleId),
        reportanteId,
        motivo: motivo.trim(),
        comentario: comentario?.trim() || null,
      }
    })

    return ok(res, reporte, 'Reporte enviado. El administrador lo revisará.', 201)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar reporte', 500)
  }
}
const obtenerReportes = async (req, res) => {
  try {
    const reportes = await prisma.reporte.findMany({
      include: {
        inmueble: {
          select: {
            id: true, titulo: true,
            propietario: { select: { id: true, nombre: true } }
          }
        },
        reportante: { select: { id: true, nombre: true, email: true } },
        apelacion: true,
      },
      orderBy: { creadoEn: 'desc' }
    })
    return ok(res, reportes, 'Reportes obtenidos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener reportes', 500)
  }
}
const descartarReporte = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const reporte = await prisma.reporte.update({
      where: { id },
      data: { estado: 'RESUELTO', resueltoEn: new Date() }
    })
    return ok(res, reporte, 'Reporte descartado')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al descartar reporte', 500)
  }
}
const sancionarReporte = async (req, res) => {
  try {
    const id = parseInt(req.params.id)

    const reporte = await prisma.reporte.findUnique({
      where: { id },
      include: { inmueble: true }
    })
    if (!reporte) return error(res, 'Reporte no encontrado', 404)

      await prisma.inmueble.update({
        where: { id: reporte.inmuebleId },
        data: {
          disponible: false,
          desactivadoPorAdmin: true,
          motivoRechazo: `Reportado por un usuario : ${reporte.motivo}`,
        }
      })

    const actualizado = await prisma.reporte.update({
      where: { id },
      data: { estado: 'RESUELTO', resueltoEn: new Date(), sancionado: true }
    })

    await crearNotificacion(
      reporte.inmueble.propietarioId,
      'Publicación desactivada',
      `Tu publicación "${reporte.inmueble.titulo}" fue desactivada por el equipo de UniHab tras revisar un reporte de un usuario.`,
      'GENERAL',
    )

    return ok(res, actualizado, 'Reporte sancionado. El inmueble fue desactivado.')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al sancionar reporte', 500)
  }
}
const aceptarApelacion = async (req, res) => {
  try {
    const id = parseInt(req.params.id)

    const reporte = await prisma.reporte.findUnique({
      where: { id },
      include: { inmueble: true, apelacion: true }
    })
    if (!reporte) return error(res, 'Reporte no encontrado', 404)
    if (reporte.apelacion?.imagenes) {
      await Promise.all(
        reporte.apelacion.imagenes.map(img =>
          cloudinary.uploader.destroy(img.publicId).catch(console.error)
        )
      )
    }
    if (reporte.apelacion) {
      await prisma.apelacion.delete({ where: { id: reporte.apelacion.id } })
    }
    await prisma.inmueble.update({
      where: { id: reporte.inmuebleId },
      data: {
        aprobado: true,
        disponible: true,
        desactivadoPorAdmin: false,
        motivoRechazo: null,
        enApelacion: false,
      }
    })
    await prisma.reporte.update({
      where: { id },
      data: { estado: 'RESUELTO', sancionado: false, resueltoEn: new Date() }
    })

    await crearNotificacion(
      reporte.inmueble.propietarioId,
      '¡Apelación aceptada!',
      `Tu apelación fue aceptada. Tu publicación "${reporte.inmueble.titulo}" fue reactivada y ya es visible para los estudiantes.`,
      'GENERAL',
    )

    return ok(res, null, 'Apelación aceptada. Inmueble reactivado.')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al aceptar apelación', 500)
  }
}
const rechazarApelacion = async (req, res) => {
  try {
    const id = parseInt(req.params.id)

    const reporte = await prisma.reporte.findUnique({
      where: { id },
      include: { inmueble: true, apelacion: true }
    })
    if (!reporte) return error(res, 'Reporte no encontrado', 404)
    if (reporte.apelacion?.imagenes) {
      await Promise.all(
        reporte.apelacion.imagenes.map(img =>
          cloudinary.uploader.destroy(img.publicId).catch(console.error)
        )
      )
    }
    if (reporte.apelacion) {
      await prisma.apelacion.delete({ where: { id: reporte.apelacion.id } })
    }
    await prisma.inmueble.update({
      where: { id: reporte.inmuebleId },
      data: { enApelacion: false }
    })
    await prisma.reporte.update({
      where: { id },
      data: { estado: 'RESUELTO', sancionado: true, resueltoEn: new Date() }
    })

    await crearNotificacion(
      reporte.inmueble.propietarioId,
      'Apelación rechazada',
      `Tu apelación para la publicación "${reporte.inmueble.titulo}" fue rechazada de forma definitiva. El inmueble permanecerá inactivo.`,
      'GENERAL',
    )

    return ok(res, null, 'Apelación rechazada. Sanción mantenida.')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al rechazar apelación', 500)
  }
}

module.exports = {
  crearReporte,
  obtenerReportes,
  descartarReporte,
  sancionarReporte,
  aceptarApelacion,
  rechazarApelacion
}
