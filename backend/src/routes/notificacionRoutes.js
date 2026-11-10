const router       = require('express').Router()
const { proteger } = require('../middlewares/authMiddleware')
const {
  obtenerNotificaciones,
  marcarTodasLeidas,
  marcarLeida,
  eliminarNotificacion,
  coSolicitud,
  responderCoSolicitud,
  misCoSolicitudes,
} = require('../controllers/notificacionController')
router.get  ('/',                      proteger, obtenerNotificaciones)
router.patch('/leer-todas',            proteger, marcarTodasLeidas)
router.post ('/co-solicitud',          proteger, coSolicitud)
router.get  ('/co-solicitud/pendientes', proteger, misCoSolicitudes)
router.patch('/co-solicitud/:id/responder', proteger, responderCoSolicitud)
router.patch('/:id/leer',              proteger, marcarLeida)
router.delete('/:id',                  proteger, eliminarNotificacion)

module.exports = router