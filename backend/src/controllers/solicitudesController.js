const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')
const crearSolicitud = async (req, res) => {
  const { inmuebleId } = req.body
  const arrendatarioId = req.usuario.id

  if (!inmuebleId) {
    return error(res, 'inmuebleId es requerido', 400)
  }

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(inmuebleId) },
      include: {
        propietario: {
          select: { id: true, nombre: true, telefono: true }
        }
      }
    })

    if (!inmueble)           return error(res, 'Inmueble no encontrado', 404)
    if (!inmueble.aprobado)  return error(res, 'Inmueble no disponible', 400)
    if (inmueble.propietarioId === arrendatarioId)
      return error(res, 'No podés contactar tu propio inmueble', 400)
    await prisma.solicitud.upsert({
      where: {
        arrendatarioId_inmuebleId: {
          arrendatarioId,
          inmuebleId: parseInt(inmuebleId)
        }
      },
      update: {
        creadoEn: new Date(),
        atendida: false,
        estado: 'PENDIENTE',
      },
      create: { arrendatarioId, inmuebleId: parseInt(inmuebleId) }
    })
    await crearNotificacion(
      inmueble.propietarioId,
      '¡Nueva solicitud recibida!',
      `${req.usuario.nombre} está interesado en tu inmueble "${inmueble.titulo}".`,
      'NUEVA_SOLICITUD',
    )
  

    return ok(res, {
      telefono: inmueble.propietario.telefono ?? null,
      propietario: inmueble.propietario.nombre
    }, 'Solicitud registrada correctamente')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al registrar solicitud')
  }
}
const obtenerSolicitudesPropietario = async (req, res) => {
  try {
    const solicitudes = await prisma.solicitud.findMany({
      where: {
        inmueble: { propietarioId: req.usuario.id },
        atendida: false,
      },
      include: {
        arrendatario: {
          select: {
            id: true,
            nombre: true,
            email: true,
            telefono: true,
            fotoPerfil: true,      // ← estos 4 faltan
            carrera: true,
            genero: true,
            ciudadOrigen: true,
            puntoInteres: { select: { nombre: true, tipo: true } },
          }
        },
        inmueble: {
          select: { id: true, titulo: true, zona: true }
        }
      },
      orderBy: { creadoEn: 'desc' }
    })

    const porCoSolicitud = {}
    for (const s of solicitudes) {
      if (s.coSolicitudId == null) continue
      porCoSolicitud[s.coSolicitudId] ??= []
      porCoSolicitud[s.coSolicitudId].push(s.arrendatario)
    }

    const conCompaneros = solicitudes.map(s => ({
      ...s,
      esConjunta: s.coSolicitudId != null,
      companeros: s.coSolicitudId == null
        ? []
        : (porCoSolicitud[s.coSolicitudId] || [])
            .filter(a => a.id !== s.arrendatario.id),
    }))

    return ok(res, conCompaneros, 'Solicitudes obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener solicitudes')
  }
}

const marcarAtendida = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const { estado } = req.body // 'ATENDIDA' | 'RECHAZADA'

    if (!['ATENDIDA', 'RECHAZADA'].includes(estado)) {
      return error(res, 'estado debe ser ATENDIDA o RECHAZADA', 400)
    }

    const solicitud = await prisma.solicitud.findUnique({
      where: { id },
      include: { inmueble: { select: { propietarioId: true } } }
    })

    if (!solicitud) return error(res, 'Solicitud no encontrada', 404)
    if (solicitud.inmueble.propietarioId !== req.usuario.id)
      return error(res, 'No autorizado', 403)

    await prisma.solicitud.update({
      where: { id },
      data:  { atendida: true, estado }
    })

    return ok(res, null, `Solicitud marcada como ${estado.toLowerCase()}`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al marcar solicitud', 500)
  }
}
const obtenerSolicitudesAtendidas = async (req, res) => {
  try {
    const solicitudes = await prisma.solicitud.findMany({
      where: {
        inmueble: { propietarioId: req.usuario.id },
        atendida: true,
      },
      include: {
        arrendatario: {
          select: {
            id: true, nombre: true, email: true,
            telefono: true, fotoPerfil: true,
          }
        },
        inmueble: { select: { id: true, titulo: true, zona: true } }
      },
      orderBy: { actualizadoEn: 'desc' }
    })
    return ok(res, solicitudes, 'Historial obtenido')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener historial', 500)
  }
}
const obtenerPostulacionesArrendatario = async (req, res) => {
  try {
    const solicitudes = await prisma.solicitud.findMany({
      where: { arrendatarioId: req.usuario.id },
      include: {
        inmueble: {
          select: {
            id: true, titulo: true, zona: true, precio: true,
            aprobado: true, disponible: true,
            imagenes: { take: 1, select: { url: true } },
            propietario: { select: { nombre: true } }
          }
        }
      },
      orderBy: { creadoEn: 'desc' }
    })

    const idsCo = solicitudes
      .map(s => s.coSolicitudId)
      .filter(v => v != null)

    let companerosPorCo = {}
    if (idsCo.length > 0) {
      const hermanas = await prisma.solicitud.findMany({
        where: {
          coSolicitudId: { in: idsCo },
          arrendatarioId: { not: req.usuario.id },
        },
        include: {
          arrendatario: { select: { id: true, nombre: true, fotoPerfil: true } },
        },
      })
      for (const h of hermanas) {
        companerosPorCo[h.coSolicitudId] ??= []
        companerosPorCo[h.coSolicitudId].push(h.arrendatario)
      }
    }

    const resultado = solicitudes.map(s => ({
      ...s,
      esConjunta: s.coSolicitudId != null,
      companeros: s.coSolicitudId == null
        ? []
        : (companerosPorCo[s.coSolicitudId] || []),
    }))

    return ok(res, resultado, 'Postulaciones obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener postulaciones', 500)
  }
}


module.exports = { crearSolicitud, obtenerSolicitudesPropietario, marcarAtendida, obtenerSolicitudesAtendidas, obtenerPostulacionesArrendatario  }
