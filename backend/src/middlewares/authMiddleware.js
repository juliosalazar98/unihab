const { verificarToken } = require('../config/jwt')
const { error } = require('../utils/respuesta')

const proteger = (req, res, next) => {
  const authHeader = req.headers['authorization']

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return error(res, 'Token requerido', 401)
  }

  const token = authHeader.split(' ')[1]

  try {
    const payload = verificarToken(token)
    req.usuario = payload
    next()
  } catch (e) {
    return error(res, 'Token inválido o expirado', 401)
  }
}

const soloAdmin = (req, res, next) => {
  if (req.usuario.rol !== 'ADMIN') {
    return error(res, 'Acceso denegado', 403)
  }
  next()
}

const soloPropietario = (req, res, next) => {
  if (req.usuario.rol !== 'PROPIETARIO' && req.usuario.rol !== 'ADMIN') {
    return error(res, 'Solo propietarios pueden realizar esta acción', 403)
  }
  next()
}

module.exports = { proteger, soloAdmin, soloPropietario }