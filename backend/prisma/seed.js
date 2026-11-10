const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function main() {
  console.log('Insertando puntos de interés...')

  const puntos = [
    { nombre: 'Universidad Simón I. Patiño (USIP)',        tipo: 'UNIVERSIDAD', latitud: -17.37483987985954,  longitud: -66.13506271976615 },
    { nombre: 'Universidad UCATEC',                         tipo: 'UNIVERSIDAD', latitud: -17.37075427134506,  longitud: -66.13686007031758 },
    { nombre: 'UPAL Campus Norte',                          tipo: 'UNIVERSIDAD', latitud: -17.373513664838327, longitud: -66.13652344482365 },
    { nombre: 'Universidad Católica (UCB)',                 tipo: 'UNIVERSIDAD', latitud: -17.37155882671714,  longitud: -66.14393783670035 },
    { nombre: 'UPAL Sede Central',                         tipo: 'UNIVERSIDAD', latitud: -17.369367507665576, longitud: -66.16025203325857 },
    { nombre: 'UNIVALLE Campus América',                    tipo: 'UNIVERSIDAD', latitud: -17.372410355879897, longitud: -66.16124906238387 },
    { nombre: 'UNICEN Torre de Salud',                     tipo: 'UNIVERSIDAD', latitud: -17.37835879573156,  longitud: -66.16291552365108 },
    { nombre: 'Universidad Privada Domingo Savio (UPDS)',  tipo: 'UNIVERSIDAD', latitud: -17.37631169390961,  longitud: -66.18401847943878 },
    { nombre: 'Universidad Privada UNO',                   tipo: 'UNIVERSIDAD', latitud: -17.387062622152943, longitud: -66.1608663586611  },
    { nombre: 'UNITEPC Campus Colonial',                   tipo: 'UNIVERSIDAD', latitud: -17.392670897819162, longitud: -66.15605598474    },
    { nombre: 'UNIVALLE Campus Ayacucho',                  tipo: 'UNIVERSIDAD', latitud: -17.394257990510106, longitud: -66.15867503354683 },
    { nombre: 'UNICEN Sede Cochabamba',                    tipo: 'UNIVERSIDAD', latitud: -17.394795420984618, longitud: -66.15992405898436 },
    { nombre: 'Universidad Mayor de San Simón (UMSS)',     tipo: 'UNIVERSIDAD', latitud: -17.394811534410998, longitud: -66.1479636479488  },
    { nombre: 'UNITEPC Campus Juan Pablo II',              tipo: 'UNIVERSIDAD', latitud: -17.39299000448942,  longitud: -66.20069042237101 },
    { nombre: 'Universidad Privada Boliviana (UPB)',       tipo: 'UNIVERSIDAD', latitud: -17.398752826296544, longitud: -66.21851170442174 },
    { nombre: 'UNIVALLE Campus Tiquipaya',                 tipo: 'UNIVERSIDAD', latitud: -17.33285667131376,  longitud: -66.22629262994272 },
    { nombre: 'Universidad Salesiana',                     tipo: 'UNIVERSIDAD', latitud: -17.36252729354462,  longitud: -66.23782665960194 },
    { nombre: 'Universidad Adventista de Bolivia',         tipo: 'UNIVERSIDAD', latitud: -17.387414417043342, longitud: -66.31746949000055 },
    { nombre: 'Universidad de Aquino Bolivia (UDABOL)',    tipo: 'UNIVERSIDAD', latitud: -17.39066910472414,  longitud: -66.06846994860176 },
    { nombre: 'Universidad Franz Tamayo (Unifranz)',       tipo: 'UNIVERSIDAD', latitud: -17.37505127778752,  longitud: -66.15868601727787 },
    { nombre: 'Instituto Tecnológico Nuestra Señora del Pilar', tipo: 'INSTITUTO', latitud: -17.35310633466433,  longitud: -66.16692004997076 },
    { nombre: 'Instituto Tecnológico Mundial OMIE',              tipo: 'INSTITUTO', latitud: -17.38996848504581,  longitud: -66.15949361967645 },
    { nombre: 'Instituto Técnico ICEPAL',                        tipo: 'INSTITUTO', latitud: -17.39234378988998,  longitud: -66.16133897946163 },
    { nombre: 'Instituto Federico Álvarez Plata',                tipo: 'INSTITUTO', latitud: -17.395218621710537, longitud: -66.15799343862462 },
    { nombre: 'Instituto Técnico Nacional Andrés Bello',         tipo: 'INSTITUTO', latitud: -17.396406243898305, longitud: -66.16043961322359 },
    { nombre: 'INFOCAL Campus Tupuraya',                         tipo: 'INSTITUTO', latitud: -17.371679335203506, longitud: -66.1422933771524  },
    { nombre: 'INFOCAL Campus Arocagua',                         tipo: 'INSTITUTO', latitud: -17.379569637062747, longitud: -66.11726835098277 },
  ]
  for (const punto of puntos) {
    await prisma.puntoInteres.upsert({
      where: { nombre: punto.nombre },  // requiere @@unique en schema (ver nota)
      update: { latitud: punto.latitud, longitud: punto.longitud },
      create: punto,
    })
  }

  console.log(`✓ ${puntos.length} puntos insertados`)
}

main()
  .catch(e => { console.error(e); process.exit(1) })
  .finally(() => prisma.$disconnect())