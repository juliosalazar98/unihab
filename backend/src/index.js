require('dotenv').config()
const path = require('path')
const express = require('express')
const cors = require('cors')

const authRoutes = require('./routes/authRoutes')
const inmuebleRoutes = require('./routes/inmuebleRoutes')
const usuarioRoutes = require('./routes/usuarioRoutes')
const solicitudesRoutes = require('./routes/solicitudesRoutes')
const puntosRoutes = require('./routes/puntosInteresRoutes')
const convivenciaRoutes = require('./routes/convivenciaRoutes')
const notificacionRoutes = require('./routes/notificacionRoutes')
const favoritosRoutes = require('./routes/favoritosRoutes')
const estadisticasRoutes = require('./routes/estadisticasRoutes')
const verificacionRoutes = require('./routes/verificacionRoutes')
const reporteRoutes = require('./routes/reporteRoutes')
const reporteriaRoutes = require('./routes/reporteriaRoutes')



const app = express()
const PORT = process.env.PORT || 3000

app.use(cors())
app.use(express.json())
// Log de peticiones: método, ruta, código de respuesta y duración.
app.use('/uploads', express.static(path.join(__dirname, '../uploads')))

app.get('/', (req, res) => {
  res.json({ mensaje: 'API UniHab funcionando' })
})

app.use('/api/auth', authRoutes)
app.use('/api/inmuebles', inmuebleRoutes)
app.use('/api/usuarios', usuarioRoutes)
app.use('/api/solicitudes', solicitudesRoutes)
app.use('/api/puntos-interes', puntosRoutes)
app.use('/api/convivencia', convivenciaRoutes)
app.use('/api/notificaciones', notificacionRoutes)
app.use('/api/favoritos', favoritosRoutes)
app.use('/api/estadisticas', estadisticasRoutes)
app.use('/api/verificacion', verificacionRoutes)
app.use('/api/reportes', reporteRoutes)
app.use('/api/reporteria', reporteriaRoutes)


app.listen(PORT, () => {
  console.log(`Servidor UniHab corriendo en http://localhost:${PORT}`)
})