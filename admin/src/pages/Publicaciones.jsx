import { useState, useEffect } from 'react'
import Layout from '../components/Layout'
import api from '../services/api'
import toast from 'react-hot-toast'
import { CheckCircle, XCircle, Clock, Eye, Trash2, X, BadgeCheck, MapPin, Search, SlidersHorizontal, RotateCcw, FileDown } from 'lucide-react'
import { descargarPdf } from '../services/descargarPdf'

const ESTADOS = [
  { label: 'Todos', valor: '' },
  { label: 'Pendientes', valor: 'pendiente' },
  { label: 'Aprobados', valor: 'aprobado' },
]

const TIPOS = [
  { label: 'Todos', valor: '' },
  { label: 'Cuarto', valor: 'CUARTO' },
  { label: 'Departamento', valor: 'DEPARTAMENTO' },
  { label: 'Compartido', valor: 'COMPARTIDO' },
]

const OFERTAS = [
  { label: 'Todas', valor: '' },
  { label: '📋 Alquiler', valor: 'ALQUILER' },
  { label: '🔑 Anticrético', valor: 'ANTICRETICO' },
]

const MOTIVOS_RECHAZO = [
  'Fotos de mala calidad o borrosas',
  'Ubicación en el mapa no coincide con la dirección',
  'Precio o información inconsistente',
  'Contenido inadecuado (fotos falsas, anuncios repetidos o texto ofensivo)',
]

const labelTipo = (t) => ({ CUARTO: 'Cuarto', DEPARTAMENTO: 'Departamento', COMPARTIDO: 'Compartido' }[t] || t)
const labelGenero = (g) => ({
  MIXTO: 'Mixto', HOMBRES: 'Solo hombres', MUJERES: 'Solo mujeres', CUALQUIERA: 'Cualquiera'
}[g] || g)

function BadgeEstado({ inm }) {
  if (inm.aprobado && inm.disponible) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
        <CheckCircle size={12} /> Publicado
      </span>
    )
  }
  if (inm.aprobado && !inm.disponible) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
        <XCircle size={12} /> Desactivado
      </span>
    )
  }
  if (!inm.aprobado && !inm.disponible) {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
        <XCircle size={12} /> Rechazado
      </span>
    )
  }
  return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
      <Clock size={12} /> Pendiente
    </span>
  )
}
function ModalRechazo({ inmueble, onClose, onConfirmar }) {
  const [seleccionados, setSeleccionados] = useState([])
  const [comentario, setComentario] = useState('')
  const [enviando, setEnviando] = useState(false)

  const toggle = (motivo) => {
    setSeleccionados((prev) =>
      prev.includes(motivo) ? prev.filter((m) => m !== motivo) : [...prev, motivo]
    )
  }

  const confirmar = async () => {
    if (seleccionados.length === 0 && !comentario.trim()) {
      toast.error('Seleccioná al menos un motivo o escribí un comentario')
      return
    }
    setEnviando(true)
    const partes = [...seleccionados]
    if (comentario.trim()) partes.push(comentario.trim())
    const motivoFinal = partes.join('. ')

    try {
      await onConfirmar(motivoFinal)
    } finally {
      setEnviando(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[60] flex items-center justify-center p-4">
      <div className="bg-white rounded-xl w-full max-w-lg shadow-2xl">
        {/* Encabezado */}
        <div className="px-6 py-5 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-800">Rechazar Publicación</h3>
          <p className="text-sm text-gray-500 mt-1">
            {inmueble?.titulo && <span className="font-medium">"{inmueble.titulo}" — </span>}
            Seleccioná los motivos del rechazo para notificar al propietario.
          </p>
        </div>

        {/* Checkboxes */}
        <div className="px-6 py-4 space-y-2">
          {MOTIVOS_RECHAZO.map((motivo) => (
            <label
              key={motivo}
              className="flex items-start gap-3 p-3 rounded-lg border border-gray-200 hover:bg-gray-50 cursor-pointer transition"
            >
              <input
                type="checkbox"
                checked={seleccionados.includes(motivo)}
                onChange={() => toggle(motivo)}
                className="mt-0.5 w-4 h-4 rounded border-gray-300 text-red-600 focus:ring-red-500 flex-shrink-0"
              />
              <span className="text-sm text-gray-700">{motivo}</span>
            </label>
          ))}
        </div>

        {/* Comentario adicional */}
        <div className="px-6 pb-4">
          <label className="block text-sm font-medium text-gray-600 mb-2">
            Comentarios adicionales (Opcional)
          </label>
          <textarea
            value={comentario}
            onChange={(e) => setComentario(e.target.value)}
            placeholder="Agregá detalles específicos para el propietario..."
            rows={3}
            className="w-full px-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent transition text-sm text-gray-800 placeholder-gray-400 resize-none"
          />
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-gray-100 flex gap-3">
          <button
            onClick={onClose}
            disabled={enviando}
            className="flex-1 py-2.5 rounded-xl bg-gray-100 text-gray-600 font-semibold text-sm hover:bg-gray-200 transition disabled:opacity-50"
          >
            Cancelar
          </button>
          <button
            onClick={confirmar}
            disabled={enviando}
            className="flex-1 py-2.5 rounded-xl bg-red-600 text-white font-semibold text-sm hover:bg-red-700 transition disabled:opacity-50"
          >
            {enviando ? 'Enviando...' : 'Confirmar Rechazo'}
          </button>
        </div>
      </div>
    </div>
  )
}
export function ModalDetalleInmueble({ inmuebleId, onClose, onAprobar, onSolicitarRechazo }) {
  const [inm, setInm] = useState(null)
  const [historial, setHistorial] = useState([])
  const [cargando, setCargando] = useState(true)
  const [procesando, setProcesando] = useState(false)
  const [fotoActiva, setFotoActiva] = useState(0)
  const [verHistorial, setVerHistorial] = useState(false)

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      try {
        const [inmRes, histRes] = await Promise.all([
          api.get(`/inmuebles/${inmuebleId}`),
          api.get(`/inmuebles/${inmuebleId}/historial`).catch(() => ({ data: { datos: [] } }))
        ])
        if (!cancelado) {
          setInm(inmRes.data.datos)
          setHistorial(histRes.data.datos || [])
        }
      } catch {
        if (!cancelado) toast.error('Error al cargar el inmueble')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [inmuebleId])

  const aprobar = async () => {
    setProcesando(true)
    try {
      await onAprobar(inmuebleId)
      onClose()
    } finally {
      setProcesando(false)
    }
  }

  const construirCaracteristicas = (i) => {
    const items = []
    if (i.tipo === 'CUARTO') {
      if (i.tamano != null) items.push(['Tamaño', `${i.tamano} m²`])
      if (i.piso != null) items.push(['Piso', `Piso ${i.piso}`])
      if (i.banoCompartido != null) items.push(['Baño', i.banoCompartido ? 'Compartido' : 'Privado'])
      if (i.generoPermitido) items.push(['Género', labelGenero(i.generoPermitido)])
      if (i.amoblado != null) items.push(['Amoblado', i.amoblado ? 'Sí' : 'No'])
      if (i.permiteMascotas != null) items.push(['Mascotas', i.permiteMascotas ? 'Sí' : 'No'])
    } else if (i.tipo === 'DEPARTAMENTO') {
      if (i.numDormitorios != null) items.push(['Dormitorios', `${i.numDormitorios}`])
      if (i.numBanos != null) items.push(['Baños', `${i.numBanos}`])
      if (i.piso != null) items.push(['Piso', `Piso ${i.piso}`])
      if (i.habitantesMax != null) items.push(['Máx. personas', `${i.habitantesMax}`])
      if (i.generoPermitido) items.push(['Género', labelGenero(i.generoPermitido)])
      if (i.tieneParqueo != null) items.push(['Parqueo', i.tieneParqueo ? 'Incluido' : 'No'])
      if (i.amoblado != null) items.push(['Amoblado', i.amoblado ? 'Sí' : 'No'])
      if (i.permiteMascotas != null) items.push(['Mascotas', i.permiteMascotas ? 'Sí' : 'No'])
    } else if (i.tipo === 'COMPARTIDO') {
      if (i.habitacionesTotales != null) items.push(['Hab. totales', `${i.habitacionesTotales}`])
      if (i.habitacionesDisponibles != null) items.push(['Disponibles', `${i.habitacionesDisponibles}`])
      if (i.banoCompartido != null) items.push(['Baño', i.banoCompartido ? 'Compartido' : 'Privado'])
      if (i.generoConvivientes) items.push(['Convivientes', labelGenero(i.generoConvivientes)])
      if (i.generoPermitido) items.push(['Postulante', labelGenero(i.generoPermitido)])
      if (i.soloEstudiantes != null) items.push(['Perfil', i.soloEstudiantes ? 'Estudiantes' : 'Cualquiera'])
      if (i.permiteMascotas != null) items.push(['Mascotas', i.permiteMascotas ? 'Sí' : 'No'])
      if (i.edadMinima != null && i.edadMaxima != null) items.push(['Edades', `${i.edadMinima}–${i.edadMaxima} años`])
    }
    return items
  }

  const servicios = inm ? [
    inm.internetIncluido && 'Internet',
    inm.luzIncluida && 'Luz',
    inm.aguaIncluida && 'Agua',
    inm.gasIncluido && 'Gas',
  ].filter(Boolean) : []

  let reglas = []
  if (inm?.reglasComunes) {
    try { reglas = JSON.parse(inm.reglasComunes) } catch { /* ignore */ }
  }

  const totalHistorial = historial.length + (inm?.motivoRechazo ? 1 : 0)

  return (
    <>
      <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
          <div className="sticky top-0 bg-white flex items-center justify-between px-6 py-4 border-b border-gray-100 z-10">
            <h3 className="text-lg font-bold text-gray-800">Detalle de publicación</h3>
            <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 transition">
              <X size={20} className="text-gray-500" />
            </button>
          </div>

          {cargando ? (
            <div className="flex items-center justify-center py-20">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
            </div>
          ) : !inm ? (
            <p className="text-center text-gray-400 py-20">No se pudo cargar el inmueble</p>
          ) : (
            <div className="p-6 space-y-6">

              {/* Galería */}
              {inm.imagenes?.length > 0 ? (
                <div>
                  <div className="w-full h-[350px] max-h-[400px] bg-gray-900 rounded-xl overflow-hidden flex items-center justify-center">
                    <img
                      key={fotoActiva}
                      src={inm.imagenes[fotoActiva]?.url}
                      alt={inm.titulo}
                      className="w-full h-full object-contain"
                    />
                  </div>
                  {inm.imagenes.length > 1 && (
                    <div className="flex gap-2 mt-2 overflow-x-auto">
                      {inm.imagenes.map((img, idx) => (
                        <button
                          key={img.id}
                          onClick={() => setFotoActiva(idx)}
                          className={`flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden border-2 transition ${
                            idx === fotoActiva ? 'border-emerald-600' : 'border-transparent'
                          }`}
                        >
                          <img src={img.url} alt="" className="w-full h-full object-cover" />
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="w-full h-[350px] bg-gray-100 rounded-xl flex items-center justify-center text-gray-400">
                  Sin fotos
                </div>
              )}

              {/* Cabecera */}
              <div>
                <div className="flex items-center justify-between">
                <span className="text-2xl font-bold text-emerald-700">
                  Bs. {inm.precio}{inm.tipoOferta === 'ANTICRETICO' ? ' (Anticrético)' : '/mes'}
                </span>
                  <BadgeEstado inm={inm} />
                </div>
                <h4 className="text-lg font-bold text-gray-800 mt-1">{inm.titulo}</h4>
                <div className="flex items-center gap-4 mt-2 text-sm text-gray-500 flex-wrap">
                <span className="px-2 py-1 rounded-lg bg-gray-100 text-gray-600 text-xs font-medium">
                  {labelTipo(inm.tipo)}
                </span>
                <span className={`px-2 py-1 rounded-lg text-xs font-medium ${
                  inm.tipoOferta === 'ANTICRETICO'
                    ? 'bg-purple-100 text-purple-700'
                    : 'bg-blue-50 text-blue-600'
                }`}>
                  {inm.tipoOferta === 'ANTICRETICO' ? '🔑 Anticrético' : '📋 Alquiler'}
                </span>
                  <span className="flex items-center gap-1">
                    <MapPin size={13} /> {inm.direccion}, {inm.zona}
                  </span>
                </div>
                {inm.descripcion && (
                  <p className="text-sm text-gray-600 mt-3">{inm.descripcion}</p>
                )}
              </div>

              {/* Mapa */}
              <div>
                <p className="text-sm font-semibold text-gray-700 mb-2">Ubicación</p>
                {inm.latitud && inm.longitud ? (
                  <div className="rounded-xl overflow-hidden border border-gray-200 h-64">
                    <iframe
                      title="Ubicación del inmueble"
                      className="w-full h-full"
                      style={{ border: 0 }}
                      loading="lazy"
                      src={`https://www.google.com/maps?q=${inm.latitud},${inm.longitud}&z=16&output=embed`}
                    />
                  </div>
                ) : (
                  <div className="rounded-xl border border-gray-200 h-32 bg-gray-50 flex items-center justify-center text-gray-400 text-sm">
                    Sin coordenadas registradas
                  </div>
                )}
              </div>

              {/* Propietario */}
              <div className="bg-gray-50 rounded-xl p-4 flex items-center gap-3">
                <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center font-bold text-emerald-700">
                  {inm.propietario?.nombre?.[0]?.toUpperCase()}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-1.5">
                    <p className="text-sm font-semibold text-gray-800">{inm.propietario?.nombre}</p>
                    {inm.propietario?.verificado && (
                      <span title="Propietario verificado">
                        <BadgeCheck size={14} className="text-emerald-600" />
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-400">{inm.propietario?.email}</p>
                </div>
              </div>

              {/* Botón historial */}
              {totalHistorial > 0 && (
                <button
                  onClick={() => setVerHistorial(true)}
                  className="w-full flex items-center justify-between px-4 py-3 rounded-xl border border-amber-200 bg-amber-50 hover:bg-amber-100 transition"
                >
                  <span className="flex items-center gap-2 text-sm font-semibold text-amber-800">
                    📜 Historial de esta publicación
                    <span className="px-1.5 py-0.5 rounded-full bg-amber-200 text-amber-900 text-xs font-bold">
                      {totalHistorial}
                    </span>
                  </span>
                  <span className="text-amber-600 text-xs">Ver →</span>
                </button>
              )}

              {/* Servicios */}
              {servicios.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-700 mb-2">Servicios incluidos</p>
                  <div className="flex flex-wrap gap-2">
                    {servicios.map((s) => (
                      <span key={s} className="px-3 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700 border border-emerald-200">
                        {s}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Características */}
              {(() => {
                const items = construirCaracteristicas(inm)
                if (items.length === 0) return null
                return (
                  <div>
                    <p className="text-sm font-semibold text-gray-700 mb-2">Características</p>
                    <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                      {items.map(([label, valor]) => (
                        <div key={label} className="bg-gray-50 rounded-lg px-3 py-2">
                          <p className="text-xs text-gray-400">{label}</p>
                          <p className="text-sm font-semibold text-gray-800">{valor}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )
              })()}

              {/* Observaciones */}
              {inm.observaciones && (
                <div className="bg-gray-50 rounded-xl p-3">
                  <p className="text-xs font-semibold text-gray-500 mb-1">Observaciones adicionales</p>
                  <p className="text-sm text-gray-700">{inm.observaciones}</p>
                </div>
              )}

              {/* Reglas */}
              {reglas.length > 0 && (
                <div>
                  <p className="text-sm font-semibold text-gray-700 mb-2">Reglas de la casa</p>
                  <ul className="space-y-1.5">
                    {reglas.map((r, idx) => (
                      <li key={idx} className="text-sm text-gray-600 flex items-start gap-2">
                        <span className="text-emerald-600 mt-0.5">•</span> {r}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Acciones */}
              {!inm.aprobado && (
                <div className="flex gap-3 pt-2 border-t border-gray-100 mt-2">
                  <button
                    onClick={() => onSolicitarRechazo(inm)}
                    disabled={procesando}
                    className="flex-1 py-2.5 rounded-xl border border-red-200 text-red-600 font-semibold text-sm hover:bg-red-50 transition disabled:opacity-50 flex items-center justify-center gap-2 mt-4"
                  >
                    <XCircle size={16} /> Rechazar
                  </button>
                  <button
                    onClick={aprobar}
                    disabled={procesando}
                    className="flex-1 py-2.5 rounded-xl bg-emerald-600 text-white font-semibold text-sm hover:bg-emerald-700 transition disabled:opacity-50 flex items-center justify-center gap-2 mt-4"
                  >
                    <CheckCircle size={16} /> Aprobar
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Modal historial — ventana emergente separada */}
      {verHistorial && inm && (
        <div className="fixed inset-0 bg-black/50 z-[60] flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl w-full max-w-lg shadow-2xl max-h-[80vh] overflow-y-auto">
            <div className="sticky top-0 bg-white flex items-center justify-between px-6 py-4 border-b border-gray-100">
              <h3 className="text-base font-bold text-gray-800">📜 Historial de revisiones</h3>
              <button
                onClick={() => setVerHistorial(false)}
                className="p-1 rounded-lg hover:bg-gray-100 transition"
              >
                <X size={18} className="text-gray-500" />
              </button>
            </div>
            <div className="p-5 space-y-3">
              {inm.motivoRechazo && (
                <div className="flex gap-3 p-3 rounded-xl bg-red-50 border border-red-100">
                  <span className="text-lg mt-0.5">⚠️</span>
                  <div>
                    <p className="text-xs font-bold text-red-700">
                      Rechazado / Sancionado por administración
                    </p>
                    <p className="text-xs text-red-600 mt-1">{inm.motivoRechazo}</p>
                   
                  </div>
                </div>
              )}
              {historial.length === 0 && !inm.motivoRechazo && (
                <p className="text-center text-gray-400 text-sm py-8">Sin historial registrado</p>
              )}
              {historial.map((r) => (
                <div key={r.id} className="flex gap-3 p-3 rounded-xl bg-amber-50 border border-amber-100">
                  <span className="text-lg mt-0.5">🚩</span>
                  <div className="flex-1">
                    <div className="flex items-center justify-between">
                      <p className="text-xs font-bold text-amber-800">
                        Reportado el {new Date(r.creadoEn).toLocaleDateString('es-BO', {
                          day: '2-digit', month: 'long', year: 'numeric'
                        })}
                      </p>
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                        r.estado === 'RESUELTO'
                          ? 'bg-emerald-100 text-emerald-700'
                          : 'bg-amber-100 text-amber-700'
                      }`}>
                        {r.estado === 'RESUELTO' ? 'Resuelto' : 'Pendiente'}
                      </span>
                    </div>
                    <p className="text-xs text-gray-600 mt-0.5">
                      Por: {r.reportante?.nombre} ({r.reportante?.email})
                    </p>
                    <span className="inline-block mt-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700">
                      {r.motivo}
                    </span>
                    {r.comentario && (
                      <p className="text-xs text-gray-500 italic mt-1.5">"{r.comentario}"</p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  )
}

function FilaInmueble({ inm, onAprobar, onSolicitarRechazo, onEliminar, onVerDetalle, onToggleDisponible }) {
  return (
    <tr className="hover:bg-gray-50 transition">
      <td className="px-4 py-3">
        <button onClick={() => onVerDetalle(inm.id)} className="flex items-center gap-3 text-left">
          {inm.imagenes?.[0] ? (
            <img src={inm.imagenes[0].url} alt={inm.titulo} className="w-12 h-12 rounded-xl object-cover flex-shrink-0" />
          ) : (
            <div className="w-12 h-12 rounded-xl bg-gray-100 flex items-center justify-center flex-shrink-0">
              <span className="text-gray-400 text-lg">🏠</span>
            </div>
          )}
          <div>
            <p className="font-medium text-gray-800 text-sm hover:text-emerald-700 transition">{inm.titulo}</p>
            <p className="text-gray-400 text-xs">{inm.zona} — {inm.direccion}</p>
          </div>
        </button>
      </td>
      <td className="px-4 py-3">
        <p className="text-sm text-gray-700">{inm.propietario?.nombre}</p>
        <p className="text-xs text-gray-400">{inm.propietario?.email}</p>
      </td>
      <td className="px-4 py-3">
        <div className="flex flex-col gap-1">
          <span className="px-2 py-1 rounded-lg text-xs font-medium bg-gray-100 text-gray-600">
            {inm.tipo}
          </span>
          <span className={`px-2 py-1 rounded-lg text-xs font-medium ${
            inm.tipoOferta === 'ANTICRETICO'
              ? 'bg-purple-100 text-purple-700'
              : 'bg-blue-50 text-blue-600'
          }`}>
            {inm.tipoOferta === 'ANTICRETICO' ? '🔑 Anticrético' : '📋 Alquiler'}
          </span>
        </div>
      </td>
      <td className="px-4 py-3">
        <span className="text-sm font-semibold text-emerald-700">Bs. {inm.precio}</span>
      </td>
      <td className="px-4 py-3">
        <BadgeEstado inm={inm} />
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center gap-1">
          <button onClick={() => onVerDetalle(inm.id)} className="p-2 rounded-lg text-gray-500 hover:bg-gray-100 transition" title="Ver detalles">
            <Eye size={18} />
          </button>
          {!inm.aprobado && (
            <button onClick={() => onAprobar(inm.id)} className="p-2 rounded-lg text-green-600 hover:bg-green-50 transition" title="Aprobar">
              <CheckCircle size={18} />
            </button>
          )}
          {!inm.aprobado && (
            <button onClick={() => onSolicitarRechazo(inm)} className="p-2 rounded-lg text-red-400 hover:bg-red-50 transition" title="Rechazar">
              <XCircle size={18} />
            </button>
          )}
          {inm.aprobado && inm.disponible && (
            <button onClick={() => onToggleDisponible(inm.id, false)} className="p-2 rounded-lg text-amber-600 hover:bg-amber-50 transition" title="Desactivar">
              <XCircle size={18} />
            </button>
          )}
          {inm.aprobado && !inm.disponible && (
            <button onClick={() => onToggleDisponible(inm.id, true)} className="p-2 rounded-lg text-blue-600 hover:bg-blue-50 transition" title="Reactivar">
              <Eye size={18} />
            </button>
          )}
          <button onClick={() => onEliminar(inm.id, inm.titulo)} className="p-2 rounded-lg text-red-600 hover:bg-red-50 transition" title="Eliminar">
            <Trash2 size={18} />
          </button>
        </div>
      </td>
    </tr>
  )
}

export default function Publicaciones() {
  const [inmuebles, setInmuebles] = useState([])
  const [cargando, setCargando] = useState(false)
  const [estado, setEstado] = useState('')
  const [tipo, setTipo] = useState('')
  const [tipoOferta, setTipoOferta] = useState('')
  const [buscar, setBuscar] = useState('')
  const [buscarInput, setBuscarInput] = useState('')
  const [precioMin, setPrecioMin] = useState('')
  const [precioMax, setPrecioMax] = useState('')
  const [desde, setDesde] = useState('')
  const [hasta, setHasta] = useState('')
  const [verMasFiltros, setVerMasFiltros] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [totalPaginas, setTotalPaginas] = useState(1)
  const [total, setTotal] = useState(0)
  const [recargar, setRecargar] = useState(0)
  const [detalleId, setDetalleId] = useState(null)
  const [rechazoTarget, setRechazoTarget] = useState(null) // inmueble completo o { id, titulo }

  useEffect(() => {
    const t = setTimeout(() => {
      setBuscar(buscarInput)
      setPagina(1)
    }, 400)
    return () => clearTimeout(t)
  }, [buscarInput])

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      setCargando(true)
      try {
        const params = new URLSearchParams({
          page: pagina,
          limit: 10,
          ...(estado && { estado }),
          ...(tipo && { tipo }),
          ...(tipoOferta && { tipoOferta }),
          ...(buscar && { buscar }),
          ...(precioMin && { precioMin }),
          ...(precioMax && { precioMax }),
          ...(desde && { desde }),
          ...(hasta && { hasta }),
        })
        const res = await api.get(`/inmuebles/admin/todas?${params}`)
        if (!cancelado) {
          setInmuebles(res.data.datos.inmuebles)
          setTotal(res.data.datos.total)
          setTotalPaginas(res.data.datos.totalPaginas)
        }
      } catch {
        if (!cancelado) toast.error('Error al cargar publicaciones')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [estado, tipo, tipoOferta, buscar, precioMin, precioMax, desde, hasta, pagina, recargar])

  const filtrosActivos = [estado, tipo, tipoOferta, buscar, precioMin, precioMax, desde, hasta].filter(Boolean).length

  const limpiarFiltros = () => {
    setEstado(''); setTipo(''); setTipoOferta('')
    setBuscar(''); setBuscarInput('')
    setPrecioMin(''); setPrecioMax('')
    setDesde(''); setHasta('')
    setPagina(1)
  }

  const exportarPdf = () => descargarPdf(
    '/reporteria/publicaciones',
    { estado, tipo, tipoOferta, buscar, precioMin, precioMax, desde, hasta },
    'publicaciones'
  )

  const aprobar = async (id) => {
    try {
      await api.patch(`/inmuebles/admin/${id}/estado`, { aprobado: true, disponible: true })
      toast.success('Publicación aprobada')
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al aprobar')
    }
  }

  const toggleDisponible = async (id, disponible) => {
    try {
      await api.patch(`/inmuebles/admin/${id}/estado`, { disponible })
      toast.success(disponible ? 'Publicación reactivada' : 'Publicación desactivada')
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al actualizar estado')
    }
  }

  const confirmarRechazo = async (motivoFinal) => {
    try {
      await api.patch(`/inmuebles/admin/${rechazoTarget.id}/estado`, {
        aprobado: false,
        disponible: false,
        motivoRechazo: motivoFinal,
      })
      toast.success('Publicación rechazada, el propietario fue notificado')
      setRechazoTarget(null)
      setDetalleId(null)
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al rechazar la publicación')
    }
  }

  const eliminar = async (id, titulo) => {
    if (!window.confirm(`¿Eliminar "${titulo}"? Esta acción no se puede deshacer.`)) return
    try {
      await api.delete(`/inmuebles/${id}`)
      toast.success('Publicación eliminada')
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al eliminar')
    }
  }

  return (
    <Layout titulo="Publicaciones">
      <div className="space-y-6">

        <div>
          <h2 className="text-xl font-bold text-gray-800">Gestión de publicaciones</h2>
          <p className="text-gray-500 text-sm mt-1">{total} publicaciones en total</p>
        </div>

        {/* Filtros */}
               {/* Filtros */}
               <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          <div className="p-4 flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[240px]">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                value={buscarInput}
                onChange={(e) => setBuscarInput(e.target.value)}
                placeholder="Buscar por título, zona, dirección o propietario..."
                className="w-full pl-9 pr-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition"
              />
            </div>

            <select
              value={estado}
              onChange={(e) => { setEstado(e.target.value); setPagina(1) }}
              className="px-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
            >
              {ESTADOS.map((e) => (
                <option key={e.valor} value={e.valor}>{e.label === 'Todos' ? 'Estado: Todos' : e.label}</option>
              ))}
            </select>

            <select
              value={tipo}
              onChange={(e) => { setTipo(e.target.value); setPagina(1) }}
              className="px-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
            >
              {TIPOS.map((t) => (
                <option key={t.valor} value={t.valor}>{t.label === 'Todos' ? 'Tipo: Todos' : t.label}</option>
              ))}
            </select>

            <button
              onClick={() => setVerMasFiltros(v => !v)}
              className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-sm font-medium transition border ${
                verMasFiltros || precioMin || precioMax || desde || hasta || tipoOferta
                  ? 'bg-emerald-50 border-emerald-200 text-emerald-700'
                  : 'bg-gray-50 border-gray-200 text-gray-600 hover:bg-gray-100'
              }`}
            >
              <SlidersHorizontal size={15} />
              Más filtros
            </button>

            {filtrosActivos > 0 && (
              <button
                onClick={limpiarFiltros}
                className="flex items-center gap-1.5 px-3 py-2.5 rounded-xl text-sm font-medium text-gray-500 hover:bg-gray-100 transition"
                title="Limpiar filtros"
              >
                <RotateCcw size={14} />
                Limpiar
              </button>
            )}

            <button
              onClick={exportarPdf}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition"
              title="Exportar a PDF con los filtros actuales"
            >
              <FileDown size={15} />
              Exportar PDF
            </button>
          </div>

          {verMasFiltros && (
            <div className="px-4 pb-4 pt-1 border-t border-gray-100 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="lg:col-span-1">
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Tipo de oferta</label>
                <select
                  value={tipoOferta}
                  onChange={(e) => { setTipoOferta(e.target.value); setPagina(1) }}
                  className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                >
                  {OFERTAS.map((o) => (
                    <option key={o.valor} value={o.valor}>{o.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Precio (Bs.)</label>
                <div className="flex gap-2">
                  <input
                    type="number"
                    value={precioMin}
                    onChange={(e) => { setPrecioMin(e.target.value); setPagina(1) }}
                    placeholder="Mín"
                    className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                  />
                  <input
                    type="number"
                    value={precioMax}
                    onChange={(e) => { setPrecioMax(e.target.value); setPagina(1) }}
                    placeholder="Máx"
                    className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Publicado desde</label>
                <input
                  type="date"
                  value={desde}
                  onChange={(e) => { setDesde(e.target.value); setPagina(1) }}
                  className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-gray-500 mb-1.5">Publicado hasta</label>
                <input
                  type="date"
                  value={hasta}
                  onChange={(e) => { setHasta(e.target.value); setPagina(1) }}
                  className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                />
              </div>
            </div>
          )}
        </div>

        {/* Tabla */}
        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
          {cargando ? (
            <div className="flex items-center justify-center py-20">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
            </div>
          ) : inmuebles.length === 0 ? (
            <div className="text-center py-20 text-gray-400">
              <p className="text-lg font-medium">No hay publicaciones</p>
              <p className="text-sm mt-1">Cambiá los filtros para ver resultados</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-100">
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Inmueble</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Propietario</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Tipo</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Precio</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Estado</th>
                    <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Acciones</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {inmuebles.map((inm) => (
                    <FilaInmueble
                      key={inm.id}
                      inm={inm}
                      onAprobar={aprobar}
                      onSolicitarRechazo={setRechazoTarget}
                      onEliminar={eliminar}
                      onVerDetalle={setDetalleId}
                      onToggleDisponible={toggleDisponible}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Paginación */}
        {totalPaginas > 1 && (
          <div className="flex items-center justify-center gap-2">
            <button onClick={() => setPagina(p => p - 1)} disabled={pagina === 1} className="px-4 py-2 rounded-xl bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40 transition text-sm">
              Anterior
            </button>
            <span className="text-sm text-gray-500">Página {pagina} de {totalPaginas}</span>
            <button onClick={() => setPagina(p => p + 1)} disabled={pagina === totalPaginas} className="px-4 py-2 rounded-xl bg-white border border-gray-200 text-gray-600 hover:bg-gray-50 disabled:opacity-40 transition text-sm">
              Siguiente
            </button>
          </div>
        )}

      </div>

      {detalleId && (
        <ModalDetalleInmueble
          inmuebleId={detalleId}
          onClose={() => setDetalleId(null)}
          onAprobar={aprobar}
          onSolicitarRechazo={setRechazoTarget}
        />
      )}

      {rechazoTarget && (
        <ModalRechazo
          inmueble={rechazoTarget}
          onClose={() => setRechazoTarget(null)}
          onConfirmar={confirmarRechazo}
        />
      )}
    </Layout>
  )
}