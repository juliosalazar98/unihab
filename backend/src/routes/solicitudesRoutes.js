const express = require('express')
const router  = express.Router()
const {
  crearSolicitud,
  obtenerSolicitudesPropietario,
  marcarAtendida,
  obtenerSolicitudesAtendidas,
  obtenerPostulacionesArrendatario,
  
} = require('../controllers/solicitudesController')
const { proteger, soloPropietario } = require('../middlewares/authMiddleware')

router.post('/',                 proteger,                  crearSolicitud)
router.get ('/mis-solicitudes',  proteger, soloPropietario, obtenerSolicitudesPropietario)
router.patch('/:id/atendida',    proteger,                  marcarAtendida)
router.get('/atendidas', proteger, soloPropietario, obtenerSolicitudesAtendidas)
router.get('/mis-postulaciones', proteger, obtenerPostulacionesArrendatario)

module.exports = router