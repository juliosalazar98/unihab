const express = require('express')
const router = express.Router()
const {
  obtenerUsuarios,
  cambiarEstadoUsuario,
  eliminarUsuario
} = require('../controllers/usuarioController')
const { proteger, soloAdmin } = require('../middlewares/authMiddleware')

router.get('/', proteger, soloAdmin, obtenerUsuarios)
router.patch('/:id/estado', proteger, soloAdmin, cambiarEstadoUsuario)
router.delete('/:id', proteger, soloAdmin, eliminarUsuario)

module.exports = router