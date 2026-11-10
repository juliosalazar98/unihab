import { useState, useEffect } from 'react'
import Layout from '../components/Layout'
import api from '../services/api'
import toast from 'react-hot-toast'
import { Eye, CheckCircle, ShieldOff, X, Flag, ThumbsUp, ThumbsDown, FileDown } from 'lucide-react'
import { descargarPdf } from '../services/descargarPdf'
import { ModalDetalleInmueble } from './Publicaciones'

function BadgeEstado({ estado }) {
  if (estado === 'RESUELTO') return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
      🟢 Resuelto
    </span>
  )
  if (estado === 'APELADO') return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 animate-pulse">
      🔵 Apelado
    </span>
  )
  return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
      🟡 Pendiente
    </span>
  )
}

function ModalDetalleReporte({ reporte, onClose, onDescartar, onSancionar, onAceptarApelacion, onRechazarApelacion, onVerInmueble }) {
  const [procesando, setProcesando] = useState(false)

  const accion = async (fn) => {
    setProcesando(true)
    try {
      await fn(reporte.id)
      onClose()
    } finally {
      setProcesando(false)
    }
  }

  const fecha = new Date(reporte.creadoEn).toLocaleDateString('es-BO', {
    day: '2-digit', month: 'long', year: 'numeric',
    hour: '2-digit', minute: '2-digit'
  })

  const esApelado = reporte.estado === 'APELADO'

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-lg shadow-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-800">Detalle del reporte</h3>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 transition">
            <X size={20} className="text-gray-500" />
          </button>
        </div>

        <div className="p-6 space-y-4">
          {/* Info básica */}
          {/* Info básica */}
          <div>
            <p className="text-xs text-gray-500">Inmueble reportado</p>
            <div className="flex items-center gap-2 mt-0.5">
              <p className="text-sm font-semibold text-gray-800">{reporte.inmueble?.titulo}</p>
              <button
                onClick={() => onVerInmueble(reporte.inmueble?.id)}
                className="flex items-center gap-1 px-2 py-0.5 rounded-lg text-xs font-medium text-blue-600 bg-blue-50 hover:bg-blue-100 transition"
              >
                <Eye size={11} /> Ver inmueble
              </button>
            </div>
            <p className="text-xs text-gray-400">Propietario: {reporte.inmueble?.propietario?.nombre}</p>
          </div>

          <div>
            <p className="text-xs text-gray-500">Reportado por</p>
            <p className="text-sm font-medium text-gray-800">{reporte.reportante?.nombre ?? 'Usuario eliminado'}</p>
            <p className="text-xs text-gray-400">{reporte.reportante?.email ?? '—'}</p>
          </div>

          <div>
            <p className="text-xs text-gray-500">Motivo original</p>
            <span className="inline-block mt-1 px-2 py-1 rounded-full text-xs font-medium bg-red-50 text-red-700">
              {reporte.motivo}
            </span>
          </div>

          {reporte.comentario && (
            <div>
              <p className="text-xs text-gray-500 mb-1">Comentario del estudiante</p>
              <p className="text-sm text-gray-700 bg-gray-50 rounded-xl p-3">{reporte.comentario}</p>
            </div>
          )}

          <div>
            <p className="text-xs text-gray-500">Fecha del reporte</p>
            <p className="text-sm text-gray-700">{fecha}</p>
          </div>

          {/* Sección de apelación */}
          {esApelado && reporte.apelacion && (
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 space-y-3">
              <p className="text-xs font-bold text-blue-800 flex items-center gap-1.5">
                🔵 Descargo del propietario
              </p>
              <p className="text-sm text-blue-700 italic">
                "{reporte.apelacion.texto}"
              </p>
              {reporte.apelacion.imagenes?.length > 0 && (
                <div>
                  <p className="text-xs text-blue-700 font-semibold mb-2">
                    Capturas de prueba ({reporte.apelacion.imagenes.length})
                  </p>
                  <div className="flex gap-2 flex-wrap">
                    {reporte.apelacion.imagenes.map((img, idx) => (
                      <a key={idx} href={img.url} target="_blank" rel="noreferrer">
                        <img
                          src={img.url}
                          alt={`Prueba ${idx + 1}`}
                          className="w-24 h-24 object-cover rounded-xl border border-blue-200 hover:opacity-90 transition"
                        />
                      </a>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Acciones */}
          {reporte.estado === 'PENDIENTE' && (
            <div className="flex gap-3 pt-2 border-t border-gray-100">
              <button
                onClick={() => accion(onDescartar)}
                disabled={procesando}
                className="flex-1 py-2.5 rounded-xl border border-gray-200 text-gray-600 font-semibold text-sm hover:bg-gray-50 transition disabled:opacity-50 flex items-center justify-center gap-2 mt-4"
              >
                <CheckCircle size={16} /> Descartar
              </button>
              <button
                onClick={() => accion(onSancionar)}
                disabled={procesando}
                className="flex-1 py-2.5 rounded-xl bg-red-600 text-white font-semibold text-sm hover:bg-red-700 transition disabled:opacity-50 flex items-center justify-center gap-2 mt-4"
              >
                <ShieldOff size={16} /> Sancionar
              </button>
            </div>
          )}

          {esApelado && (
            <div className="pt-2 border-t border-gray-100 space-y-2">
              <p className="text-xs text-gray-500 text-center mb-3">Decisión sobre la apelación</p>
              <button
                onClick={() => accion(onRechazarApelacion)}
                disabled={procesando}
                className="w-full py-2.5 rounded-xl border border-red-200 text-red-600 font-semibold text-sm hover:bg-red-50 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <ThumbsDown size={16} /> Rechazar Apelación (mantener bloqueo)
              </button>
              <button
                onClick={() => accion(onAceptarApelacion)}
                disabled={procesando}
                className="w-full py-2.5 rounded-xl bg-emerald-600 text-white font-semibold text-sm hover:bg-emerald-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <ThumbsUp size={16} /> Aceptar Apelación (reactivar inmueble)
              </button>
            </div>
          )}

          {reporte.estado === 'RESUELTO' && (
            <div className="pt-2 border-t border-gray-100">
              <p className="text-xs text-gray-400 text-center">
                {reporte.sancionado
                  ? 'Este reporte resultó en la desactivación del inmueble.'
                  : 'Este reporte fue descartado.'}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default function Reportes() {
    const [reportes, setReportes] = useState([])
    const [cargando, setCargando] = useState(true)
    const [detalle, setDetalle] = useState(null)
    const [recargar, setRecargar] = useState(0)
    const [tab, setTab] = useState('PENDIENTE')
    const [verInmuebleId, setVerInmuebleId] = useState(null)

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      setCargando(true)
      try {
        const res = await api.get('/reportes')
        if (!cancelado) setReportes(res.data.datos)
      } catch {
        if (!cancelado) toast.error('Error al cargar reportes')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [recargar])

  const descartar = async (id) => {
    try {
      await api.patch(`/reportes/${id}/descartar`)
      toast.success('Reporte descartado')
      setRecargar(r => r + 1)
    } catch { toast.error('Error al descartar') }
  }

  const sancionar = async (id) => {
    try {
      await api.patch(`/reportes/${id}/sancionar`)
      toast.success('Inmueble desactivado y propietario notificado')
      setRecargar(r => r + 1)
    } catch { toast.error('Error al sancionar') }
  }

  const aceptarApelacion = async (id) => {
    try {
      await api.patch(`/reportes/${id}/aceptar-apelacion`)
      toast.success('Apelación aceptada. Inmueble reactivado ✓')
      setRecargar(r => r + 1)
    } catch { toast.error('Error al aceptar apelación') }
  }

  const rechazarApelacion = async (id) => {
    try {
      await api.patch(`/reportes/${id}/rechazar-apelacion`)
      toast.success('Apelación rechazada. Sanción mantenida.')
      setRecargar(r => r + 1)
    } catch { toast.error('Error al rechazar apelación') }
  }

  const fechaCorta = (iso) => new Date(iso).toLocaleDateString('es-BO', {
    day: '2-digit', month: 'short', year: 'numeric'
  })

  const exportarPdf = () => descargarPdf(
    '/reporteria/moderacion',
    { estado: tab },
    `moderacion-${tab.toLowerCase()}`
  )

  const pendientes = reportes.filter(r => r.estado === 'PENDIENTE').length
  const apelados   = reportes.filter(r => r.estado === 'APELADO').length
  const reportesFiltrados = reportes.filter(r =>
    tab === 'RESUELTO' ? r.estado === 'RESUELTO' : r.estado === tab
  )

  return (
    <Layout titulo="Reportes">
      <div className="space-y-6">

      <div className="flex items-start justify-between gap-4">
          <div>
            <h2 className="text-xl font-bold text-gray-800 flex items-center gap-2">
              <Flag size={20} className="text-red-500" /> Reportes de estudiantes
            </h2>
            <p className="text-gray-500 text-sm mt-1">{reportes.length} reportes en total</p>
          </div>
          <button
            onClick={exportarPdf}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition flex-shrink-0"
            title="Exportar la pestaña actual a PDF"
          >
            <FileDown size={15} />
            Exportar PDF
          </button>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 border-b border-gray-200">
          <button
            onClick={() => setTab('PENDIENTE')}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold border-b-2 transition ${
              tab === 'PENDIENTE'
                ? 'border-amber-500 text-amber-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            🟡 Pendientes
            {pendientes > 0 && (
              <span className="px-1.5 py-0.5 rounded-full bg-amber-100 text-amber-700 text-xs font-bold">
                {pendientes}
              </span>
            )}
          </button>
          <button
            onClick={() => setTab('APELADO')}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold border-b-2 transition ${
              tab === 'APELADO'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            🔵 Apelaciones
            {apelados > 0 && (
              <span className={`px-1.5 py-0.5 rounded-full bg-blue-100 text-blue-700 text-xs font-bold ${apelados > 0 ? 'animate-pulse' : ''}`}>
                {apelados}
              </span>
            )}
          </button>
          <button
            onClick={() => setTab('RESUELTO')}
            className={`flex items-center gap-2 px-4 py-2.5 text-sm font-semibold border-b-2 transition ${
              tab === 'RESUELTO'
                ? 'border-emerald-500 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            🟢 Historial
          </button>
        </div>

        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          {cargando ? (
            <div className="flex items-center justify-center py-20">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
            </div>
        ) : reportesFiltrados.length === 0 ? (
            <div className="text-center py-20 text-gray-400">
              <p className="text-lg font-medium">
                {tab === 'PENDIENTE' && 'Sin reportes pendientes 🎉'}
                {tab === 'APELADO' && 'Sin apelaciones activas'}
                {tab === 'RESUELTO' && 'Sin reportes resueltos aún'}
              </p>
              <p className="text-sm mt-1">
                {tab === 'PENDIENTE' && 'Todo al día por ahora.'}
                {tab === 'APELADO' && 'Ningún propietario ha apelado todavía.'}
                {tab === 'RESUELTO' && 'Los reportes resueltos aparecerán aquí.'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Inmueble / Propietario</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Reportado por</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Motivo</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Fecha</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Estado</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                {reportesFiltrados.map((r) => (
                    <tr key={r.id} className={`hover:bg-gray-50 transition ${r.estado === 'APELADO' ? 'bg-blue-50/40' : ''}`}>
                      <td className="px-4 py-3">
                        <p className="text-sm font-medium text-gray-800">{r.inmueble?.titulo}</p>
                        <p className="text-xs text-gray-400">{r.inmueble?.propietario?.nombre}</p>
                      </td>
                      <td className="px-4 py-3">
                      <p className="text-sm text-gray-700">{r.reportante?.nombre ?? 'Usuario eliminado'}</p>
                        <p className="text-xs text-gray-400">{r.reportante?.email ?? '—'}</p>
                      </td>
                      <td className="px-4 py-3">
                        <span className="px-2 py-1 rounded-full text-xs font-medium bg-red-50 text-red-700">
                          {r.motivo}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        <span className="text-xs text-gray-400">{fechaCorta(r.creadoEn)}</span>
                      </td>
                      <td className="px-4 py-3">
                        <BadgeEstado estado={r.estado} />
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => setDetalle(r)}
                            className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 transition"
                            title="Ver detalle"
                          >
                            <Eye size={18} />
                          </button>
                          {r.estado === 'PENDIENTE' && (
                            <>
                              <button
                                onClick={() => descartar(r.id)}
                                className="p-2 rounded-lg text-emerald-600 hover:bg-emerald-50 transition"
                                title="Descartar"
                              >
                                <CheckCircle size={18} />
                              </button>
                              <button
                                onClick={() => sancionar(r.id)}
                                className="p-2 rounded-lg text-red-600 hover:bg-red-50 transition"
                                title="Sancionar"
                              >
                                <ShieldOff size={18} />
                              </button>
                            </>
                          )}
                          {r.estado === 'APELADO' && (
                            <>
                              <button
                                onClick={() => rechazarApelacion(r.id)}
                                className="p-2 rounded-lg text-red-600 hover:bg-red-50 transition"
                                title="Rechazar apelación"
                              >
                                <ThumbsDown size={18} />
                              </button>
                              <button
                                onClick={() => aceptarApelacion(r.id)}
                                className="p-2 rounded-lg text-emerald-600 hover:bg-emerald-50 transition"
                                title="Aceptar apelación"
                              >
                                <ThumbsUp size={18} />
                              </button>
                            </>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {detalle && (
        <ModalDetalleReporte
          reporte={detalle}
          onClose={() => setDetalle(null)}
          onDescartar={descartar}
          onSancionar={sancionar}
          onAceptarApelacion={aceptarApelacion}
          onRechazarApelacion={rechazarApelacion}
          onVerInmueble={(id) => {
            setDetalle(null)
            setVerInmuebleId(id)
          }}
        />
      )}

      {verInmuebleId && (
        <ModalDetalleInmueble
          inmuebleId={verInmuebleId}
          onClose={() => setVerInmuebleId(null)}
          onAprobar={() => {}}
          onSolicitarRechazo={() => {}}
        />
      )}
    </Layout>
  )
}