const bcrypt = require('bcryptjs')
const prisma  = require('../config/prisma')
const { crearToken } = require('../config/jwt')
const { ok, error }  = require('../utils/respuesta')
const { cloudinary } = require('../config/multer')
const { OAuth2Client } = require('google-auth-library')
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID)
const nodemailer = require('nodemailer')

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  }
})
const _selectPerfil = {
  id: true, nombre: true, email: true, rol: true,
  telefono: true, fotoPerfil: true,
  carrera: true, genero: true, ciudadOrigen: true,
  puntoInteresId: true, estadoVerificacion: true, verificado: true,
  puntoInteres: {
    select: { id: true, nombre: true, tipo: true, latitud: true, longitud: true },
  },
}
const registrar = async (req, res) => {
  const { nombre, email, password, rol, telefono } = req.body

  if (!nombre || !email || !password) {
    return error(res, 'Nombre, email y contraseña son obligatorios', 400)
  }

  const rolesValidos = ['ARRENDATARIO', 'PROPIETARIO']
  if (rol && !rolesValidos.includes(rol)) {
    return error(res, 'Rol inválido', 400)
  }

  try {
    const existente = await prisma.usuario.findUnique({ where: { email } })
    if (existente) return error(res, 'El email ya está registrado', 409)

    const hash    = await bcrypt.hash(password, 10)
    const usuario = await prisma.usuario.create({
      data: {
        nombre,
        email,
        password: hash,
        rol: rol || 'ARRENDATARIO',
        ...(telefono && { telefono: `591${telefono.replace(/\D/g, '').slice(-8)}` }),
      },
    })

    const token = crearToken({
      id: usuario.id, nombre: usuario.nombre,
      email: usuario.email, rol: usuario.rol,
    })

    return ok(res, { token, usuario: {
      id: usuario.id, nombre: usuario.nombre,
      email: usuario.email, rol: usuario.rol,
    }}, 'Registro exitoso', 201)
  } catch (e) {
    console.error(e)
    return error(res, 'Error al registrar usuario')
  }
}

const login = async (req, res) => {
  const { email, password } = req.body
  if (!email || !password) {
    return error(res, 'Email y contraseña son obligatorios', 400)
  }

  try {
    const usuario = await prisma.usuario.findUnique({ where: { email } })
    if (!usuario || !usuario.activo) return error(res, 'Credenciales incorrectas', 401)

    const passwordValida = await bcrypt.compare(password, usuario.password)
    if (!passwordValida) return error(res, 'Credenciales incorrectas', 401)

    const token = crearToken({
      id: usuario.id, nombre: usuario.nombre,
      email: usuario.email, rol: usuario.rol,
    })

    return ok(res, { token, usuario: {
      id: usuario.id, nombre: usuario.nombre,
      email: usuario.email, rol: usuario.rol,
    }}, 'Login exitoso')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al iniciar sesión')
  }
}
const perfil = async (req, res) => {
  try {
    const usuario = await prisma.usuario.findUnique({
      where:  { id: req.usuario.id },
      select: _selectPerfil,
    })
    return ok(res, usuario, 'Perfil obtenido')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al obtener perfil')
  }
}
const actualizarPerfil = async (req, res) => {
  const { telefono, puntoInteresId, carrera, genero, ciudadOrigen } = req.body
  const generosValidos = ['MASCULINO', 'FEMENINO', 'OTRO']
  if (genero !== undefined && genero !== null && !generosValidos.includes(genero)) {
    return error(res, 'Género inválido', 400)
  }

  try {
    const actualizado = await prisma.usuario.update({
      where: { id: req.usuario.id },
      data: {
        ...(telefono      !== undefined && { telefono }),
        ...(puntoInteresId !== undefined && {
          puntoInteresId: puntoInteresId ? parseInt(puntoInteresId) : null,
        }),
        ...(carrera      !== undefined && { carrera:      carrera || null }),
        ...(genero       !== undefined && { genero:       genero  || null }),
        ...(ciudadOrigen !== undefined && { ciudadOrigen: ciudadOrigen || null }),
      },
      select: _selectPerfil,
    })
    return ok(res, actualizado, 'Perfil actualizado')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al actualizar perfil')
  }
}
const subirFotoPerfil = async (req, res) => {
  try {
    if (!req.file) return error(res, 'No se envió imagen', 400)

    const usuario = await prisma.usuario.update({
      where:  { id: req.usuario.id },
      data:   { fotoPerfil: req.file.path },
      select: _selectPerfil,
    })
    return ok(res, usuario, 'Foto de perfil actualizada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al subir foto', 500)
  }
}
const eliminarFotoPerfil = async (req, res) => {
  try {
    const actual = await prisma.usuario.findUnique({
      where:  { id: req.usuario.id },
      select: { fotoPerfil: true },
    })

    if (!actual?.fotoPerfil) {
      return error(res, 'No tenés una foto de perfil para quitar', 400)
    }

    const match = actual.fotoPerfil.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-zA-Z]+(?:\?.*)?$/)
    if (match) {
      try {
        await cloudinary.uploader.destroy(match[1])
      } catch (e) {
        console.error('Error al borrar foto de Cloudinary:', e)
      }
    }

    const usuario = await prisma.usuario.update({
      where:  { id: req.usuario.id },
      data:   { fotoPerfil: null },
      select: _selectPerfil,
    })
    return ok(res, usuario, 'Foto de perfil eliminada')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al eliminar foto', 500)
  }
}
const loginConGoogle = async (req, res) => {
  const { idToken } = req.body
  if (!idToken) return error(res, 'Token de Google requerido', 400)

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_CLIENT_ID,
    })
    const payload = ticket.getPayload()
    const { email, name, picture } = payload
    let usuario = await prisma.usuario.findUnique({ where: { email } })

    if (!usuario) {
      usuario = await prisma.usuario.create({
        data: {
          nombre: name,
          email,
          password: '',         // sin contraseña para usuarios de Google
          fotoPerfil: picture,
          rol: 'ARRENDATARIO',  // rol por defecto
        }
      })
    }

    const token = crearToken({
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      rol: usuario.rol,
    })

    return ok(res, {
      token,
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        email: usuario.email,
        rol: usuario.rol,
      }
    }, 'Login con Google exitoso')
  } catch (e) {
    console.error(e)
    return error(res, 'Token de Google inválido', 401)
  }
}
const olvidoPassword = async (req, res) => {
  const { email } = req.body
  if (!email?.trim()) return error(res, 'El correo es requerido', 400)

  try {
    const usuario = await prisma.usuario.findUnique({
      where: { email: email.trim().toLowerCase() }
    })
    if (!usuario) return ok(res, null, 'Si el correo existe, recibirás el código.')
    const codigo = Math.floor(100000 + Math.random() * 900000).toString()
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000) // 15 minutos
    await prisma.codigoRecuperacion.updateMany({
      where: { email: email.trim().toLowerCase(), usado: false },
      data: { usado: true }
    })
       // El código se almacena cifrado; al usuario se le envía el valor en claro.
       const codigoHash = await bcrypt.hash(codigo, 10)
       await prisma.codigoRecuperacion.create({
         data: {
           email: email.trim().toLowerCase(),
           codigo: codigoHash,
           expiresAt,
         }
       })
    await transporter.sendMail({
      from: `"UniHab" <${process.env.MAIL_USER}>`,
      to: email.trim(),
      subject: '🔑 Código de recuperación UniHab',
      html: `
        <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
          <div style="text-align: center; margin-bottom: 24px;">
            <div style="display: inline-block; background: #10B981; border-radius: 50%; width: 60px; height: 60px; line-height: 60px; font-size: 28px; color: white; font-weight: bold;">U</div>
            <h2 style="color: #1F2937; margin-top: 12px;">UniHab</h2>
          </div>
          <h3 style="color: #1F2937;">Recuperación de contraseña</h3>
          <p style="color: #6B7280;">Tu código de verificación es:</p>
          <div style="text-align: center; margin: 24px 0;">
            <span style="font-size: 40px; font-weight: bold; letter-spacing: 12px; color: #10B981;">${codigo}</span>
          </div>
          <p style="color: #6B7280; font-size: 13px;">Este código expira en <strong>15 minutos</strong>. Si no solicitaste este código, ignorá este correo.</p>
          <hr style="border: none; border-top: 1px solid #E5E7EB; margin: 24px 0;" />
          <p style="color: #9CA3AF; font-size: 12px; text-align: center;">UniHab — Plataforma de alojamiento estudiantil</p>
        </div>
      `
    })
    return ok(res, null, 'Código enviado correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al enviar el código', 500)
  }
}
const resetPassword = async (req, res) => {
  const { email, codigo, nuevaPassword } = req.body

  if (!email || !codigo || !nuevaPassword)
    return error(res, 'Todos los campos son requeridos', 400)
  if (nuevaPassword.length < 6)
    return error(res, 'La contraseña debe tener al menos 6 caracteres', 400)

  try {
    const registro = await prisma.codigoRecuperacion.findFirst({
      where: {
        email: email.trim().toLowerCase(),
        usado: false,
        expiresAt: { gt: new Date() }
      },
      orderBy: { creadoEn: 'desc' }
    })

    if (!registro)
      return error(res, 'Código inválido o expirado', 400)

    const codigoValido = await bcrypt.compare(codigo.trim(), registro.codigo)
    if (!codigoValido)
      return error(res, 'Código inválido o expirado', 400)

    const hash = await bcrypt.hash(nuevaPassword, 10)
    await prisma.usuario.update({
      where: { email: email.trim().toLowerCase() },
      data: { password: hash }
    })

    await prisma.codigoRecuperacion.update({
      where: { id: registro.id },
      data: { usado: true }
    })

    return ok(res, null, 'Contraseña actualizada correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al actualizar la contraseña', 500)
  }
}
const cambiarPassword = async (req, res) => {
  const { passwordActual, passwordNueva } = req.body

  if (!passwordActual || !passwordNueva)
    return error(res, 'Todos los campos son requeridos', 400)
  if (passwordNueva.length < 6)
    return error(res, 'La nueva contraseña debe tener al menos 6 caracteres', 400)

  try {
    const usuario = await prisma.usuario.findUnique({ where: { id: req.usuario.id } })
    if (!usuario) return error(res, 'Usuario no encontrado', 404)

    if (!usuario.password) {
      return error(res, 'Esta cuenta inició sesión con Google y no tiene contraseña propia', 400)
    }

    const passwordValida = await bcrypt.compare(passwordActual, usuario.password)
    if (!passwordValida) return error(res, 'La contraseña actual es incorrecta', 400)

    const hash = await bcrypt.hash(passwordNueva, 10)
    await prisma.usuario.update({
      where: { id: req.usuario.id },
      data: { password: hash },
    })

    return ok(res, null, 'Contraseña actualizada correctamente')
  } catch (e) {
    console.error(e)
    return error(res, 'Error al cambiar la contraseña', 500)
  }
}


module.exports = {
  registrar, login, perfil, actualizarPerfil,
  subirFotoPerfil, eliminarFotoPerfil, loginConGoogle,
  olvidoPassword, resetPassword, cambiarPassword
}