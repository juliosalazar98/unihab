const prisma = require('../config/prisma')
const { cloudinary } = require('../config/multer')
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')

const crearInmueble = async (req, res) => {
  const {
    titulo, descripcion, precio, tipo, zona, direccion, latitud, longitud,
    luzIncluida, aguaIncluida, internetIncluido, gasIncluido,
    tamano, piso, amoblado, permiteMascotas, generoPermitido,
    numDormitorios, numBanos, tieneParqueo, habitantesMax,
    habitacionesTotales, habitacionesDisponibles, banoCompartido,
    soloEstudiantes, generoConvivientes, edadMinima, edadMaxima,
    reglasComunes, observaciones
  } = req.body

  if (!titulo || !precio || !tipo || !zona || !direccion) {
    return error(res, 'Completá todos los campos obligatorios', 400)
  }

  const tiposValidos = ['CUARTO', 'DEPARTAMENTO', 'COMPARTIDO']
  if (!tiposValidos.includes(tipo)) {
    return error(res, 'Tipo inválido. Debe ser CUARTO, DEPARTAMENTO o COMPARTIDO', 400)
  }

  if (req.files && req.files.length < 3) {
    return error(res, 'Debés subir mínimo 3 fotos del inmueble', 400)
  }

  const camposNumericos = [
    { campo: 'precio', valor: precio, obligatorio: true },
    { campo: 'tamano', valor: tamano },
    { campo: 'piso', valor: piso, entero: true },
    { campo: 'numDormitorios', valor: numDormitorios, entero: true },
    { campo: 'numBanos', valor: numBanos, entero: true },
    { campo: 'habitantesMax', valor: habitantesMax, entero: true },
    { campo: 'habitacionesTotales', valor: habitacionesTotales, entero: true },
    { campo: 'habitacionesDisponibles', valor: habitacionesDisponibles, entero: true },
    { campo: 'edadMinima', valor: edadMinima, entero: true },
    { campo: 'edadMaxima', valor: edadMaxima, entero: true },
  ]
  for (const { campo, valor, entero, obligatorio } of camposNumericos) {
    if (valor === undefined || valor === null || valor === '') {
      if (obligatorio) return error(res, `El campo "${campo}" es obligatorio`, 400)
      continue
    }
    const num = entero ? parseInt(valor) : parseFloat(valor)
    if (isNaN(num)) {
      return error(res, `El campo "${campo}" debe ser un número válido`, 400)
    }
  }

  try {
    let habitacionesOcupadas = null
    if (tipo === 'COMPARTIDO' && habitacionesTotales && habitacionesDisponibles) {
      habitacionesOcupadas = parseInt(habitacionesTotales) - parseInt(habitacionesDisponibles)
    }

    const inmueble = await prisma.inmueble.create({
      data: {
        titulo,
        descripcion: descripcion || null,
        precio: parseFloat(precio),
        tipo,
        zona,
        direccion,
        latitud: latitud ? parseFloat(latitud) : null,
        longitud: longitud ? parseFloat(longitud) : null,
        propietarioId: req.usuario.id,
        tipoOferta: ['ALQUILER', 'ANTICRETICO'].includes(req.body.tipoOferta)
          ? req.body.tipoOferta
          : 'ALQUILER',
        luzIncluida: luzIncluida === 'true' || luzIncluida === true,
        aguaIncluida: aguaIncluida === 'true' || aguaIncluida === true,
        internetIncluido: internetIncluido === 'true' || internetIncluido === true,
        gasIncluido: gasIncluido === 'true' || gasIncluido === true,
        tamano: tamano ? parseFloat(tamano) : null,
        piso: piso ? parseInt(piso) : null,
        amoblado: amoblado !== undefined ? amoblado === 'true' || amoblado === true : null,
        permiteMascotas: permiteMascotas !== undefined ? permiteMascotas === 'true' || permiteMascotas === true : null,
        generoPermitido: generoPermitido || null,
        numDormitorios: numDormitorios ? parseInt(numDormitorios) : null,
        numBanos: numBanos ? parseInt(numBanos) : null,
        tieneParqueo: tieneParqueo !== undefined ? tieneParqueo === 'true' || tieneParqueo === true : null,
        habitantesMax: habitantesMax ? parseInt(habitantesMax) : null,
        habitacionesTotales: habitacionesTotales ? parseInt(habitacionesTotales) : null,
        habitacionesDisponibles: habitacionesDisponibles ? parseInt(habitacionesDisponibles) : null,
        banoCompartido: banoCompartido !== undefined ? banoCompartido === 'true' || banoCompartido === true : null,
        soloEstudiantes: soloEstudiantes !== undefined ? soloEstudiantes === 'true' || soloEstudiantes === true : null,
        generoConvivientes: generoConvivientes || null,
        edadMinima: edadMinima ? parseInt(edadMinima) : null,
        edadMaxima: edadMaxima ? parseInt(edadMaxima) : null,
        reglasComunes: reglasComunes || null,
        observaciones: observaciones || null,
      }
    })
    if (req.files && req.files.length > 0) {
      const imagenes = req.files.map(file => ({
        url: file.path,
        publicId: file.filename,
        inmuebleId: inmueble.id
      }))
      await prisma.imagen.createMany({ data: imagenes })
    }

    const inmuebleCompleto = await prisma.inmueble.findUnique({
      where: { id: inmueble.id },
      include: { imagenes: true }
    })

    return ok(res, inmuebleCompleto, 'Inmueble creado exitosamente', 201)

  } catch (e) {
    console.error(e)
    return error(res, 'Error al crear inmueble')
  }
}

const obtenerInmuebles = async (req, res) => {
  const {
    zona, tipo, tipoOferta, precioMin, precioMax, orden,
    luz, agua, internet, gas,
    page = 1, limit = 10
  } = req.query

  const filtros = { aprobado: true, disponible: true }
  if (zona) filtros.zona = { contains: zona, mode: 'insensitive' }
  if (tipo) filtros.tipo = tipo
  if (tipoOferta) filtros.tipoOferta = tipoOferta
  if (luz === 'true') filtros.luzIncluida = true
  if (agua === 'true') filtros.aguaIncluida = true
  if (internet === 'true') filtros.internetIncluido = true
  if (gas === 'true') filtros.gasIncluido = true
  if (precioMin || precioMax) {
    filtros.precio = {}
    if (precioMin) filtros.precio.gte = parseFloat(precioMin)
    if (precioMax) filtros.precio.lte = parseFloat(precioMax)
  }

  const ordenamientos = {
    recientes:    { creadoEn: 'desc' },
    precio_asc:   { precio: 'asc' },
    precio_desc:  { precio: 'desc' },
  }
  const orderBy = ordenamientos[orden] || ordenamientos.recientes

  try {
    const total = await prisma.inmueble.count({ where: filtros })
    const inmuebles = await prisma.inmueble.findMany({
      where: filtros,
      include: {
        imagenes: true,
        propietario: {
          select: { id: true, nombre: true, email: true, verificado: true }
        }
      },
      orderBy,
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit)
    })

    return ok(res, {
      inmuebles,
      total,
      pagina: parseInt(page),
      totalPaginas: Math.ceil(total / parseInt(limit))
    }, 'Inmuebles obtenidos')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener inmuebles')
  }
}

const obtenerZonas = async (req, res) => {
  try {
    const filas = await prisma.inmueble.findMany({
      where:  { aprobado: true },
      select: { zona: true },
      distinct: ['zona'],
      orderBy: { zona: 'asc' },
    })

    let zonas = filas
      .map(f => f.zona?.trim())
      .filter(z => z && z.length > 0)

    if (zonas.length === 0) {
      zonas = [
        'Cala Cala', 'Centro', 'Queru Queru', 'Quillacollo',
        'Sacaba', 'Sarco', 'Temporal', 'Tupuraya',
      ]
    }

    return ok(res, zonas, 'Zonas obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener zonas')
  }
}

const obtenerInmueble = async (req, res) => {
  const { id } = req.params

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) },
      include: {
        imagenes: true,
        propietario: {
          select: { id: true, nombre: true, email: true, verificado: true }
        }
      }
    })

    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)

    return ok(res, inmueble, 'Inmueble obtenido')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener inmueble')
  }
}

const actualizarInmueble = async (req, res) => {
  const { id } = req.params
  const b = req.body || {}

  const bool = (v, fallback) =>
    v === undefined ? fallback : (v === 'true' || v === true)
  const num = (v, fallback, fn = parseFloat) =>
    v !== undefined && v !== '' ? fn(v) : fallback

  const camposNumericos = [
    { campo: 'precio', valor: b.precio },
    { campo: 'tamano', valor: b.tamano },
    { campo: 'piso', valor: b.piso, entero: true },
    { campo: 'numDormitorios', valor: b.numDormitorios, entero: true },
    { campo: 'numBanos', valor: b.numBanos, entero: true },
    { campo: 'habitantesMax', valor: b.habitantesMax, entero: true },
    { campo: 'habitacionesTotales', valor: b.habitacionesTotales, entero: true },
    { campo: 'habitacionesDisponibles', valor: b.habitacionesDisponibles, entero: true },
    { campo: 'edadMinima', valor: b.edadMinima, entero: true },
    { campo: 'edadMaxima', valor: b.edadMaxima, entero: true },
  ]
  for (const { campo, valor, entero } of camposNumericos) {
    if (valor === undefined || valor === '') continue
    const numValidado = entero ? parseInt(valor) : parseFloat(valor)
    if (isNaN(numValidado)) {
      return error(res, `El campo "${campo}" debe ser un número válido`, 400)
    }
  }

  try {
    const inmueble = await prisma.inmueble.findUnique({ where: { id: parseInt(id) } })
    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)
    if (inmueble.propietarioId !== req.usuario.id && req.usuario.rol !== 'ADMIN')
      return error(res, 'Sin permiso', 403)

    await prisma.inmueble.update({
      where: { id: parseInt(id) },
      data: {
        titulo:      b.titulo      || inmueble.titulo,
        tipoOferta:  ['ALQUILER', 'ANTICRETICO'].includes(b.tipoOferta)
          ? b.tipoOferta
          : inmueble.tipoOferta,
        descripcion: b.descripcion !== undefined ? b.descripcion : inmueble.descripcion,
        precio:      num(b.precio,    inmueble.precio),
        zona:        b.zona        || inmueble.zona,
        direccion:   b.direccion   || inmueble.direccion,
        latitud:     num(b.latitud,   inmueble.latitud),
        longitud:    num(b.longitud,  inmueble.longitud),
        aprobado:    false,
        disponible:  true,
        motivoRechazo: null,
        luzIncluida:      bool(b.luzIncluida,      inmueble.luzIncluida),
        aguaIncluida:     bool(b.aguaIncluida,      inmueble.aguaIncluida),
        internetIncluido: bool(b.internetIncluido,  inmueble.internetIncluido),
        gasIncluido:      bool(b.gasIncluido,       inmueble.gasIncluido),
        tamano:          num(b.tamano,          inmueble.tamano),
        piso:            num(b.piso,            inmueble.piso,            parseInt),
        amoblado:        bool(b.amoblado,        inmueble.amoblado),
        permiteMascotas: bool(b.permiteMascotas, inmueble.permiteMascotas),
        generoPermitido: b.generoPermitido || inmueble.generoPermitido,
        numDormitorios:  num(b.numDormitorios,  inmueble.numDormitorios,  parseInt),
        numBanos:        num(b.numBanos,        inmueble.numBanos,        parseInt),
        tieneParqueo:    bool(b.tieneParqueo,   inmueble.tieneParqueo),
        habitantesMax:   num(b.habitantesMax,   inmueble.habitantesMax,   parseInt),
        habitacionesTotales:     num(b.habitacionesTotales,     inmueble.habitacionesTotales,     parseInt),
        habitacionesDisponibles: num(b.habitacionesDisponibles, inmueble.habitacionesDisponibles, parseInt),
        banoCompartido:          bool(b.banoCompartido,         inmueble.banoCompartido),
        soloEstudiantes:         bool(b.soloEstudiantes,        inmueble.soloEstudiantes),
        generoConvivientes:      b.generoConvivientes || inmueble.generoConvivientes,
        edadMinima:              num(b.edadMinima,  inmueble.edadMinima,  parseInt),
        edadMaxima:              num(b.edadMaxima,  inmueble.edadMaxima,  parseInt),
        observaciones:           b.observaciones !== undefined ? b.observaciones : inmueble.observaciones,
        reglasComunes: b.reglasComunes !== undefined ? b.reglasComunes : inmueble.reglasComunes,
      }
    })

    if (req.files && req.files.length > 0) {
      await prisma.imagen.createMany({
        data: req.files.map(f => ({
          url: f.path, publicId: f.filename, inmuebleId: parseInt(id)
        }))
      })
    }

    const completo = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) },
      include: { imagenes: true }
    })
    return ok(res, completo, 'Inmueble actualizado. Pendiente de revisión.')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al actualizar inmueble')
  }
}

const eliminarInmueble = async (req, res) => {
  const { id } = req.params

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) },
      include: { imagenes: true }
    })

    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)

    if (inmueble.propietarioId !== req.usuario.id && req.usuario.rol !== 'ADMIN') {
      return error(res, 'No tenés permiso para eliminar este inmueble', 403)
    }

    if (inmueble.imagenes.length > 0) {
      await Promise.all(
        inmueble.imagenes.map(img => cloudinary.uploader.destroy(img.publicId))
      )
    }

    await prisma.inmueble.delete({ where: { id: parseInt(id) } })

    return ok(res, null, 'Inmueble eliminado correctamente')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar inmueble')
  }
}

const misInmuebles = async (req, res) => {
  try {
    const inmuebles = await prisma.inmueble.findMany({
      where: { propietarioId: req.usuario.id },
      include: { imagenes: true },
      orderBy: { creadoEn: 'desc' }
    })

    return ok(res, inmuebles, 'Mis inmuebles obtenidos')

  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener tus inmuebles')
  }
}

const obtenerTodasAdmin = async (req, res) => {
  const {
    estado, tipo, tipoOferta, buscar,
    precioMin, precioMax, desde, hasta,
    page = 1, limit = 10
  } = req.query

  const filtros = {}
  if (estado === 'pendiente') filtros.aprobado = false
  if (estado === 'aprobado') filtros.aprobado = true
  if (tipo) filtros.tipo = tipo
  if (tipoOferta) filtros.tipoOferta = tipoOferta

  if (buscar && buscar.trim()) {
    const q = buscar.trim()
    filtros.OR = [
      { titulo:    { contains: q, mode: 'insensitive' } },
      { zona:      { contains: q, mode: 'insensitive' } },
      { direccion: { contains: q, mode: 'insensitive' } },
      { propietario: { nombre: { contains: q, mode: 'insensitive' } } },
    ]
  }

  if (precioMin || precioMax) {
    filtros.precio = {}
    if (precioMin && !isNaN(parseFloat(precioMin))) filtros.precio.gte = parseFloat(precioMin)
    if (precioMax && !isNaN(parseFloat(precioMax))) filtros.precio.lte = parseFloat(precioMax)
  }

  if (desde || hasta) {
    filtros.creadoEn = {}
    if (desde) filtros.creadoEn.gte = new Date(desde)
    if (hasta) {
      const fin = new Date(hasta)
      fin.setHours(23, 59, 59, 999)
      filtros.creadoEn.lte = fin
    }
  }

  try {
    const total = await prisma.inmueble.count({ where: filtros })
    const inmuebles = await prisma.inmueble.findMany({
      where: filtros,
      include: {
        imagenes: true,
        propietario: {
          select: { id: true, nombre: true, email: true }
        }
      },
      orderBy: { creadoEn: 'desc' },
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit)
    })

    return ok(res, {
      inmuebles,
      total,
      pagina: parseInt(page),
      totalPaginas: Math.ceil(total / parseInt(limit))
    }, 'Inmuebles obtenidos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener inmuebles')
  }
}

const cambiarEstado = async (req, res) => {
  const { id } = req.params
  const { aprobado, disponible, motivoRechazo } = req.body

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) }
    })

    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)

      const eraAprobado = inmueble.aprobado
      const eraRechazado = !inmueble.aprobado && !inmueble.disponible
      const vaARechazar = aprobado === false && disponible === false
      const aprobadoResultante = aprobado === undefined ? inmueble.aprobado : aprobado
      const esDesactivacionAdmin = disponible === false && aprobadoResultante === true
  
      const actualizado = await prisma.inmueble.update({
        where: { id: parseInt(id) },
        data: {
          aprobado: aprobado !== undefined ? aprobado : inmueble.aprobado,
          disponible: disponible !== undefined ? disponible : inmueble.disponible,
          ...(vaARechazar && { motivoRechazo: motivoRechazo || null }),
          ...(aprobado === true && { motivoRechazo: null }),
          ...(esDesactivacionAdmin && { desactivadoPorAdmin: true }),
          ...(disponible === true && { desactivadoPorAdmin: false }),
        },
        include: { imagenes: true }
      })

    const ahoraAprobado = actualizado.aprobado && actualizado.disponible
    const ahoraRechazado = !actualizado.aprobado && !actualizado.disponible

    if (ahoraAprobado && !eraAprobado) {
      await crearNotificacion(
        actualizado.propietarioId,
        '¡Inmueble aprobado!',
        `Tu publicación "${actualizado.titulo}" fue aprobada y ya es visible para los estudiantes.`,
        'INMUEBLE_APROBADO',
      )
    } else if (ahoraRechazado && !eraRechazado) {
      const razon = motivoRechazo?.trim()
        ? motivoRechazo.trim()
        : 'No se especificaron motivos detallados.'
      await crearNotificacion(
        actualizado.propietarioId,
        'Inmueble rechazado',
        `Tu publicación "${actualizado.titulo}" fue rechazada. Motivo: ${razon}`,
        'INMUEBLE_RECHAZADO',
      )
    }

    return ok(res, actualizado, 'Estado actualizado correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al cambiar estado')
  }
}
const toggleDisponible = async (req, res) => {
  const { id } = req.params
  const { disponible } = req.body

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) }
    })
    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)
    if (inmueble.propietarioId !== req.usuario.id)
      return error(res, 'Sin permiso', 403)

    const nuevoDisponible = disponible ?? !inmueble.disponible
    if (nuevoDisponible === true && inmueble.desactivadoPorAdmin) {
      const actualizado = await prisma.inmueble.update({
        where: { id: parseInt(id) },
        data: {
          aprobado: false,
          disponible: true,
          desactivadoPorAdmin: false,
        }
      })
      return ok(
        res,
        actualizado,
        'Tu publicación fue reenviada para revisión del administrador'
      )
    }
    const actualizado = await prisma.inmueble.update({
      where: { id: parseInt(id) },
      data: {
        disponible: nuevoDisponible,
        desactivadoPorAdmin: false, // este cambio lo origina el propietario
      }
    })

    return ok(
      res,
      actualizado,
      actualizado.disponible ? 'Publicación reactivada' : 'Publicación pausada'
    )
  } catch (e) {
    console.error(e)
    return error(res, 'Error al actualizar disponibilidad')
  }
}
const eliminarImagen = async (req, res) => {
  const { imagenId } = req.params
  try {
    const imagen = await prisma.imagen.findUnique({
      where: { id: parseInt(imagenId) },
      include: { inmueble: true }
    })
    if (!imagen) return error(res, 'Imagen no encontrada', 404)
    if (imagen.inmueble.propietarioId !== req.usuario.id)
      return error(res, 'Sin permiso', 403)
    if (imagen.publicId) {
      try { await cloudinary.uploader.destroy(imagen.publicId) }
      catch (e) { console.error('Cloudinary error:', e) }
    }

    await prisma.imagen.delete({ where: { id: parseInt(imagenId) } })
    return ok(res, null, 'Imagen eliminada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar imagen')
  }
}
const apelarInmueble = async (req, res) => {
  const { id } = req.params
  const { texto } = req.body

  if (!texto?.trim())
    return error(res, 'El texto de apelación no puede estar vacío', 400)

  try {
    const inmueble = await prisma.inmueble.findUnique({
      where: { id: parseInt(id) }
    })
    if (!inmueble) return error(res, 'Inmueble no encontrado', 404)
    if (inmueble.propietarioId !== req.usuario.id)
      return error(res, 'Sin permiso', 403)
    let imagenesData = null
    if (req.files && req.files.length > 0) {
      const subirBuffer = (buffer) =>
        new Promise((resolve, reject) =>
          cloudinary.uploader.upload_stream(
            { folder: 'unihab/apelaciones', resource_type: 'image' },
            (err, result) => (err ? reject(err) : resolve(result))
          ).end(buffer)
        )
      const resultados = await Promise.all(
        req.files.map(f => subirBuffer(f.buffer))
      )
      imagenesData = resultados.map(r => ({
        url: r.secure_url,
        publicId: r.public_id
      }))
    }
    const reporteReciente = await prisma.reporte.findFirst({
      where: {
        inmuebleId: parseInt(id),
        estado: 'RESUELTO',
        sancionado: true,
      },
      orderBy: { creadoEn: 'desc' }
    })
    if (!reporteReciente)
      return error(res, 'No hay reporte sancionado para apelar', 404)
    await prisma.apelacion.create({
      data: {
        reporteId: reporteReciente.id,
        inmuebleId: parseInt(id),
        texto: texto.trim(),
        imagenes: imagenesData,
      }
    })
    await prisma.reporte.update({
      where: { id: reporteReciente.id },
      data: { estado: 'APELADO' }
    })
    await prisma.inmueble.update({
      where: { id: parseInt(id) },
      data: { enApelacion: true }
    })

    return ok(res, null, 'Apelación enviada correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar apelación', 500)
  }
}
const obtenerHistorialInmueble = async (req, res) => {
  const { id } = req.params
  try {
    const reportes = await prisma.reporte.findMany({
      where: { inmuebleId: parseInt(id) },
      include: {
        reportante: { select: { nombre: true, email: true } }
      },
      orderBy: { creadoEn: 'desc' }
    })
    return ok(res, reportes, 'Historial obtenido')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener historial', 500)
  }
}


module.exports = {
  crearInmueble, obtenerInmuebles, obtenerInmueble,obtenerZonas,
  actualizarInmueble, eliminarInmueble, misInmuebles,
  obtenerTodasAdmin, cambiarEstado, toggleDisponible,
  eliminarImagen, apelarInmueble, obtenerHistorialInmueble
}