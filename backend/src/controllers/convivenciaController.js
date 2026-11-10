const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')

// Nivel de compatibilidad a partir del puntaje (0-100)
const nivelDe = (p) => (p >= 80 ? 'ALTA' : p >= 60 ? 'MEDIA' : 'BAJA')

const obtenerMiPerfil = async (req, res) => {
  try {
    const perfil = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: req.usuario.id },
    })
    return ok(res, perfil, 'Perfil de convivencia')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener perfil', 500)
  }
}

const guardarPerfil = async (req, res) => {
  try {
    const {
      aceptaMascotas,
      fumaTabaco,
      cronotipo,
      ambienteEstudio,
      politicaVisitas,
      nivelOrden,
      descripcionSobreMi,
      zonasPreferidas,
      presupuestoMin,
      presupuestoMax,
    } = req.body

    if (!aceptaMascotas || !fumaTabaco || !cronotipo ||
        !ambienteEstudio || !politicaVisitas || !nivelOrden || !descripcionSobreMi) {
      return error(res, 'Todos los campos son obligatorios', 400)
    }

    const zonas = Array.isArray(zonasPreferidas) ? zonasPreferidas : []
    const pMin = presupuestoMin != null ? parseInt(presupuestoMin) : null
    const pMax = presupuestoMax != null ? parseInt(presupuestoMax) : null

    if (pMin != null && isNaN(pMin)) return error(res, 'Presupuesto mínimo inválido', 400)
    if (pMax != null && isNaN(pMax)) return error(res, 'Presupuesto máximo inválido', 400)
    if (pMin != null && pMax != null && pMin > pMax) {
      return error(res, 'El presupuesto mínimo no puede ser mayor al máximo', 400)
    }

    const datos = {
      aceptaMascotas, fumaTabaco, cronotipo,
      ambienteEstudio, politicaVisitas, nivelOrden,
      descripcionSobreMi,
      zonasPreferidas: zonas,
      presupuestoMin: pMin,
      presupuestoMax: pMax,
    }

    const perfil = await prisma.perfilConvivencia.upsert({
      where:  { usuarioId: req.usuario.id },
      create: { usuarioId: req.usuario.id, ...datos, activo: true },
      update: datos,
    })

    return ok(res, perfil, 'Perfil de convivencia guardado')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al guardar perfil', 500)
  }
}

const toggleVisibilidad = async (req, res) => {
  try {
    const { activo } = req.body

    if (typeof activo !== 'boolean') {
      return error(res, 'El campo activo debe ser boolean', 400)
    }

    const existe = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: req.usuario.id },
    })
    if (!existe) return error(res, 'No tenés un perfil de convivencia', 404)

    const perfil = await prisma.perfilConvivencia.update({
      where: { usuarioId: req.usuario.id },
      data:  { activo },
    })

    return ok(res, perfil, activo ? 'Perfil visible en la comunidad' : 'Perfil oculto')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al cambiar visibilidad', 500)
  }
}

const obtenerMatches = async (req, res) => {
  try {
    const miId = req.usuario.id

    const yo = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: miId },
    })
    if (!yo) {
      return error(res, 'Completá tu perfil de convivencia primero', 400)
    }

    const candidatos = await prisma.perfilConvivencia.findMany({
      where: {
        usuarioId: { not: miId },
        activo: true,
      },
      include: {
        usuario: {
          select: {
            id:         true,
            nombre:     true,
            fotoPerfil: true,
            telefono:   true,
            carrera: true,
            genero: true,
            ciudadOrigen: true,
            puntoInteres: {
              select: { nombre: true, tipo: true },
            },
          },
        },
      },
    })

    const misMatches = await prisma.matchConvivencia.findMany({
      where: {
        OR: [
          { solicitanteId: miId },
          { receptorId:    miId },
        ],
      },
    })

    const rechazadosIds = new Set(
      misMatches
        .filter(m => m.estado === 'RECHAZADO')
        .map(m => m.solicitanteId === miId ? m.receptorId : m.solicitanteId)
    )

    // El algoritmo ya no actúa como portero: ordena y etiqueta, pero no oculta.
    // Los descartes duros (mascotas, tabaco, presupuesto) sí se mantienen porque
    // representan incompatibilidades declaradas explícitamente por el usuario.
    const MINIMO_VISIBLE = 0
    const PESO      = 20   // 4 hábitos × 20 = 80
    const PESO_ZONA = 20   // zona compartida = 20

    const presupuestosChocan = (a, b) => {
      if (a.presupuestoMin == null || a.presupuestoMax == null) return false
      if (b.presupuestoMin == null || b.presupuestoMax == null) return false
      return a.presupuestoMin > b.presupuestoMax || b.presupuestoMin > a.presupuestoMax
    }

    const zonasEnComun = (a, b) => {
      const za = a.zonasPreferidas || []
      const zb = b.zonasPreferidas || []
      return za.filter(z => zb.includes(z))
    }

    const resultados = candidatos
      .filter(c => {
        if (rechazadosIds.has(c.usuarioId)) return false
        if (yo.aceptaMascotas === 'NO_TOLERO' && c.aceptaMascotas === 'SI') return false
        if (c.aceptaMascotas  === 'NO_TOLERO' && yo.aceptaMascotas === 'SI') return false
        if (yo.fumaTabaco     === 'NO_TOLERO' && c.fumaTabaco      === 'SI') return false
        if (c.fumaTabaco      === 'NO_TOLERO' && yo.fumaTabaco     === 'SI') return false
        if (presupuestosChocan(yo, c)) return false
        return true
      })
      .map(c => {
        let puntos = 0
        if (yo.cronotipo       === c.cronotipo)       puntos += PESO
        if (yo.ambienteEstudio === c.ambienteEstudio) puntos += PESO
        if (yo.politicaVisitas === c.politicaVisitas) puntos += PESO
        if (yo.nivelOrden      === c.nivelOrden)      puntos += PESO

        const comunes = zonasEnComun(yo, c)
        if (comunes.length > 0) puntos += PESO_ZONA

        const matchExistente = misMatches.find(m =>
          (m.solicitanteId === miId && m.receptorId === c.usuarioId) ||
          (m.receptorId    === miId && m.solicitanteId === c.usuarioId)
        )

        return {
          usuarioId:          c.usuarioId,
          nombre:             c.usuario.nombre,
          fotoPerfil:         c.usuario.fotoPerfil  ?? null,
          telefono:           c.usuario.telefono    ?? null,
          institucion:        c.usuario.puntoInteres?.nombre ?? null,
          descripcionSobreMi: c.descripcionSobreMi,
          zonasPreferidas:    c.zonasPreferidas || [],
          zonasEnComun:       comunes,
          presupuestoMin:     c.presupuestoMin,
          presupuestoMax:     c.presupuestoMax,
          carrera:            c.usuario.carrera      ?? null,
          genero:             c.usuario.genero       ?? null,
          ciudadOrigen:       c.usuario.ciudadOrigen ?? null,
          afinidad:           puntos,
          nivel:              nivelDe(puntos),
          matchId:            matchExistente?.id            ?? null,
          estadoMatch:        matchExistente?.estado        ?? null,
          soyElSolicitante:   matchExistente
                                ? matchExistente.solicitanteId === miId
                                : null,
          perfil: {
            aceptaMascotas:  c.aceptaMascotas,
            fumaTabaco:      c.fumaTabaco,
            cronotipo:       c.cronotipo,
            ambienteEstudio: c.ambienteEstudio,
            politicaVisitas: c.politicaVisitas,
            nivelOrden:      c.nivelOrden,
          },
        }
      })
      .filter(c  => c.afinidad >= MINIMO_VISIBLE)
      .sort((a, b) => b.afinidad - a.afinidad)

    return ok(res, resultados, `${resultados.length} estudiantes encontrados`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al calcular matches', 500)
  }
}

const solicitarMatch = async (req, res) => {
  try {
    const solicitanteId = req.usuario.id
    const receptorId    = parseInt(req.params.receptorId)

    if (isNaN(receptorId))            return error(res, 'ID de receptor inválido', 400)
    if (solicitanteId === receptorId) return error(res, 'No puedes enviarte una solicitud a ti mismo', 400)

    const receptorPerfil = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: receptorId },
    })
    if (!receptorPerfil)        return error(res, 'El usuario no tiene perfil de convivencia', 404)
    if (!receptorPerfil.activo) return error(res, 'Este usuario no está disponible actualmente', 400)

    const matchExistente = await prisma.matchConvivencia.findFirst({
      where: {
        OR: [
          { solicitanteId, receptorId },
          { solicitanteId: receptorId, receptorId: solicitanteId },
        ],
      },
    })

    if (matchExistente) {
      if (matchExistente.estado === 'ACEPTADO')  return error(res, 'Ya son conexiones', 409)
      if (matchExistente.estado === 'PENDIENTE') return error(res, 'Ya existe una solicitud pendiente', 409)
      if (matchExistente.estado === 'RECHAZADO') return error(res, 'Esta conexión no está disponible', 409)
    }

    const match = await prisma.matchConvivencia.create({
      data: { solicitanteId, receptorId, estado: 'PENDIENTE' },
    })

    const solicitante = await prisma.usuario.findUnique({
      where:  { id: solicitanteId },
      select: { nombre: true },
    })
    await crearNotificacion(
      receptorId,
      '¡Alguien quiere conectar!',
      `${solicitante.nombre} vio tu perfil de convivencia y quiere ser tu roommate.`,
      'MATCH_SOLICITUD',
    )

    return ok(res, match, 'Solicitud de conexión enviada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar solicitud', 500)
  }
}

/**
 * Conexión directa por correo.
 * Permite que dos estudiantes que ya se conocen se conecten sin pasar por el
 * cálculo de afinidad. El algoritmo asiste el descubrimiento, no lo condiciona.
 */
const conectarDirecto = async (req, res) => {
  try {
    const solicitanteId = req.usuario.id
    const email = String(req.body.email || '').trim().toLowerCase()

    if (!email || !email.includes('@')) {
      return error(res, 'Ingresá un correo válido', 400)
    }

    const miPerfil = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: solicitanteId },
    })
    if (!miPerfil) return error(res, 'Completá tu perfil de convivencia primero', 400)

    const receptor = await prisma.usuario.findFirst({
      where:  { email: { equals: email, mode: 'insensitive' } },
      select: { id: true, nombre: true, rol: true, activo: true },
    })

    if (!receptor)                      return error(res, 'No encontramos a nadie registrado con ese correo', 404)
    if (receptor.id === solicitanteId)  return error(res, 'Ese es tu propio correo', 400)
    if (!receptor.activo)               return error(res, 'Esta cuenta no está disponible', 400)
    if (receptor.rol !== 'ARRENDATARIO') {
      return error(res, 'Solo puedes conectar con estudiantes que buscan vivienda', 400)
    }

    const existente = await prisma.matchConvivencia.findFirst({
      where: {
        OR: [
          { solicitanteId, receptorId: receptor.id },
          { solicitanteId: receptor.id, receptorId: solicitanteId },
        ],
      },
    })

    if (existente) {
      if (existente.estado === 'ACEPTADO')  return error(res, `Ya estás conectado con ${receptor.nombre}`, 409)
      if (existente.estado === 'PENDIENTE') return error(res, 'Ya existe una solicitud pendiente con esta persona', 409)
      if (existente.estado === 'RECHAZADO') return error(res, 'Esta conexión no está disponible', 409)
    }

    const match = await prisma.matchConvivencia.create({
      data: { solicitanteId, receptorId: receptor.id, estado: 'PENDIENTE' },
    })

    const solicitante = await prisma.usuario.findUnique({
      where:  { id: solicitanteId },
      select: { nombre: true },
    })
    await crearNotificacion(
      receptor.id,
      '¡Alguien quiere conectar!',
      `${solicitante.nombre} te buscó por tu correo y quiere ser tu roommate.`,
      'MATCH_SOLICITUD',
    )

    return ok(res, match, `Solicitud enviada a ${receptor.nombre}`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar la solicitud', 500)
  }
}

const responderMatch = async (req, res) => {
  try {
    const receptorId = req.usuario.id
    const matchId    = parseInt(req.params.matchId)
    const { accion } = req.body

    if (isNaN(matchId)) return error(res, 'ID de solicitud inválido', 400)
    if (!accion || !['ACEPTAR', 'RECHAZAR'].includes(accion)) {
      return error(res, 'Acción inválida. Usa ACEPTAR o RECHAZAR', 400)
    }

    const match = await prisma.matchConvivencia.findUnique({ where: { id: matchId } })

    if (!match)                          return error(res, 'Solicitud no encontrada', 404)
    if (match.receptorId !== receptorId) return error(res, 'No autorizado', 403)
    if (match.estado     !== 'PENDIENTE') return error(res, 'Esta solicitud ya fue respondida', 400)

    if (accion === 'RECHAZAR') {
      await prisma.matchConvivencia.update({
        where: { id: matchId },
        data:  { estado: 'RECHAZADO' },
      })
      return ok(res, null, 'Solicitud rechazada')
    }

    const matchActualizado = await prisma.matchConvivencia.update({
      where: { id: matchId },
      data:  { estado: 'ACEPTADO' },
    })
    const receptor = await prisma.usuario.findUnique({
      where:  { id: receptorId },
      select: { nombre: true },
    })
    await crearNotificacion(
      match.solicitanteId,
      '¡Conexión aceptada!',
      `${receptor.nombre} aceptó tu solicitud. Ya puedes hablarle por WhatsApp.`,
      'MATCH_ACEPTADO',
    )
    return ok(res, matchActualizado, '¡Conexión aceptada!')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al responder solicitud', 500)
  }
}

const obtenerSolicitudesRecibidas = async (req, res) => {
  try {
    const miId = req.usuario.id

    const miPerfil = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: miId },
    })

    const solicitudes = await prisma.matchConvivencia.findMany({
      where:   { receptorId: miId, estado: 'PENDIENTE' },
      include: {
        solicitante: {
          select: {
            id:           true,
            nombre:       true,
            fotoPerfil:   true,
            telefono:     true,
            carrera:      true,
            genero:       true,
            ciudadOrigen: true,
            puntoInteres: { select: { nombre: true } },
            perfilConvivencia: {
              select: {
                aceptaMascotas:     true,
                fumaTabaco:         true,
                cronotipo:          true,
                ambienteEstudio:    true,
                politicaVisitas:    true,
                nivelOrden:         true,
                descripcionSobreMi: true,
                zonasPreferidas:    true,
                presupuestoMin:     true,
                presupuestoMax:     true,
              },
            },
          },
        },
      },
      orderBy: { creadoEn: 'desc' },
    })

    const resultado = solicitudes.map(s => {
      const u = s.solicitante
      const p = u.perfilConvivencia

      let afinidad = 0
      let comunes  = []
      if (miPerfil && p) {
        const PESO = 20
        if (miPerfil.cronotipo       === p.cronotipo)       afinidad += PESO
        if (miPerfil.ambienteEstudio === p.ambienteEstudio) afinidad += PESO
        if (miPerfil.politicaVisitas === p.politicaVisitas) afinidad += PESO
        if (miPerfil.nivelOrden      === p.nivelOrden)      afinidad += PESO
        const za = miPerfil.zonasPreferidas || []
        const zb = p.zonasPreferidas || []
        comunes = za.filter(z => zb.includes(z))
        if (comunes.length > 0) afinidad += 20
      }

      return {
        matchId:            s.id,
        usuarioId:          u.id,
        nombre:             u.nombre,
        fotoPerfil:         u.fotoPerfil   ?? null,
        telefono:           u.telefono     ?? null,
        institucion:        u.puntoInteres?.nombre ?? null,
        carrera:            u.carrera      ?? null,
        genero:             u.genero       ?? null,
        ciudadOrigen:       u.ciudadOrigen ?? null,
        descripcionSobreMi: p?.descripcionSobreMi ?? '',
        zonasPreferidas:    p?.zonasPreferidas || [],
        zonasEnComun:       comunes,
        presupuestoMin:     p?.presupuestoMin ?? null,
        presupuestoMax:     p?.presupuestoMax ?? null,
        afinidad,
        nivel:              nivelDe(afinidad),
        // Solo los 6 hábitos: el modelo de Flutter espera Map<String, String>.
        perfil: p
          ? {
              aceptaMascotas:  p.aceptaMascotas,
              fumaTabaco:      p.fumaTabaco,
              cronotipo:       p.cronotipo,
              ambienteEstudio: p.ambienteEstudio,
              politicaVisitas: p.politicaVisitas,
              nivelOrden:      p.nivelOrden,
            }
          : {},
        creadoEn: s.creadoEn,
      }
    })

    return ok(res, resultado, `${resultado.length} solicitudes recibidas`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener solicitudes recibidas', 500)
  }
}

const obtenerMisConexiones = async (req, res) => {
  try {
    const miId = req.usuario.id

    const miPerfil = await prisma.perfilConvivencia.findUnique({
      where: { usuarioId: miId },
    })

    const seleccionUsuario = {
      id:           true,
      nombre:       true,
      fotoPerfil:   true,
      telefono:     true,
      carrera:      true,
      genero:       true,
      ciudadOrigen: true,
      puntoInteres: { select: { nombre: true } },
      perfilConvivencia: {
        select: {
          aceptaMascotas:     true,
          fumaTabaco:         true,
          cronotipo:          true,
          ambienteEstudio:    true,
          politicaVisitas:    true,
          nivelOrden:         true,
          descripcionSobreMi: true,
          zonasPreferidas:    true,
          presupuestoMin:     true,
          presupuestoMax:     true,
        },
      },
    }

    const conexiones = await prisma.matchConvivencia.findMany({
      where: {
        estado: 'ACEPTADO',
        OR: [
          { solicitanteId: miId },
          { receptorId:    miId },
        ],
      },
      include: {
        solicitante: { select: seleccionUsuario },
        receptor:    { select: seleccionUsuario },
      },
      orderBy: { actualizadoEn: 'desc' },
    })

    const resultado = conexiones.map(c => {
      const otro = c.solicitanteId === miId ? c.receptor : c.solicitante
      const p    = otro.perfilConvivencia

      let afinidad = 0
      let comunes  = []
      if (miPerfil && p) {
        const PESO = 20
        if (miPerfil.cronotipo       === p.cronotipo)       afinidad += PESO
        if (miPerfil.ambienteEstudio === p.ambienteEstudio) afinidad += PESO
        if (miPerfil.politicaVisitas === p.politicaVisitas) afinidad += PESO
        if (miPerfil.nivelOrden      === p.nivelOrden)      afinidad += PESO
        const za = miPerfil.zonasPreferidas || []
        const zb = p.zonasPreferidas || []
        comunes = za.filter(z => zb.includes(z))
        if (comunes.length > 0) afinidad += 20
      }

      return {
        matchId:            c.id,
        usuarioId:          otro.id,
        nombre:             otro.nombre,
        fotoPerfil:         otro.fotoPerfil  ?? null,
        telefono:           otro.telefono    ?? null,
        institucion:        otro.puntoInteres?.nombre ?? null,
        carrera:            otro.carrera      ?? null,
        genero:             otro.genero       ?? null,
        ciudadOrigen:       otro.ciudadOrigen ?? null,
        descripcionSobreMi: p?.descripcionSobreMi ?? '',
        zonasPreferidas:    p?.zonasPreferidas || [],
        zonasEnComun:       comunes,
        presupuestoMin:     p?.presupuestoMin ?? null,
        presupuestoMax:     p?.presupuestoMax ?? null,
        afinidad,
        nivel:              nivelDe(afinidad),
        estadoMatch:        'ACEPTADO',
        soyElSolicitante:   c.solicitanteId === miId,
        perfil: p
          ? {
              aceptaMascotas:  p.aceptaMascotas,
              fumaTabaco:      p.fumaTabaco,
              cronotipo:       p.cronotipo,
              ambienteEstudio: p.ambienteEstudio,
              politicaVisitas: p.politicaVisitas,
              nivelOrden:      p.nivelOrden,
            }
          : {},
      }
    })

    return ok(res, resultado, `${resultado.length} conexiones activas`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener conexiones', 500)
  }
}

const finalizarConexion = async (req, res) => {
  try {
    const miId   = req.usuario.id
    const matchId = parseInt(req.params.matchId)

    if (isNaN(matchId)) return error(res, 'ID de conexión inválido', 400)

    const match = await prisma.matchConvivencia.findUnique({ where: { id: matchId } })

    if (!match) return error(res, 'Conexión no encontrada', 404)
    if (match.solicitanteId !== miId && match.receptorId !== miId) {
      return error(res, 'No autorizado', 403)
    }
    if (match.estado !== 'ACEPTADO') {
      return error(res, 'Solo se pueden finalizar conexiones activas', 400)
    }

    await prisma.matchConvivencia.delete({ where: { id: matchId } })

    const yo = await prisma.usuario.findUnique({
      where:  { id: miId },
      select: { nombre: true },
    })
    const otroId = match.solicitanteId === miId ? match.receptorId : match.solicitanteId

    await crearNotificacion(
      otroId,
      'Conexión finalizada',
      `${yo.nombre} finalizó la conexión de convivencia contigo.`,
      'MATCH_FINALIZADO',
    )

    return ok(res, null, 'Conexión finalizada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al finalizar la conexión', 500)
  }
}

const cancelarMatch = async (req, res) => {
  try {
    const solicitanteId = req.usuario.id
    const matchId       = parseInt(req.params.matchId)

    const match = await prisma.matchConvivencia.findUnique({ where: { id: matchId } })

    if (!match)                                return error(res, 'Solicitud no encontrada', 404)
    if (match.solicitanteId !== solicitanteId) return error(res, 'No autorizado', 403)
    if (match.estado        !== 'PENDIENTE')   return error(res, 'Solo se pueden cancelar solicitudes pendientes', 400)

    await prisma.matchConvivencia.delete({ where: { id: matchId } })
    return ok(res, null, 'Solicitud cancelada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al cancelar solicitud', 500)
  }
}

module.exports = {
  obtenerMiPerfil,
  guardarPerfil,
  toggleVisibilidad,
  obtenerMatches,
  solicitarMatch,
  conectarDirecto,
  responderMatch,
  obtenerSolicitudesRecibidas,
  obtenerMisConexiones,
  finalizarConexion,
  cancelarMatch,
}