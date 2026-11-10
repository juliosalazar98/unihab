const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')
const obtenerEstadisticasPropietario = async (req, res) => {
  try {
    const propietarioId = req.usuario.id
    const inmuebles = await prisma.inmueble.findMany({
      where: { propietarioId },
      select: { id: true, titulo: true }
    })

    const inmuebleIds = inmuebles.map(i => i.id)

    if (inmuebleIds.length === 0) {
      return ok(res, {
        vistas: 0, solicitudes: 0, conversion: 0,
        solicitudesMensuales: [], popularidadInmuebles: []
      }, 'Sin datos')
    }
    const vistas = await prisma.inmuebleVisto.count({
      where: { inmuebleId: { in: inmuebleIds } }
    })

    const solicitudesTotal = await prisma.solicitud.count({
      where: { inmuebleId: { in: inmuebleIds } }
    })

    const conversion = vistas > 0
      ? parseFloat(((solicitudesTotal / vistas) * 100).toFixed(1))
      : 0
    const hace6Meses = new Date()
    hace6Meses.setMonth(hace6Meses.getMonth() - 5)
    hace6Meses.setDate(1)
    hace6Meses.setHours(0, 0, 0, 0)

    const solicitudesRaw = await prisma.solicitud.findMany({
      where: {
        inmuebleId: { in: inmuebleIds },
        creadoEn:   { gte: hace6Meses }
      },
      select: { creadoEn: true }
    })
    const mesesMap = {}
    solicitudesRaw.forEach(s => {
      const d   = new Date(s.creadoEn)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      mesesMap[key] = (mesesMap[key] || 0) + 1
    })
    const solicitudesMensuales = []
    for (let i = 5; i >= 0; i--) {
      const d   = new Date()
      d.setMonth(d.getMonth() - i)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      solicitudesMensuales.push({ mes: key, cantidad: mesesMap[key] || 0 })
    }
    const porInmueble = await prisma.solicitud.groupBy({
      by:    ['inmuebleId'],
      where: { inmuebleId: { in: inmuebleIds } },
      _count: { id: true }
    })

    const popularidadInmuebles = porInmueble
      .map(s => {
        const inm = inmuebles.find(i => i.id === s.inmuebleId)
        return {
          inmuebleId:  s.inmuebleId,
          titulo:      inm?.titulo ?? 'Desconocido',
          solicitudes: s._count.id,
          porcentaje:  solicitudesTotal > 0
            ? parseFloat(((s._count.id / solicitudesTotal) * 100).toFixed(1))
            : 0
        }
      })
      .sort((a, b) => b.solicitudes - a.solicitudes)

    return ok(res, {
      vistas, solicitudes: solicitudesTotal, conversion,
      solicitudesMensuales, popularidadInmuebles
    }, 'Estadísticas obtenidas')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener estadísticas', 500)
  }
}

const obtenerEstadisticasAdmin = async (req, res) => {
  try {
    const totalEstudiantes = await prisma.usuario.count({
      where: { rol: 'ARRENDATARIO' }
    })

    const totalPropietarios = await prisma.usuario.count({
      where: { rol: 'PROPIETARIO' }
    })

    const verificacionesPendientes = await prisma.usuario.count({
      where: { rol: 'PROPIETARIO', estadoVerificacion: 'PENDIENTE' }
    })

    const inmueblesPublicados = await prisma.inmueble.count({
      where: { aprobado: true }
    })

    const matchesExitosos = await prisma.matchConvivencia.count({
      where: { estado: 'ACEPTADO' }
    })
    const hace7Meses = new Date()
    hace7Meses.setMonth(hace7Meses.getMonth() - 6)
    hace7Meses.setDate(1)
    hace7Meses.setHours(0, 0, 0, 0)

    const usuariosRaw = await prisma.usuario.findMany({
      where: { creadoEn: { gte: hace7Meses }, rol: { in: ['ARRENDATARIO', 'PROPIETARIO'] } },
      select: { creadoEn: true, rol: true }
    })

    const mesesMap = {}
    usuariosRaw.forEach(u => {
      const d = new Date(u.creadoEn)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      if (!mesesMap[key]) mesesMap[key] = { estudiantes: 0, propietarios: 0 }
      if (u.rol === 'ARRENDATARIO') mesesMap[key].estudiantes++
      else mesesMap[key].propietarios++
    })

    const nombresMes = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic']
    const registroMensual = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date()
      d.setMonth(d.getMonth() - i)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      registroMensual.push({
        mes: nombresMes[d.getMonth()],
        estudiantes: mesesMap[key]?.estudiantes || 0,
        propietarios: mesesMap[key]?.propietarios || 0,
      })
    }
    const porTipoRaw = await prisma.inmueble.groupBy({
      by: ['tipo'],
      _count: { id: true }
    })
    const inmueblesPorTipo = porTipoRaw.map(t => ({
      tipo: t.tipo,
      cantidad: t._count.id
    }))
    const ultimasVerificaciones = await prisma.usuario.findMany({
      where: { rol: 'PROPIETARIO', estadoVerificacion: 'PENDIENTE' },
      select: { id: true, nombre: true, actualizadoEn: true },
      orderBy: { actualizadoEn: 'desc' },
      take: 3
    })
    const ultimasPublicaciones = await prisma.inmueble.findMany({
      where: { aprobado: false, disponible: true },
      select: {
        id: true, titulo: true, creadoEn: true,
        propietario: { select: { nombre: true } }
      },
      orderBy: { creadoEn: 'desc' },
      take: 5
    })

    return ok(res, {
      totalEstudiantes,
      totalPropietarios,
      verificacionesPendientes,
      inmueblesPublicados,
      matchesExitosos,
      registroMensual,
      inmueblesPorTipo,
      ultimasVerificaciones,
      ultimasPublicaciones,
    }, 'Estadísticas de admin obtenidas')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener estadísticas de admin', 500)
  }
}

module.exports = { obtenerEstadisticasPropietario, obtenerEstadisticasAdmin }