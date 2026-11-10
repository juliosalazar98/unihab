const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')

const obtenerPuntos = async (req, res) => {
  try {
    const puntos = await prisma.puntoInteres.findMany({
      orderBy: [{ tipo: 'asc' }, { nombre: 'asc' }]
    })
    return ok(res, puntos, 'Puntos de interés obtenidos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener puntos')
  }
}

module.exports = { obtenerPuntos }