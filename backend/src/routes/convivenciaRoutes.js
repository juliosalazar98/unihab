const router       = require('express').Router()
const { proteger } = require('../middlewares/authMiddleware')
const {
  obtenerMiPerfil,
  guardarPerfil,
  toggleVisibilidad,
  obtenerMatches,
  solicitarMatch,
  responderMatch,
  conectarDirecto,
  obtenerSolicitudesRecibidas,
  obtenerMisConexiones,
  finalizarConexion,
  cancelarMatch,
} = require('../controllers/convivenciaController')
router.get  ('/mi-perfil',         proteger, obtenerMiPerfil)
router.post ('/perfil',            proteger, guardarPerfil)
router.patch('/perfil/visibilidad', proteger, toggleVisibilidad)
router.get('/match', proteger, obtenerMatches)
router.get   ('/match/solicitudes-recibidas',  proteger, obtenerSolicitudesRecibidas)
router.get   ('/match/mis-conexiones',         proteger, obtenerMisConexiones)
router.post  ('/match/solicitar/:receptorId',  proteger, solicitarMatch)
router.patch ('/match/:matchId/responder',     proteger, responderMatch)
router.delete('/match/:matchId/cancelar',      proteger, cancelarMatch)
router.delete('/match/:matchId/conexion',      proteger, finalizarConexion)
router.post('/match/directo', proteger, conectarDirecto)
router.get('/match/conexiones', proteger, obtenerMisConexiones)

module.exports = router