/**
 * seed-pruebas.js — Carga de datos de prueba para el Capítulo III (UniHab)
 *
 * Genera:
 *   - 1 propietario de prueba
 *   - 100 inmuebles aprobados y disponibles, distribuidos en 13 zonas de Cochabamba
 *   - 3 imágenes por inmueble (reutiliza URLs ya alojadas en Cloudinary, no sube nada)
 *   - 30 arrendatarios con su perfil de convivencia activo
 *
 * Todo lo que crea queda marcado para poder borrarlo después:
 *   - inmuebles: el título empieza con "[PRUEBA]"
 *   - usuarios:  el email termina en "@prueba.unihab"
 *
 * Uso:   node seed-pruebas.js
 * Borrar: node limpiar-pruebas.js
 */

const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

// bcrypt o bcryptjs, según lo que tenga instalado el proyecto
let bcrypt
try { bcrypt = require('bcrypt') } catch (e) { bcrypt = require('bcryptjs') }

// ---------------------------------------------------------------------------
// Configuración
// ---------------------------------------------------------------------------

const TOTAL_INMUEBLES = 100
const TOTAL_ARRENDATARIOS = 30
const PASSWORD_PLANO = 'Prueba123'

// URLs reales ya almacenadas en Cloudinary. No se sube nada nuevo.
// Los publicId son ficticios a propósito: así, si alguna vez se elimina un
// inmueble de prueba desde la API, Cloudinary no borrará las imágenes reales.
const IMAGENES_BASE = [
  'https://res.cloudinary.com/dyzmdizad/image/upload/v1790885731/unihab/inmuebles/ix4rr4ydxen4t0xijnv2.jpg',
  'https://res.cloudinary.com/dyzmdizad/image/upload/v1790885730/unihab/inmuebles/mab4jwm02qtwyx3ovp9e.jpg',
  'https://res.cloudinary.com/dyzmdizad/image/upload/v1790885730/unihab/inmuebles/uzlrjk3sxa81h0sfsmox.jpg',
]

// Zonas de Cochabamba con coordenadas aproximadas de su centro.
// La dispersión real es lo que permite que el filtro por radio discrimine.
const ZONAS = [
  { nombre: 'Cala Cala',      lat: -17.3650, lng: -66.1620 },
  { nombre: 'Tupuraya',       lat: -17.3760, lng: -66.1480 },
  { nombre: 'Queru Queru',    lat: -17.3720, lng: -66.1400 },
  { nombre: 'Centro',         lat: -17.3935, lng: -66.1570 },
  { nombre: 'Muyurina',       lat: -17.3790, lng: -66.1310 },
  { nombre: 'Sarco',          lat: -17.3880, lng: -66.1830 },
  { nombre: 'Hipódromo',      lat: -17.3830, lng: -66.1680 },
  { nombre: 'Temporal',       lat: -17.3600, lng: -66.1300 },
  { nombre: 'Jaihuayco',      lat: -17.4080, lng: -66.1480 },
  { nombre: 'Alalay',         lat: -17.4150, lng: -66.1400 },
  { nombre: 'Villa Pagador',  lat: -17.4300, lng: -66.0900 },
  { nombre: 'Quillacollo',    lat: -17.3920, lng: -66.2790 },
  { nombre: 'Sacaba',         lat: -17.4030, lng: -66.0380 },
]

const TIPOS = ['CUARTO', 'DEPARTAMENTO', 'COMPARTIDO']
const OFERTAS = ['ALQUILER', 'ANTICRETICO']

const NOMBRES = ['Ana','Luis','María','Carlos','Lucía','Jorge','Valeria','Diego','Camila','Andrés',
                 'Paola','Rodrigo','Daniela','Fernando','Gabriela','Mauricio','Rocío','Iván',
                 'Natalia','Sergio','Patricia','Álvaro','Verónica','Ramiro','Silvia','Marcelo',
                 'Carolina','Juan','Alejandra','Pablo']
const APELLIDOS = ['Rojas','Vargas','Quispe','Mamani','Terceros','Claros','Arce','Salazar','Vega',
                   'Montaño','Céspedes','Flores','Zambrana','Peredo','Antezana']

const CARRERAS = ['Ingeniería de Sistemas','Medicina','Derecho','Arquitectura','Administración',
                  'Comunicación','Psicología','Contaduría','Odontología','Ingeniería Civil']

// Valores válidos de los enums del schema
const OPCION   = ['SI', 'NO_TOLERO', 'INDIFERENTE']
const CRONO    = ['DIURNO', 'NOCTURNO']
const AMBIENTE = ['SILENCIO', 'ACTIVO']
const VISITAS  = ['FRECUENTE', 'MODERADO', 'RESTRINGIDO']
const ORDEN    = ['RIGUROSO', 'RELAJADO']
const GENEROS  = ['MASCULINO', 'FEMENINO', 'OTRO']

// ---------------------------------------------------------------------------
// Utilidades
// ---------------------------------------------------------------------------

const al = (arr) => arr[Math.floor(Math.random() * arr.length)]
const entre = (min, max) => Math.floor(Math.random() * (max - min + 1)) + min
const quiza = () => Math.random() < 0.5
// desplazamiento de hasta ~1.2 km alrededor del centro de la zona
const jitter = () => (Math.random() - 0.5) * 0.022

async function main () {
  console.log('Iniciando carga de datos de prueba...\n')
  const hash = await bcrypt.hash(PASSWORD_PLANO, 10)

  // -------------------------------------------------------------------------
  // 1. Propietario de prueba
  // -------------------------------------------------------------------------
  const propietario = await prisma.usuario.upsert({
    where:  { email: 'propietario.carga@prueba.unihab' },
    update: {},
    create: {
      nombre: '[PRUEBA] Propietario de carga',
      email: 'propietario.carga@prueba.unihab',
      password: hash,
      rol: 'PROPIETARIO',
      verificado: true,
      telefono: '70000000',
    },
  })
  console.log(`Propietario de prueba listo (id ${propietario.id})`)

  // -------------------------------------------------------------------------
  // 2. Inmuebles + imágenes
  // -------------------------------------------------------------------------
  let creados = 0
  for (let i = 1; i <= TOTAL_INMUEBLES; i++) {
    const zona = al(ZONAS)
    const tipo = al(TIPOS)
    const oferta = al(OFERTAS)

    // Rangos de precio coherentes con el mercado local
    const precio = oferta === 'ANTICRETICO'
      ? entre(8, 45) * 1000
      : (tipo === 'CUARTO' ? entre(400, 900)
        : tipo === 'COMPARTIDO' ? entre(500, 1100)
        : entre(1200, 3000))

    const esCompartido = tipo === 'COMPARTIDO'
    const habTotales = esCompartido ? entre(2, 5) : null

    const inmueble = await prisma.inmueble.create({
      data: {
        titulo: `[PRUEBA] ${tipo.charAt(0) + tipo.slice(1).toLowerCase()} en ${zona.nombre} N° ${i}`,
        descripcion: `Registro generado para las pruebas de rendimiento del Capítulo III. ` +
                     `Ubicado en ${zona.nombre}, a pocos minutos de avenidas principales.`,
        precio,
        tipo,
        zona: zona.nombre,
        direccion: `Calle ${entre(1, 40)} N° ${entre(100, 2500)}, ${zona.nombre}`,
        latitud:  zona.lat + jitter(),
        longitud: zona.lng + jitter(),
        disponible: true,
        aprobado: true,                 // debe estar aprobado para salir en la búsqueda
        tipoOferta: oferta,
        propietarioId: propietario.id,
        luzIncluida: quiza(),
        aguaIncluida: quiza(),
        internetIncluido: quiza(),
        gasIncluido: quiza(),
        tamano: entre(18, 120),
        piso: entre(1, 6),
        amoblado: quiza(),
        permiteMascotas: quiza(),
        generoPermitido: al(['CUALQUIERA', 'MASCULINO', 'FEMENINO']),
        numDormitorios: entre(1, 4),
        numBanos: entre(1, 3),
        tieneParqueo: quiza(),
        habitantesMax: entre(1, 6),
        habitacionesTotales: habTotales,
        habitacionesDisponibles: habTotales ? entre(1, habTotales) : null,
        banoCompartido: esCompartido ? quiza() : false,
        soloEstudiantes: quiza(),
        generoConvivientes: al(['MIXTO', 'MASCULINO', 'FEMENINO']),
        edadMinima: 18,
        edadMaxima: entre(28, 45),
        reglasComunes: '[]',
      },
    })

    await prisma.imagen.createMany({
      data: IMAGENES_BASE.map((url, n) => ({
        url,
        publicId: `unihab/pruebas/cap3-${inmueble.id}-${n + 1}`, // ficticio a propósito
        inmuebleId: inmueble.id,
      })),
    })

    creados++
    if (creados % 20 === 0) console.log(`  ${creados} inmuebles creados...`)
  }
  console.log(`${creados} inmuebles con 3 imágenes cada uno\n`)

  // -------------------------------------------------------------------------
  // 3. Arrendatarios con perfil de convivencia
  // -------------------------------------------------------------------------
  let perfiles = 0
  for (let i = 1; i <= TOTAL_ARRENDATARIOS; i++) {
    const nombre = `${al(NOMBRES)} ${al(APELLIDOS)}`
    const usuario = await prisma.usuario.create({
      data: {
        nombre: `[PRUEBA] ${nombre}`,
        email: `arrendatario${i}@prueba.unihab`,
        password: hash,
        rol: 'ARRENDATARIO',
        verificado: true,
        genero: al(GENEROS),
        carrera: al(CARRERAS),
        ciudadOrigen: al(['Cochabamba', 'Oruro', 'Potosí', 'Sucre', 'La Paz', 'Santa Cruz', 'Tarija']),
        telefono: `7${entre(1000000, 9999999)}`,
      },
    })

    await prisma.perfilConvivencia.create({
      data: {
        usuarioId: usuario.id,
        aceptaMascotas: al(OPCION),
        fumaTabaco: al(OPCION),
        cronotipo: al(CRONO),
        ambienteEstudio: al(AMBIENTE),
        politicaVisitas: al(VISITAS),
        nivelOrden: al(ORDEN),
        descripcionSobreMi: `Estudiante de ${al(CARRERAS)}. Perfil generado para las pruebas del Capítulo III.`,
        activo: true,
      },
    })
    perfiles++
  }
  console.log(`${perfiles} arrendatarios con perfil de convivencia activo\n`)

  // -------------------------------------------------------------------------
  // 4. Resumen
  // -------------------------------------------------------------------------
  const totalInmuebles = await prisma.inmueble.count({ where: { aprobado: true, disponible: true } })
  const totalUsuarios  = await prisma.usuario.count()
  const totalPerfiles  = await prisma.perfilConvivencia.count({ where: { activo: true } })

  console.log('─────────────────────────────────────────')
  console.log('Volumen total en la base de datos')
  console.log(`  Inmuebles visibles en búsqueda : ${totalInmuebles}`)
  console.log(`  Usuarios registrados           : ${totalUsuarios}`)
  console.log(`  Perfiles de convivencia activos: ${totalPerfiles}`)
  console.log('─────────────────────────────────────────')
  console.log(`\nContraseña de todas las cuentas de prueba: ${PASSWORD_PLANO}`)
  console.log('Anotá estas cifras: son el volumen que se reporta en el Capítulo III.')
}

main()
  .catch((e) => { console.error('Error en la carga:', e); process.exit(1) })
  .finally(async () => { await prisma.$disconnect() })
