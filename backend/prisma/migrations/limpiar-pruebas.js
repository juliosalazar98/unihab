/**
 * limpiar-pruebas.js — Elimina únicamente los datos creados por seed-pruebas.js
 *
 * Borra:
 *   - los inmuebles cuyo título empieza con "[PRUEBA]" (y, en cascada, sus
 *     imágenes, favoritos, vistos, reportes y solicitudes)
 *   - los usuarios cuyo email termina en "@prueba.unihab" (y, en cascada, sus
 *     perfiles de convivencia, matches y notificaciones)
 *
 * No toca ningún otro registro. Ejecutar solo cuando las mediciones ya estén
 * anotadas y las capturas de evidencia tomadas.
 *
 * Uso: node limpiar-pruebas.js
 */

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function main () {
  // Conteo previo, para poder reportar qué se eliminó
  const inmueblesPrueba = await prisma.inmueble.count({
    where: { titulo: { startsWith: '[PRUEBA]' } },
  })
  const usuariosPrueba = await prisma.usuario.count({
    where: { email: { endsWith: '@prueba.unihab' } },
  })

  if (inmueblesPrueba === 0 && usuariosPrueba === 0) {
    console.log('No se encontraron datos de prueba. Nada que borrar.')
    return
  }

  console.log(`Se van a eliminar ${inmueblesPrueba} inmuebles y ${usuariosPrueba} usuarios de prueba.\n`)

  // Primero los inmuebles: el propietario no puede borrarse mientras tenga
  // publicaciones, porque esa relación no está en cascada.
  const inm = await prisma.inmueble.deleteMany({
    where: { titulo: { startsWith: '[PRUEBA]' } },
  })
  console.log(`  Inmuebles eliminados: ${inm.count}`)

  const usr = await prisma.usuario.deleteMany({
    where: { email: { endsWith: '@prueba.unihab' } },
  })
  console.log(`  Usuarios eliminados : ${usr.count}`)

  const restantes = await prisma.inmueble.count()
  const usuariosRestantes = await prisma.usuario.count()
  console.log(`\nQuedan ${restantes} inmuebles y ${usuariosRestantes} usuarios reales en la base.`)
}

main()
  .catch((e) => { console.error('Error en la limpieza:', e); process.exit(1) })
  .finally(async () => { await prisma.$disconnect() })
