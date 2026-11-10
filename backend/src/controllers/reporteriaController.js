const prisma = require('../config/prisma')
const { error } = require('../utils/respuesta')
const {
  crearDocumento, encabezado, tabla, resumen, pieDePagina, fechaCorta
} = require('../utils/pdf')

const labelTipo = (t) => ({
  CUARTO: 'Cuarto', DEPARTAMENTO: 'Departamento', COMPARTIDO: 'Compartido'
}[t] || t)

const labelEstadoInmueble = (i) => {
  if (i.aprobado && i.disponible) return 'Publicado'
  if (i.aprobado && !i.disponible) return 'Desactivado'
  if (!i.aprobado && !i.disponible) return 'Rechazado'
  return 'Pendiente'
}

const rangoFechas = (desde, hasta) => {
  if (!desde && !hasta) return null
  const f = {}
  if (desde) f.gte = new Date(desde)
  if (hasta) {
    const fin = new Date(hasta)
    fin.setHours(23, 59, 59, 999)
    f.lte = fin
  }
  return f
}

const pdfPublicaciones = async (req, res) => {
  const { estado, tipo, tipoOferta, buscar, precioMin, precioMax, desde, hasta } = req.query

  try {
    const filtros = {}
    if (estado === 'pendiente') filtros.aprobado = false
    if (estado === 'aprobado') filtros.aprobado = true
    if (tipo) filtros.tipo = tipo
    if (tipoOferta) filtros.tipoOferta = tipoOferta
    if (buscar?.trim()) {
      const q = buscar.trim()
      filtros.OR = [
        { titulo: { contains: q, mode: 'insensitive' } },
        { zona: { contains: q, mode: 'insensitive' } },
        { propietario: { nombre: { contains: q, mode: 'insensitive' } } },
      ]
    }
    if (precioMin || precioMax) {
      filtros.precio = {}
      if (precioMin) filtros.precio.gte = parseFloat(precioMin)
      if (precioMax) filtros.precio.lte = parseFloat(precioMax)
    }
    const rango = rangoFechas(desde, hasta)
    if (rango) filtros.creadoEn = rango

    const inmuebles = await prisma.inmueble.findMany({
      where: filtros,
      include: { propietario: { select: { nombre: true } } },
      orderBy: { creadoEn: 'desc' }
    })

    const etiquetas = []
    if (estado) etiquetas.push(`Estado: ${estado}`)
    if (tipo) etiquetas.push(`Tipo: ${labelTipo(tipo)}`)
    if (tipoOferta) etiquetas.push(`Oferta: ${tipoOferta}`)
    if (buscar) etiquetas.push(`Búsqueda: "${buscar}"`)
    if (precioMin || precioMax) etiquetas.push(`Precio: ${precioMin || '0'} – ${precioMax || '∞'} Bs.`)
    if (desde || hasta) etiquetas.push(`Fechas: ${desde || '...'} a ${hasta || '...'}`)

      const doc = crearDocumento(res, `unihab-publicaciones-${Date.now()}.pdf`, { horizontal: true })
    let y = encabezado(
      doc,
      'Reporte de Publicaciones',
      `${inmuebles.length} publicaciones encontradas`,
      etiquetas
    )

    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Título', campo: 'titulo', ancho: 240 },
        { titulo: 'Propietario', campo: 'propietario', ancho: 140 },
        { titulo: 'Tipo', campo: 'tipo', ancho: 70 },
        { titulo: 'Zona', campo: 'zona', ancho: 110 },
        { titulo: 'Precio', campo: 'precio', ancho: 75, align: 'right' },
        { titulo: 'Estado', campo: 'estado', ancho: 70 },
        { titulo: 'Fecha', campo: 'fecha', ancho: 57 },
      ],
      filas: inmuebles.map(i => ({
        titulo: i.titulo,
        propietario: i.propietario?.nombre || '—',
        tipo: labelTipo(i.tipo),
        zona: i.zona,
        precio: `${i.precio}`,
        estado: labelEstadoInmueble(i),
        fecha: fechaCorta(i.creadoEn),
      }))
    })

    const publicados = inmuebles.filter(i => i.aprobado && i.disponible).length
    const pendientes = inmuebles.filter(i => !i.aprobado && i.disponible).length
    const rechazados = inmuebles.filter(i => !i.aprobado && !i.disponible).length
    const precioProm = inmuebles.length
      ? (inmuebles.reduce((a, i) => a + i.precio, 0) / inmuebles.length).toFixed(0)
      : 0

    resumen(doc, y, [
      { label: 'Total', valor: inmuebles.length },
      { label: 'Publicados', valor: publicados },
      { label: 'Pendientes', valor: pendientes },
      { label: 'Rechazados', valor: rechazados },
      { label: 'Precio prom.', valor: `${precioProm} Bs.` },
    ])

    pieDePagina(doc)
    doc.end()
  } catch (e) {
    console.error(e)
    return error(res, 'Error al generar el reporte', 500)
  }
}

const pdfUsuarios = async (req, res) => {
  const { rol, activo, verificacion, buscar, desde, hasta } = req.query

  try {
    const filtros = {}
    if (rol) filtros.rol = rol
    if (activo !== undefined && activo !== '') filtros.activo = activo === 'true'
    if (verificacion) {
      filtros.estadoVerificacion = verificacion === 'NO_VERIFICADO'
        ? { in: ['NO_VERIFICADO', 'RECHAZADO'] }
        : verificacion
    }
    if (buscar?.trim()) {
      filtros.OR = [
        { nombre: { contains: buscar.trim(), mode: 'insensitive' } },
        { email: { contains: buscar.trim(), mode: 'insensitive' } },
      ]
    }
    const rango = rangoFechas(desde, hasta)
    if (rango) filtros.creadoEn = rango

    const usuarios = await prisma.usuario.findMany({
      where: filtros,
      select: {
        nombre: true, email: true, rol: true, activo: true,
        estadoVerificacion: true, creadoEn: true,
        _count: { select: { inmuebles: true } }
      },
      orderBy: { creadoEn: 'desc' }
    })

    const etiquetas = []
    if (rol) etiquetas.push(`Rol: ${rol}`)
    if (activo !== undefined && activo !== '') etiquetas.push(`Estado: ${activo === 'true' ? 'Activos' : 'Suspendidos'}`)
    if (verificacion) etiquetas.push(`Verificación: ${verificacion}`)
    if (buscar) etiquetas.push(`Búsqueda: "${buscar}"`)
    if (desde || hasta) etiquetas.push(`Fechas: ${desde || '...'} a ${hasta || '...'}`)

      const doc = crearDocumento(res, `unihab-usuarios-${Date.now()}.pdf`, { horizontal: true })
    let y = encabezado(
      doc,
      'Reporte de Usuarios',
      `${usuarios.length} usuarios encontrados`,
      etiquetas
    )

    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Nombre', campo: 'nombre', ancho: 180 },
        { titulo: 'Email', campo: 'email', ancho: 235 },
        { titulo: 'Rol', campo: 'rol', ancho: 100 },
        { titulo: 'Estado', campo: 'estado', ancho: 95 },
        { titulo: 'Publicaciones', campo: 'publicaciones', ancho: 70, align: 'right' },
        { titulo: 'Registro', campo: 'fecha', ancho: 82 },
      ],
      filas: usuarios.map(u => ({
        nombre: u.nombre,
        email: u.email,
        rol: u.rol === 'ARRENDATARIO' ? 'Arrendatario'
           : u.rol === 'PROPIETARIO' ? 'Propietario' : 'Admin',
        estado: u.activo ? 'Activo' : 'Suspendido',
        publicaciones: u._count.inmuebles,
        fecha: fechaCorta(u.creadoEn),
      }))
    })

    const arrendatarios = usuarios.filter(u => u.rol === 'ARRENDATARIO').length
    const propietarios = usuarios.filter(u => u.rol === 'PROPIETARIO').length
    const verificados = usuarios.filter(u => u.estadoVerificacion === 'APROBADO').length
    const suspendidos = usuarios.filter(u => !u.activo).length

    resumen(doc, y, [
      { label: 'Total', valor: usuarios.length },
      { label: 'Arrendatarios', valor: arrendatarios },
      { label: 'Propietarios', valor: propietarios },
      { label: 'Verificados', valor: verificados },
      { label: 'Suspendidos', valor: suspendidos },
    ])

    pieDePagina(doc)
    doc.end()
  } catch (e) {
    console.error(e)
    return error(res, 'Error al generar el reporte', 500)
  }
}

const pdfModeracion = async (req, res) => {
  const { estado, desde, hasta } = req.query

  try {
    const filtros = {}
    if (estado) filtros.estado = estado
    const rango = rangoFechas(desde, hasta)
    if (rango) filtros.creadoEn = rango

    const reportes = await prisma.reporte.findMany({
      where: filtros,
      include: {
        inmueble: {
          select: { titulo: true, propietario: { select: { nombre: true } } }
        },
        reportante: { select: { nombre: true } },
      },
      orderBy: { creadoEn: 'desc' }
    })

    const etiquetas = []
    if (estado) etiquetas.push(`Estado: ${estado}`)
    if (desde || hasta) etiquetas.push(`Fechas: ${desde || '...'} a ${hasta || '...'}`)

      const doc = crearDocumento(res, `unihab-moderacion-${Date.now()}.pdf`, { horizontal: true })
    let y = encabezado(
      doc,
      'Reporte de Moderación',
      `${reportes.length} reportes de estudiantes`,
      etiquetas
    )

    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Inmueble', campo: 'inmueble', ancho: 200 },
        { titulo: 'Propietario', campo: 'propietario', ancho: 130 },
        { titulo: 'Reportado por', campo: 'reportante', ancho: 130 },
        { titulo: 'Motivo', campo: 'motivo', ancho: 150 },
        { titulo: 'Estado', campo: 'estado', ancho: 80 },
        { titulo: 'Fecha', campo: 'fecha', ancho: 72 },
      ],
      filas: reportes.map(r => ({
        inmueble: r.inmueble?.titulo || '—',
        propietario: r.inmueble?.propietario?.nombre || '—',
        reportante: r.reportante?.nombre || '—',
        motivo: r.motivo,
        estado: r.estado === 'RESUELTO' ? 'Resuelto'
              : r.estado === 'APELADO' ? 'Apelado' : 'Pendiente',
        fecha: fechaCorta(r.creadoEn),
      }))
    })

    const pendientes = reportes.filter(r => r.estado === 'PENDIENTE').length
    const apelados = reportes.filter(r => r.estado === 'APELADO').length
    const sancionados = reportes.filter(r => r.sancionado).length
    const resueltos = reportes.filter(r => r.estado === 'RESUELTO').length

    resumen(doc, y, [
      { label: 'Total', valor: reportes.length },
      { label: 'Pendientes', valor: pendientes },
      { label: 'Apelados', valor: apelados },
      { label: 'Resueltos', valor: resueltos },
      { label: 'Sancionados', valor: sancionados },
    ])

    pieDePagina(doc)
    doc.end()
  } catch (e) {
    console.error(e)
    return error(res, 'Error al generar el reporte', 500)
  }
}

const pdfGeneral = async (req, res) => {
  try {
    const [
      totalEstudiantes, totalPropietarios, verificados, verificacionesPendientes,
      totalInmuebles, publicados, pendientes, rechazados,
      totalSolicitudes, matchesAceptados, totalReportes, sancionados
    ] = await Promise.all([
      prisma.usuario.count({ where: { rol: 'ARRENDATARIO' } }),
      prisma.usuario.count({ where: { rol: 'PROPIETARIO' } }),
      prisma.usuario.count({ where: { rol: 'PROPIETARIO', estadoVerificacion: 'APROBADO' } }),
      prisma.usuario.count({ where: { rol: 'PROPIETARIO', estadoVerificacion: 'PENDIENTE' } }),
      prisma.inmueble.count(),
      prisma.inmueble.count({ where: { aprobado: true, disponible: true } }),
      prisma.inmueble.count({ where: { aprobado: false, disponible: true } }),
      prisma.inmueble.count({ where: { aprobado: false, disponible: false } }),
      prisma.solicitud.count(),
      prisma.matchConvivencia.count({ where: { estado: 'ACEPTADO' } }),
      prisma.reporte.count(),
      prisma.reporte.count({ where: { sancionado: true } }),
    ])

    const porTipo = await prisma.inmueble.groupBy({
      by: ['tipo'],
      _count: { id: true },
      _avg: { precio: true },
    })

    const doc = crearDocumento(res, `unihab-general-${Date.now()}.pdf`)
    let y = encabezado(
      doc,
      'Reporte General del Sistema',
      'Resumen consolidado de la plataforma UniHab'
    )

    const seccion = (titulo, posY) => {
      doc.fillColor('#1F2937').fontSize(11).font('Helvetica-Bold')
         .text(titulo, 40, posY)
      return posY + 20
    }

    y = seccion('Usuarios', y)
    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Indicador', campo: 'indicador', ancho: 300 },
        { titulo: 'Cantidad', campo: 'valor', ancho: 215, align: 'right' },
      ],
      filas: [
        { indicador: 'Arrendatarios registrados', valor: totalEstudiantes },
        { indicador: 'Propietarios registrados', valor: totalPropietarios },
        { indicador: 'Propietarios verificados', valor: verificados },
        { indicador: 'Verificaciones pendientes', valor: verificacionesPendientes },
      ]
    })

    y = seccion('Publicaciones', y + 18)
    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Indicador', campo: 'indicador', ancho: 300 },
        { titulo: 'Cantidad', campo: 'valor', ancho: 215, align: 'right' },
      ],
      filas: [
        { indicador: 'Total de publicaciones', valor: totalInmuebles },
        { indicador: 'Publicadas y disponibles', valor: publicados },
        { indicador: 'Pendientes de aprobación', valor: pendientes },
        { indicador: 'Rechazadas', valor: rechazados },
      ]
    })

    y = seccion('Publicaciones por tipo', y + 18)
    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Tipo', campo: 'tipo', ancho: 200 },
        { titulo: 'Cantidad', campo: 'cantidad', ancho: 157, align: 'right' },
        { titulo: 'Precio promedio', campo: 'promedio', ancho: 158, align: 'right' },
      ],
      filas: porTipo.map(t => ({
        tipo: labelTipo(t.tipo),
        cantidad: t._count.id,
        promedio: `${(t._avg.precio || 0).toFixed(0)} Bs.`,
      }))
    })

    y = seccion('Actividad y moderación', y + 18)
    y = tabla(doc, {
      y,
      columnas: [
        { titulo: 'Indicador', campo: 'indicador', ancho: 300 },
        { titulo: 'Cantidad', campo: 'valor', ancho: 215, align: 'right' },
      ],
      filas: [
        { indicador: 'Solicitudes de contacto enviadas', valor: totalSolicitudes },
        { indicador: 'Conexiones de convivencia aceptadas', valor: matchesAceptados },
        { indicador: 'Reportes recibidos', valor: totalReportes },
        { indicador: 'Inmuebles sancionados', valor: sancionados },
      ]
    })

    pieDePagina(doc)
    doc.end()
  } catch (e) {
    console.error(e)
    return error(res, 'Error al generar el reporte', 500)
  }
}

module.exports = { pdfPublicaciones, pdfUsuarios, pdfModeracion, pdfGeneral }