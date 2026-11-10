const router       = require('express').Router()
const { proteger } = require('../middlewares/authMiddleware')
const {
  obtenerListas, crearLista, renombrarLista, eliminarLista,
  obtenerInmueblesLista, guardarEnLista, quitarDeLista,
  obtenerEstado, registrarVisto, obtenerVistos, eliminarVisto,
  obtenerEstadoInmueble
} = require('../controllers/favoritosController')
router.get   ('/listas',               proteger, obtenerListas)
router.post  ('/listas',               proteger, crearLista)
router.patch ('/listas/:id/nombre',    proteger, renombrarLista)
router.delete('/listas/:id',           proteger, eliminarLista)
router.get   ('/listas/:id',           proteger, obtenerInmueblesLista)
router.post  ('/guardar',                        proteger, guardarEnLista)
router.delete('/quitar/:listaId/:inmuebleId',    proteger, quitarDeLista)
router.get('/estado/:inmuebleId', proteger, obtenerEstadoInmueble)
router.get   ('/estado',               proteger, obtenerEstado)
router.post  ('/visto',                proteger, registrarVisto)
router.get   ('/vistos',               proteger, obtenerVistos)
router.delete('/vistos/:inmuebleId',   proteger, eliminarVisto)

module.exports = router