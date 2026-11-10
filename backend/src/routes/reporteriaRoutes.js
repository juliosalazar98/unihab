const router = require('express').Router()
const { proteger, soloAdmin } = require('../middlewares/authMiddleware')
const {
  pdfPublicaciones, pdfUsuarios, pdfModeracion, pdfGeneral
} = require('../controllers/reporteriaController')

router.get('/publicaciones', proteger, soloAdmin, pdfPublicaciones)
router.get('/usuarios',      proteger, soloAdmin, pdfUsuarios)
router.get('/moderacion',    proteger, soloAdmin, pdfModeracion)
router.get('/general',       proteger, soloAdmin, pdfGeneral)

module.exports = router