const express = require('express')
const router  = express.Router()
const { obtenerEstadisticasPropietario, obtenerEstadisticasAdmin } = require('../controllers/estadisticasController')
const { proteger, soloPropietario, soloAdmin } = require('../middlewares/authMiddleware')

router.get('/propietario', proteger, soloPropietario, obtenerEstadisticasPropietario)
router.get('/admin', proteger, soloAdmin, obtenerEstadisticasAdmin)

module.exports = router