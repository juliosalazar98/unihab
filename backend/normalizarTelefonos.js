/**
 * Script Prisma — Normalizar teléfonos bolivianos
 * Ejecutar: node normalizarTelefonos.js
 */

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function normalizar() {
  console.log('🔍 Leyendo usuarios con teléfono...')

  const usuarios = await prisma.usuario.findMany({
    where:  { telefono: { not: null } },
    select: { id: true, nombre: true, telefono: true },
  })

  console.log(`📋 Total encontrados: ${usuarios.length}\n`)

  let actualizados = 0
  let ignorados    = 0

  for (const u of usuarios) {
    const original = u.telefono ?? ''
    if (!original.trim()) { ignorados++; continue }
    const limpio = original.replace(/[^\d]/g, '')
    if (limpio.startsWith('591') && limpio.length === 11) {
      console.log(`✅ Ya normalizado: ${u.nombre} → ${limpio}`)
      ignorados++
      continue
    }
    if (limpio.length === 8) {
      const normalizado = `591${limpio}`
      await prisma.usuario.update({
        where: { id: u.id },
        data:  { telefono: normalizado },
      })
      console.log(`✏️  ${u.nombre}: ${original} → ${normalizado}`)
      actualizados++
      continue
    }
    console.log(`⚠️  Ignorado (formato inesperado): ${u.nombre} → "${original}"`)
    ignorados++
  }

  console.log('\n────────────────────────────')
  console.log(`✅ Actualizados: ${actualizados}`)
  console.log(`⏭️  Ignorados:   ${ignorados}`)
  console.log('────────────────────────────')
  console.log('🎉 Normalización completada.')
}

normalizar()
  .catch(e => { console.error('❌ Error:', e); process.exit(1) })
  .finally(() => prisma.$disconnect())