const prisma    = require('../config/prisma')
const cloudinary = require('cloudinary').v2
const { ok, error } = require('../utils/respuesta')
const { crearNotificacion } = require('../utils/notificaciones')
const solicitarVerificacion = async (req, res) => {
  try {
    const { nombre, ci, extension } = req.body
    const files = req.files

    if (!nombre?.trim() || !ci?.trim() || !extension?.trim()) {
      return error(res, 'Nombre, CI y extensión son requeridos', 400)
    }
    if (!files?.fotoAnverso?.[0] || !files?.fotoReverso?.[0] || !files?.fotoRostro?.[0]) {
      return error(res, 'Las 3 fotos (anverso, reverso y rostro) son requeridas', 400)
    }

    const subirBuffer = (buffer) =>
      new Promise((resolve, reject) =>
        cloudinary.uploader.upload_stream(
          { folder: 'unihab/verificaciones', resource_type: 'image' },
          (err, result) => (err ? reject(err) : resolve(result))
        ).end(buffer)
      )

    const [anverso, reverso, rostro] = await Promise.all([
      subirBuffer(files.fotoAnverso[0].buffer),
      subirBuffer(files.fotoReverso[0].buffer),
      subirBuffer(files.fotoRostro[0].buffer),
    ])

    await prisma.usuario.update({
      where: { id: req.usuario.id },
      data: {
        estadoVerificacion: 'PENDIENTE',
        nombreLegal:        nombre.trim(),
        ciNumero:           ci.trim(),
        ciExtension:        extension.trim(),
        fotoAnversoUrl:     anverso.secure_url,
        fotoReversoUrl:     reverso.secure_url,
        fotoRostroUrl:      rostro.secure_url,
      },
    })

    return ok(res, null, 'Solicitud de verificación enviada correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar verificación', 500)
  }
}
const obtenerVerificacionesPendientes = async (req, res) => {
  try {
    const propietarios = await prisma.usuario.findMany({
      where: { rol: 'PROPIETARIO', estadoVerificacion: 'PENDIENTE' },
      select: {
        id: true, nombre: true, nombreLegal: true, email: true, telefono: true,
        actualizadoEn: true,
      },
      orderBy: { actualizadoEn: 'desc' },
    })
    return ok(res, propietarios, 'Verificaciones pendientes obtenidas')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener verificaciones pendientes', 500)
  }
}
const obtenerVerificacionDetalle = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const propietario = await prisma.usuario.findUnique({
      where: { id },
      select: {
        id: true, nombre: true, nombreLegal: true, email: true, telefono: true,
        ciNumero: true, ciExtension: true,
        fotoAnversoUrl: true, fotoReversoUrl: true, fotoRostroUrl: true,
        estadoVerificacion: true,
      },
    })
    if (!propietario) return error(res, 'Propietario no encontrado', 404)
    return ok(res, propietario, 'Detalle obtenido')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener detalle', 500)
  }
}
const aprobarVerificacion = async (req, res) => {
  try {
    const id = parseInt(req.params.id)

    const actual = await prisma.usuario.findUnique({
      where: { id },
      select: { nombreLegal: true },
    })
    if (!actual) return error(res, 'Propietario no encontrado', 404)

    const propietario = await prisma.usuario.update({
      where: { id },
      data: {
        estadoVerificacion: 'APROBADO',
        verificado: true,
        ...(actual.nombreLegal && { nombre: actual.nombreLegal }),
      },
      select: { id: true, nombre: true },
    })

    await crearNotificacion(
      id,
      '¡Cuenta verificada!',
      'Tu identidad fue verificada correctamente. Ya contás con la insignia de Propietario Verificado.',
      'VERIFICACION_APROBADA',
    )

    return ok(res, propietario, 'Verificación aprobada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al aprobar verificación', 500)
  }
}
const rechazarVerificacion = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const propietario = await prisma.usuario.update({
      where: { id },
      data: { estadoVerificacion: 'RECHAZADO' },
      select: { id: true, nombre: true },
    })

    await crearNotificacion(
      id,
      'Verificación rechazada',
      'Tu solicitud de verificación fue rechazada. Revisá tus documentos e intentá nuevamente.',
      'VERIFICACION_RECHAZADA',
    )

    return ok(res, propietario, 'Verificación rechazada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al rechazar verificación', 500)
  }
}

module.exports = {
  solicitarVerificacion,
  obtenerVerificacionesPendientes,
  obtenerVerificacionDetalle,
  aprobarVerificacion,
  rechazarVerificacion,
}