import api from './api'
import toast from 'react-hot-toast'

export async function descargarPdf(ruta, params = {}, nombreBase = 'reporte') {
  const toastId = toast.loading('Generando PDF...')
  try {
    const limpios = Object.fromEntries(
      Object.entries(params).filter(([, v]) => v !== '' && v != null)
    )
    const res = await api.get(ruta, {
      params: limpios,
      responseType: 'blob',
    })

    const url = URL.createObjectURL(new Blob([res.data], { type: 'application/pdf' }))
    const fecha = new Date().toISOString().slice(0, 10)
    const a = document.createElement('a')
    a.href = url
    a.download = `unihab-${nombreBase}-${fecha}.pdf`
    document.body.appendChild(a)
    a.click()
    a.remove()
    URL.revokeObjectURL(url)

    toast.success('Reporte descargado', { id: toastId })
  } catch {
    toast.error('Error al generar el reporte', { id: toastId })
  }
}