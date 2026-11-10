const express  = require('express')
const multer   = require('multer')
const router   = express.Router()
const {
  solicitarVerificacion,
  obtenerVerificacionesPendientes,
  obtenerVerificacionDetalle,
  aprobarVerificacion,
  rechazarVerificacion,
} = require('../controllers/verificacionController')
const { proteger, soloPropietario, soloAdmin } = require('../middlewares/authMiddleware')

const upload = multer({ storage: multer.memoryStorage() })

router.post(
  '/solicitar',
  proteger,
  soloPropietario,
  upload.fields([
    { name: 'fotoAnverso', maxCount: 1 },
    { name: 'fotoReverso', maxCount: 1 },
    { name: 'fotoRostro', maxCount: 1 },
  ]),
  solicitarVerificacion
)

router.get('/pendientes',     proteger, soloAdmin, obtenerVerificacionesPendientes)
router.get('/:id',            proteger, soloAdmin, obtenerVerificacionDetalle)
router.patch('/:id/aprobar',  proteger, soloAdmin, aprobarVerificacion)
router.patch('/:id/rechazar', proteger, soloAdmin, rechazarVerificacion)

module.exports = router