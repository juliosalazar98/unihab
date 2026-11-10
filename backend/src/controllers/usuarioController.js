const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')

const obtenerUsuarios = async (req, res) => {
  const {
    rol, activo, buscar, verificacion,
    desde, hasta, page = 1, limit = 10
  } = req.query

  const filtros = {}
  if (rol) filtros.rol = rol
  if (activo !== undefined && activo !== '') filtros.activo = activo === 'true'

  if (buscar && buscar.trim()) {
    filtros.OR = [
      { nombre: { contains: buscar.trim(), mode: 'insensitive' } },
      { email:  { contains: buscar.trim(), mode: 'insensitive' } },
    ]
  }

  if (verificacion) {
    if (verificacion === 'NO_VERIFICADO') {
      filtros.OR = [
        ...(filtros.OR || []),
      ]
      filtros.estadoVerificacion = { in: ['NO_VERIFICADO', 'RECHAZADO'] }
    } else {
      filtros.estadoVerificacion = verificacion
    }
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
    const total = await prisma.usuario.count({ where: filtros })
    const usuarios = await prisma.usuario.findMany({
      where: filtros,
      select: {
        id: true,
        nombre: true,
        email: true,
        rol: true,
        activo: true,
        verificado: true,
        estadoVerificacion: true,
        creadoEn: true,
        _count: {
          select: { inmuebles: true }
        }
      },
      orderBy: { creadoEn: 'desc' },
      skip: (parseInt(page) - 1) * parseInt(limit),
      take: parseInt(limit)
    })

    return ok(res, {
      usuarios,
      total,
      pagina: parseInt(page),
      totalPaginas: Math.ceil(total / parseInt(limit))
    }, 'Usuarios obtenidos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener usuarios')
  }
}

const cambiarEstadoUsuario = async (req, res) => {
  const { id } = req.params
  const { activo } = req.body

  try {
    const usuario = await prisma.usuario.findUnique({
      where: { id: parseInt(id) }
    })

    if (!usuario) return error(res, 'Usuario no encontrado', 404)

    if (usuario.rol === 'ADMIN') {
      return error(res, 'No se puede modificar un administrador', 403)
    }

    const actualizado = await prisma.usuario.update({
      where: { id: parseInt(id) },
      data: { activo },
      select: {
        id: true,
        nombre: true,
        email: true,
        rol: true,
        activo: true,
      }
    })

    return ok(res, actualizado, `Usuario ${activo ? 'activado' : 'suspendido'} correctamente`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al cambiar estado del usuario')
  }
}

const eliminarUsuario = async (req, res) => {
  const { id } = req.params

  try {
    const usuario = await prisma.usuario.findUnique({
      where: { id: parseInt(id) }
    })

    if (!usuario) return error(res, 'Usuario no encontrado', 404)
    if (usuario.rol === 'ADMIN') {
      return error(res, 'No se puede eliminar un administrador', 403)
    }

    await prisma.usuario.delete({ where: { id: parseInt(id) } })
    return ok(res, null, 'Usuario eliminado correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar usuario')
  }
}

module.exports = { obtenerUsuarios, cambiarEstadoUsuario, eliminarUsuario }