const express = require('express')
const router = express.Router()
const {
  crearInmueble,
  obtenerInmuebles,
  obtenerInmueble,
  obtenerZonas,
  actualizarInmueble,
  eliminarInmueble,
  misInmuebles,
  obtenerTodasAdmin,
  cambiarEstado,
  toggleDisponible,
  eliminarImagen,
  apelarInmueble,
  obtenerHistorialInmueble,
} = require('../controllers/inmuebleController')
const { proteger, soloPropietario, soloAdmin } = require('../middlewares/authMiddleware')
const { upload } = require('../config/multer')
const multer = require('multer')
const uploadMemory = multer({ storage: multer.memoryStorage() })
router.get('/',                 obtenerInmuebles)
router.get('/zonas',            obtenerZonas)
router.get('/mis-inmuebles',    proteger, soloPropietario, misInmuebles)
router.get('/admin/todas',      proteger, soloAdmin,       obtenerTodasAdmin)
router.get('/:id',              obtenerInmueble)
router.post('/',                proteger, soloPropietario, upload.array('imagenes', 5), crearInmueble)
router.put('/:id',              proteger, soloPropietario, upload.array('imagenes', 5), actualizarInmueble)
router.delete('/:id',           proteger,                  eliminarInmueble)
router.patch('/admin/:id/estado',   proteger, soloAdmin,       cambiarEstado)
router.patch('/:id/disponible',     proteger,                  toggleDisponible)
router.delete('/imagenes/:imagenId',proteger,                  eliminarImagen)
router.post('/:id/apelar',    proteger, uploadMemory.array('pruebas', 3), apelarInmueble)
router.get('/:id/historial',  proteger, soloAdmin,  obtenerHistorialInmueble)



module.exports = router