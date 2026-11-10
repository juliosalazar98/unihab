const express = require('express')
const router  = express.Router()
const {
  crearReporte,
  obtenerReportes,
  descartarReporte,
  sancionarReporte,
  aceptarApelacion,
  rechazarApelacion,
} = require('../controllers/reporteController')
const { proteger, soloAdmin } = require('../middlewares/authMiddleware')

router.post('/',                        proteger,            crearReporte)
router.get('/',                         proteger, soloAdmin, obtenerReportes)
router.patch('/:id/descartar',          proteger, soloAdmin, descartarReporte)
router.patch('/:id/sancionar',          proteger, soloAdmin, sancionarReporte)
router.patch('/:id/aceptar-apelacion',  proteger, soloAdmin, aceptarApelacion)
router.patch('/:id/rechazar-apelacion', proteger, soloAdmin, rechazarApelacion)

module.exports = router