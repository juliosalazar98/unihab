const PDFDocument = require('pdfkit')
const path = require('path')
const fs = require('fs')

const LOGO_PATH = path.join(__dirname, '../assets/logo.png')

const VERDE = '#10B981'
const VERDE_OSCURO = '#059669'
const GRIS = '#6B7280'
const GRIS_CLARO = '#F3F4F6'
const TEXTO = '#1F2937'

const fechaLarga = (d = new Date()) =>
  d.toLocaleDateString('es-BO', {
    day: '2-digit', month: 'long', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  })

const fechaCorta = (iso) => {
  if (!iso) return '—'
  return new Date(iso).toLocaleDateString('es-BO', {
    day: '2-digit', month: '2-digit', year: 'numeric'
  })
}

function crearDocumento(res, nombreArchivo, { horizontal = false } = {}) {
  const doc = new PDFDocument({
    size: 'A4',
    layout: horizontal ? 'landscape' : 'portrait',
    margin: 40,
    bufferPages: true,
  })
  res.setHeader('Content-Type', 'application/pdf')
  res.setHeader('Content-Disposition', `attachment; filename="${nombreArchivo}"`)
  doc.pipe(res)
  return doc
}

function encabezado(doc, titulo, subtitulo, filtros = []) {
  doc.rect(0, 0, doc.page.width, 135).fill(VERDE)

  if (fs.existsSync(LOGO_PATH)) {
    doc.image(LOGO_PATH, 40, 18, { fit: [300, 95] })
  } else {
    doc.fillColor('#FFFFFF').fontSize(26).font('Helvetica-Bold')
       .text('UniHab', 40, 45)
  }

  doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold')
     .text(`Generado: ${fechaLarga()}`, 40, 115, {
       width: doc.page.width - 80, align: 'right'
     })

  doc.fillColor(TEXTO).fontSize(16).font('Helvetica-Bold')
     .text(titulo, 40, 160)

  let y = 182
  if (subtitulo) {
    doc.fillColor(GRIS).fontSize(10).font('Helvetica').text(subtitulo, 40, y)
    y += 16
  }

  if (filtros.length > 0) {
    doc.fillColor(GRIS).fontSize(8).font('Helvetica-Oblique')
       .text(`Filtros aplicados: ${filtros.join('  ·  ')}`, 40, y, {
         width: doc.page.width - 80
       })
    y += 16
  }

  doc.moveTo(40, y + 4).lineTo(doc.page.width - 40, y + 4)
     .strokeColor('#E5E7EB').lineWidth(1).stroke()

  return y + 18
}

/** Recorta el texto con puntos suspensivos para que nunca desborde su columna. */
function recortar(doc, texto, anchoMax) {
  let t = String(texto ?? '—')
  if (doc.widthOfString(t) <= anchoMax) return t
  while (t.length > 1 && doc.widthOfString(t + '…') > anchoMax) {
    t = t.slice(0, -1)
  }
  return t.trimEnd() + '…'
}

function tabla(doc, { columnas, filas, y }) {
  const inicioX = 40
  const anchoTotal = doc.page.width - 80
  const alturaFila = 22
  const alturaCabecera = 24

  // Escala los anchos declarados para que ocupen exactamente el ancho útil.
  const suma = columnas.reduce((a, c) => a + c.ancho, 0)
  const escala = anchoTotal / suma
  const cols = columnas.map(c => ({ ...c, ancho: c.ancho * escala }))

  const dibujarCabecera = (posY) => {
    doc.rect(inicioX, posY, anchoTotal, alturaCabecera).fill(GRIS_CLARO)
    let x = inicioX
    doc.fillColor(TEXTO).fontSize(8).font('Helvetica-Bold')
    cols.forEach((col) => {
      const ancho = col.ancho - 12
      doc.text(recortar(doc, col.titulo.toUpperCase(), ancho), x + 6, posY + 8, {
        width: ancho,
        align: col.align || 'left',
        lineBreak: false,
      })
      x += col.ancho
    })
    return posY + alturaCabecera
  }

  let posY = dibujarCabecera(y)

  filas.forEach((fila, i) => {
    if (posY + alturaFila > doc.page.height - 60) {
      doc.addPage()
      posY = dibujarCabecera(50)
    }

    if (i % 2 === 1) {
      doc.rect(inicioX, posY, anchoTotal, alturaFila).fill('#FAFAFA')
    }

    let x = inicioX
    doc.fillColor(TEXTO).fontSize(8).font('Helvetica')
    cols.forEach((col) => {
      const ancho = col.ancho - 12
      const valor = fila[col.campo] ?? '—'
      doc.text(recortar(doc, valor, ancho), x + 6, posY + 7, {
        width: ancho,
        align: col.align || 'left',
        lineBreak: false,
      })
      x += col.ancho
    })

    doc.moveTo(inicioX, posY + alturaFila)
       .lineTo(inicioX + anchoTotal, posY + alturaFila)
       .strokeColor('#F3F4F6').lineWidth(0.5).stroke()

    posY += alturaFila
  })

  return posY
}

function resumen(doc, y, items) {
  if (y + 70 > doc.page.height - 60) {
    doc.addPage()
    y = 50
  }

  const inicioX = 40
  const ancho = doc.page.width - 80

  doc.rect(inicioX, y + 12, ancho, 50).fill('#ECFDF5')
  doc.fillColor(VERDE_OSCURO).fontSize(9).font('Helvetica-Bold')
     .text('RESUMEN', inicioX + 12, y + 22)

  let x = inicioX + 12
  const anchoItem = (ancho - 24) / items.length
  items.forEach((item) => {
    doc.fillColor(GRIS).fontSize(7).font('Helvetica')
       .text(item.label.toUpperCase(), x, y + 38, { width: anchoItem - 8, lineBreak: false })
    doc.fillColor(VERDE_OSCURO).fontSize(12).font('Helvetica-Bold')
       .text(String(item.valor), x, y + 47, { width: anchoItem - 8, lineBreak: false })
    x += anchoItem
  })

  return y + 70
}

function pieDePagina(doc) {
  const rango = doc.bufferedPageRange()
  for (let i = 0; i < rango.count; i++) {
    doc.switchToPage(rango.start + i)
    doc.fillColor(GRIS).fontSize(7).font('Helvetica')
       .text(
         `UniHab — Reporte administrativo   |   Página ${i + 1} de ${rango.count}`,
         40, doc.page.height - 40,
         { width: doc.page.width - 80, align: 'center' }
       )
  }
}

module.exports = {
  crearDocumento, encabezado, tabla, resumen, pieDePagina,
  recortar, fechaCorta, fechaLarga, VERDE, VERDE_OSCURO, GRIS, TEXTO
}