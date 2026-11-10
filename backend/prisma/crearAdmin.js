const { PrismaClient } = require('@prisma/client')
const bcrypt = require('bcryptjs')

const prisma = new PrismaClient()

async function crearAdmin() {
  const existente = await prisma.usuario.findUnique({
    where: { email: 'admin@unihab.com' }
  })

  if (existente) {
    console.log('El administrador ya existe')
    await prisma.$disconnect()
    return
  }

  const hash = await bcrypt.hash('admin123', 10)

  const admin = await prisma.usuario.create({
    data: {
      nombre: 'Admin UniHab',
      email: 'admin@unihab.com',
      password: hash,
      rol: 'ADMIN',
      verificado: true
    }
  })

  console.log('Administrador creado:', admin.email)
  await prisma.$disconnect()
}

crearAdmin()