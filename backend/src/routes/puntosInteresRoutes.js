const express  = require('express')
const router   = express.Router()
const { obtenerPuntos } = require('../controllers/puntosInteresController')

router.get('/', obtenerPuntos) // público, no requiere auth

module.exports = router