const prisma = require('../config/prisma')
const { ok, error } = require('../utils/respuesta')

const _selectInmueble = {
  id: true, titulo: true, precio: true, tipo: true, zona: true,
  imagenes: { take: 1, orderBy: { id: 'asc' } },
}
const obtenerListas = async (req, res) => {
  try {
    const listas = await prisma.listaFavoritos.findMany({
      where: { usuarioId: req.usuario.id },
      include: {
        inmuebles: {
          orderBy: { creadoEn: 'desc' },
          take: 1,
          include: {
            inmueble: { select: { imagenes: { take: 1, orderBy: { id: 'asc' } } } }
          }
        },
        _count: { select: { inmuebles: true } }
      },
      orderBy: { creadoEn: 'desc' }
    })

    const resultado = listas.map(l => ({
      id:        l.id,
      nombre:    l.nombre,
      total:     l._count.inmuebles,
      thumbnail: l.inmuebles[0]?.inmueble.imagenes[0]?.url ?? null,
      creadoEn:  l.creadoEn,
    }))
    return ok(res, resultado, `${resultado.length} listas`)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener listas', 500)
  }
}
const crearLista = async (req, res) => {
  try {
    const { nombre } = req.body
    if (!nombre?.trim()) return error(res, 'El nombre es requerido', 400)

    const lista = await prisma.listaFavoritos.create({
      data: { nombre: nombre.trim(), usuarioId: req.usuario.id }
    })
    return ok(res, lista, 'Lista creada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al crear lista', 500)
  }
}
const renombrarLista = async (req, res) => {
  try {
    const id     = parseInt(req.params.id)
    const { nombre } = req.body
    if (!nombre?.trim()) return error(res, 'El nombre es requerido', 400)

    const lista = await prisma.listaFavoritos.findUnique({ where: { id } })
    if (!lista)                           return error(res, 'Lista no encontrada', 404)
    if (lista.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    const actualizada = await prisma.listaFavoritos.update({
      where: { id },
      data:  { nombre: nombre.trim() }
    })
    return ok(res, actualizada, 'Lista renombrada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al renombrar', 500)
  }
}
const eliminarLista = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const lista = await prisma.listaFavoritos.findUnique({ where: { id } })
    if (!lista)                           return error(res, 'Lista no encontrada', 404)
    if (lista.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    await prisma.listaFavoritos.delete({ where: { id } })
    return ok(res, null, 'Lista eliminada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar lista', 500)
  }
}
const obtenerInmueblesLista = async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const lista = await prisma.listaFavoritos.findUnique({
      where: { id },
      include: {
        inmuebles: {
          orderBy: { creadoEn: 'desc' },
          include: { inmueble: { select: _selectInmueble } }
        }
      }
    })
    if (!lista)                           return error(res, 'Lista no encontrada', 404)
    if (lista.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    const resultado = {
      id:     lista.id,
      nombre: lista.nombre,
      inmuebles: lista.inmuebles.map(i => ({
        id:        i.inmueble.id,
        titulo:    i.inmueble.titulo,
        precio:    i.inmueble.precio,
        tipo:      i.inmueble.tipo,
        zona:      i.inmueble.zona,
        thumbnail: i.inmueble.imagenes[0]?.url ?? null,
        guardadoEn: i.creadoEn,
      }))
    }
    return ok(res, resultado, 'Inmuebles de la lista')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener inmuebles', 500)
  }
}
const guardarEnLista = async (req, res) => {
  try {
    const { inmuebleId, listaId } = req.body
    if (!inmuebleId || !listaId) return error(res, 'inmuebleId y listaId son requeridos', 400)

    const lista = await prisma.listaFavoritos.findUnique({
      where: { id: parseInt(listaId) }
    })
    if (!lista)                           return error(res, 'Lista no encontrada', 404)
    if (lista.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    const favorito = await prisma.inmuebleFavorito.upsert({
      where: {
        listaId_inmuebleId: {
          listaId:    parseInt(listaId),
          inmuebleId: parseInt(inmuebleId)
        }
      },
      create: { listaId: parseInt(listaId), inmuebleId: parseInt(inmuebleId) },
      update: {}
    })

    return ok(res, { ...favorito, nombreLista: lista.nombre }, 'Guardado en lista')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al guardar', 500)
  }
}
const quitarDeLista = async (req, res) => {
  try {
    const listaId    = parseInt(req.params.listaId)
    const inmuebleId = parseInt(req.params.inmuebleId)

    const lista = await prisma.listaFavoritos.findUnique({ where: { id: listaId } })
    if (!lista)                           return error(res, 'Lista no encontrada', 404)
    if (lista.usuarioId !== req.usuario.id) return error(res, 'No autorizado', 403)

    await prisma.inmuebleFavorito.delete({
      where: { listaId_inmuebleId: { listaId, inmuebleId } }
    })
    return ok(res, { nombreLista: lista.nombre }, 'Eliminado de lista')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al quitar', 500)
  }
}
const obtenerEstado = async (req, res) => {
  try {
    const favoritos = await prisma.inmuebleFavorito.findMany({
      where: { lista: { usuarioId: req.usuario.id } },
      select: {
        inmuebleId: true,
        listaId:    true,
        lista:      { select: { nombre: true } }
      }
    })
    const resultado = favoritos.map(f => ({
      inmuebleId:  f.inmuebleId,
      listaId:     f.listaId,
      nombreLista: f.lista.nombre,
    }))
    return ok(res, resultado, 'Estado de favoritos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener estado', 500)
  }
}
const registrarVisto = async (req, res) => {
  try {
    const { inmuebleId } = req.body
    if (!inmuebleId) return error(res, 'inmuebleId es requerido', 400)

    await prisma.inmuebleVisto.upsert({
      where: {
        usuarioId_inmuebleId: {
          usuarioId:  req.usuario.id,
          inmuebleId: parseInt(inmuebleId)
        }
      },
      create: { usuarioId: req.usuario.id, inmuebleId: parseInt(inmuebleId) },
      update: { vistoEn: new Date() }
    })
    return ok(res, null, 'Visto registrado')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al registrar visto', 500)
  }
}
const obtenerVistos = async (req, res) => {
  try {
    const vistos = await prisma.inmuebleVisto.findMany({
      where:   { usuarioId: req.usuario.id },
      include: { inmueble: { select: _selectInmueble } },
      orderBy: { vistoEn: 'desc' },
      take: 50
    })

    const grupos = {}
    for (const v of vistos) {
      const fecha = v.vistoEn.toISOString().split('T')[0]
      if (!grupos[fecha]) grupos[fecha] = []
      grupos[fecha].push({
        id:         v.id,
        inmuebleId: v.inmueble.id,
        titulo:     v.inmueble.titulo,
        precio:     v.inmueble.precio,
        tipo:       v.inmueble.tipo,
        zona:       v.inmueble.zona,
        thumbnail:  v.inmueble.imagenes[0]?.url ?? null,
        vistoEn:    v.vistoEn,
      })
    }

    const resultado = Object.entries(grupos)
      .map(([fecha, items]) => ({ fecha, items }))
    return ok(res, resultado, 'Inmuebles vistos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener vistos', 500)
  }
}
const eliminarVisto = async (req, res) => {
  try {
    const inmuebleId = parseInt(req.params.inmuebleId)
    await prisma.inmuebleVisto.delete({
      where: {
        usuarioId_inmuebleId: { usuarioId: req.usuario.id, inmuebleId }
      }
    })
    return ok(res, null, 'Eliminado de vistos')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar', 500)
  }
}

const obtenerEstadoInmueble = async (req, res) => {
  try {
    const inmuebleId = parseInt(req.params.inmuebleId)
    const favorito = await prisma.inmuebleFavorito.findFirst({
      where: {
        inmuebleId,
        lista: { usuarioId: req.usuario.id },
      },
      include: { lista: { select: { id: true, nombre: true } } },
    })
    return ok(res, {
      isFavorito:  !!favorito,
      listaId:     favorito?.lista.id     ?? null,
      nombreLista: favorito?.lista.nombre ?? null,
    }, 'Estado del inmueble')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener estado', 500)
  }
}


module.exports = {
  obtenerListas, crearLista, renombrarLista, eliminarLista,
  obtenerInmueblesLista, guardarEnLista, quitarDeLista,
  obtenerEstado, registrarVisto, obtenerVistos, eliminarVisto, obtenerEstadoInmueble
}