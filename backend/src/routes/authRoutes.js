const express = require('express')
const router  = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { upload }   = require('../config/multer')
const { uploadPerfil } = require('../config/multer')
const {
  registrar,
  login,
  perfil,
  actualizarPerfil,
  subirFotoPerfil, 
  eliminarFotoPerfil,
  loginConGoogle,
  olvidoPassword, resetPassword,   // ← faltaba esto
  cambiarPassword,
} = require('../controllers/authController')

router.post  ('/registro',    registrar)
router.post  ('/login',       login)
router.get   ('/perfil',      proteger, perfil)
router.patch ('/perfil',      proteger, actualizarPerfil)
router.patch('/foto-perfil', proteger, uploadPerfil.single('foto'), subirFotoPerfil)
router.delete('/foto-perfil', proteger, eliminarFotoPerfil)
router.post('/google', loginConGoogle)
router.post('/forgot-password', olvidoPassword)
router.post('/reset-password',  resetPassword)
router.patch('/cambiar-password', proteger, cambiarPassword)

module.exports = router