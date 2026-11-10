import { useState, useEffect } from 'react'
import Layout from '../components/Layout'
import api from '../services/api'
import toast from 'react-hot-toast'
import { UserCheck, UserX, Trash2, Shield, Home, User, X, CheckCircle, XCircle, BadgeCheck, Clock, Search, SlidersHorizontal, RotateCcw, FileDown } from 'lucide-react'
import { descargarPdf } from '../services/descargarPdf'

const ROLES = [
  { label: 'Todos', valor: '' },
  { label: 'Arrendatarios', valor: 'ARRENDATARIO' },
  { label: 'Propietarios', valor: 'PROPIETARIO' },
]

const ESTADOS_CUENTA = [
  { label: 'Estado: Todos', valor: '' },
  { label: 'Activos', valor: 'true' },
  { label: 'Suspendidos', valor: 'false' },
]

const VERIFICACIONES = [
  { label: 'Verificación: Todas', valor: '' },
  { label: 'Verificados', valor: 'APROBADO' },
  { label: 'Por revisar', valor: 'PENDIENTE' },
  { label: 'No verificados', valor: 'NO_VERIFICADO' },
]

function BadgeRol({ rol }) {
  if (rol === 'ADMIN') return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700">
      <Shield size={11} /> Admin
    </span>
  )
  if (rol === 'PROPIETARIO') return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
      <Home size={11} /> Propietario
    </span>
  )
  return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700">
      <User size={11} /> Arrendatario
    </span>
  )
}

function BadgeVerificacion({ estado }) {
  if (estado === 'APROBADO') {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
        <BadgeCheck size={12} /> Verificado
      </span>
    )
  }
  if (estado === 'PENDIENTE') {
    return (
      <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 animate-pulse">
        <Clock size={12} /> Por Revisar
      </span>
    )
  }
  return (
    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-500">
      No Verificado
    </span>
  )
}

function FilaUsuario({ usuario, onCambiarEstado, onEliminar }) {
  const fecha = new Date(usuario.creadoEn).toLocaleDateString('es-BO', {
    day: '2-digit', month: 'short', year: 'numeric'
  })

  return (
    <tr className="hover:bg-gray-50 transition">
      <td className="px-4 py-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center font-bold text-emerald-700 flex-shrink-0">
            {usuario.nombre?.[0]?.toUpperCase()}
          </div>
          <div className="flex flex-col justify-center">
            <p className="font-medium text-gray-800 text-sm leading-tight">{usuario.nombre}</p>
            <p className="text-gray-400 text-xs leading-tight">{usuario.email}</p>
            {usuario.rol === 'PROPIETARIO' && (
              <div className="mt-1">
                <BadgeVerificacion estado={usuario.estadoVerificacion} />
              </div>
            )}
          </div>
        </div>
      </td>
      <td className="px-4 py-3">
        <BadgeRol rol={usuario.rol} />
      </td>
      <td className="px-4 py-3">
        <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium ${usuario.activo ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
          {usuario.activo ? <UserCheck size={11} /> : <UserX size={11} />}
          {usuario.activo ? 'Activo' : 'Suspendido'}
        </span>
      </td>
      <td className="px-4 py-3">
        <span className="text-sm text-gray-600">
          {usuario._count?.inmuebles ?? 0} publicaciones
        </span>
      </td>
      <td className="px-4 py-3">
        <span className="text-xs text-gray-400">{fecha}</span>
      </td>
      <td className="px-4 py-3">
        <div className="flex items-center gap-1">
          {usuario.rol !== 'ADMIN' && (
            <>
              {usuario.activo ? (
                <button onClick={() => onCambiarEstado(usuario.id, false)} className="p-2 rounded-lg text-amber-600 hover:bg-amber-50 transition" title="Suspender">
                  <UserX size={18} />
                </button>
              ) : (
                <button onClick={() => onCambiarEstado(usuario.id, true)} className="p-2 rounded-lg text-green-600 hover:bg-green-50 transition" title="Activar">
                  <UserCheck size={18} />
                </button>
              )}
              <button onClick={() => onEliminar(usuario.id, usuario.nombre)} className="p-2 rounded-lg text-red-600 hover:bg-red-50 transition" title="Eliminar">
                <Trash2 size={18} />
              </button>
            </>
          )}
          {usuario.rol === 'ADMIN' && (
            <span className="text-xs text-gray-400 px-2">Protegido</span>
          )}
        </div>
      </td>
    </tr>
  )
}
function formatearTelefono(tel) {
  if (!tel) return '—'
  let limpio = tel.trim()
  if (limpio.startsWith('+591')) limpio = limpio.substring(4)
  else if (limpio.startsWith('591') && limpio.length === 11) limpio = limpio.substring(3)
  return limpio
}

function ModalVerificacion({ propietarioId, onClose, onResuelto }) {
  const [detalle, setDetalle] = useState(null)
  const [cargando, setCargando] = useState(true)
  const [procesando, setProcesando] = useState(false)

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      try {
        const res = await api.get(`/verificacion/${propietarioId}`)
        if (!cancelado) setDetalle(res.data.datos)
      } catch {
        if (!cancelado) toast.error('Error al cargar detalle')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [propietarioId])

  const resolver = async (accion) => {
    setProcesando(true)
    try {
      await api.patch(`/verificacion/${propietarioId}/${accion}`)
      toast.success(accion === 'aprobar' ? 'Verificación aprobada' : 'Verificación rechazada')
      onResuelto()
      onClose()
    } catch {
      toast.error('Error al procesar la verificación')
    } finally {
      setProcesando(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white flex items-center justify-between px-6 py-4 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-800">Detalle de verificación</h3>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-100 transition">
            <X size={20} className="text-gray-500" />
          </button>
        </div>

        {cargando ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
          </div>
        ) : !detalle ? (
          <p className="text-center text-gray-400 py-20">No se pudo cargar el detalle</p>
        ) : (
          <div className="p-6 space-y-6">
            {/* Datos personales */}
            {/* Datos personales */}
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 bg-amber-50 border border-amber-200 rounded-xl p-3">
                <p className="text-xs text-amber-700 font-medium mb-1">
                  Comparar con las fotos antes de aprobar
                </p>
                <div className="flex gap-6">
                  <div>
                    <p className="text-xs text-gray-500">Nombre en el carnet (legal)</p>
                    <p className="text-sm font-bold text-gray-800">{detalle.nombreLegal || '—'}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500">Nombre en registro de cuenta</p>
                    <p className="text-sm font-medium text-gray-600">{detalle.nombre}</p>
                  </div>
                </div>
              </div>
              <div>
                <p className="text-xs text-gray-500">Email</p>
                <p className="text-sm font-medium text-gray-800">{detalle.email}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Teléfono</p>
                <p className="text-sm font-medium text-gray-800">{formatearTelefono(detalle.telefono)}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Número de C.I.</p>
                <p className="text-sm font-medium text-gray-800">
                  {detalle.ciNumero} {detalle.ciExtension}
                </p>
              </div>
            </div>

            {/* Fotos */}
            <div>
              <p className="text-xs font-medium text-gray-500 mb-2">Documentos de respaldo</p>
              <div className="grid grid-cols-3 gap-3">
                {[
                  { label: 'Anverso', url: detalle.fotoAnversoUrl },
                  { label: 'Reverso', url: detalle.fotoReversoUrl },
                  { label: 'Rostro', url: detalle.fotoRostroUrl },
                ].map((f) => (
                  <div key={f.label}>
                    <a href={f.url} target="_blank" rel="noreferrer">
                      <img
                        src={f.url}
                        alt={f.label}
                        className="w-full h-32 object-cover rounded-xl border border-gray-200 hover:opacity-90 transition"
                      />
                    </a>
                    <p className="text-xs text-gray-500 text-center mt-1">{f.label}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Acciones */}
            <div className="flex gap-3 pt-2">
              <button
                onClick={() => resolver('rechazar')}
                disabled={procesando}
                className="flex-1 py-2.5 rounded-xl border border-red-200 text-red-600 font-semibold text-sm hover:bg-red-50 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <XCircle size={16} /> Rechazar
              </button>
              <button
                onClick={() => resolver('aprobar')}
                disabled={procesando}
                className="flex-1 py-2.5 rounded-xl bg-emerald-600 text-white font-semibold text-sm hover:bg-emerald-700 transition disabled:opacity-50 flex items-center justify-center gap-2"
              >
                <CheckCircle size={16} /> Aprobar
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default function Usuarios() {
  const [tab, setTab] = useState('todos') // 'todos' | 'verificaciones'
  const [usuarios, setUsuarios] = useState([])
  const [cargando, setCargando] = useState(false)
  const [rol, setRol] = useState('')
  const [activo, setActivo] = useState('')
  const [verificacion, setVerificacion] = useState('')
  const [buscar, setBuscar] = useState('')
  const [buscarInput, setBuscarInput] = useState('')
  const [desde, setDesde] = useState('')
  const [hasta, setHasta] = useState('')
  const [verMasFiltros, setVerMasFiltros] = useState(false)
  const [pagina, setPagina] = useState(1)
  const [totalPaginas, setTotalPaginas] = useState(1)
  const [total, setTotal] = useState(0)
  const [recargar, setRecargar] = useState(0)
  const [verificaciones, setVerificaciones] = useState([])
  const [cargandoVer, setCargandoVer] = useState(false)
  const [modalId, setModalId] = useState(null)
  const [recargarVer, setRecargarVer] = useState(0)

  useEffect(() => {
    const t = setTimeout(() => {
      setBuscar(buscarInput)
      setPagina(1)
    }, 400)
    return () => clearTimeout(t)
  }, [buscarInput])

  useEffect(() => {
    if (tab !== 'todos') return
    let cancelado = false
    const cargar = async () => {
      setCargando(true)
      try {
        const params = new URLSearchParams({
          page: pagina, limit: 10,
          ...(rol && { rol }),
          ...(activo !== '' && { activo }),
          ...(verificacion && { verificacion }),
          ...(buscar && { buscar }),
          ...(desde && { desde }),
          ...(hasta && { hasta }),
        })
        const res = await api.get(`/usuarios?${params}`)
        if (!cancelado) {
          setUsuarios(res.data.datos.usuarios)
          setTotal(res.data.datos.total)
          setTotalPaginas(res.data.datos.totalPaginas)
        }
      } catch {
        if (!cancelado) toast.error('Error al cargar usuarios')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [rol, activo, verificacion, buscar, desde, hasta, pagina, recargar, tab])

  const filtrosActivos = [rol, activo, verificacion, buscar, desde, hasta].filter(v => v !== '').length

  const limpiarFiltros = () => {
    setRol(''); setActivo(''); setVerificacion('')
    setBuscar(''); setBuscarInput('')
    setDesde(''); setHasta('')
    setPagina(1)
  }

  const exportarPdf = () => descargarPdf(
    '/reporteria/usuarios',
    { rol, activo, verificacion, buscar, desde, hasta },
    'usuarios'
  )

  useEffect(() => {
    if (tab !== 'verificaciones') return
    let cancelado = false
    const cargar = async () => {
      setCargandoVer(true)
      try {
        const res = await api.get('/verificacion/pendientes')
        if (!cancelado) setVerificaciones(res.data.datos)
      } catch {
        if (!cancelado) toast.error('Error al cargar verificaciones')
      } finally {
        if (!cancelado) setCargandoVer(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [tab, recargarVer])

  const cambiarEstado = async (id, activo) => {
    try {
      await api.patch(`/usuarios/${id}/estado`, { activo })
      toast.success(activo ? 'Usuario activado' : 'Usuario suspendido')
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al cambiar estado')
    }
  }

  const eliminar = async (id, nombre) => {
    if (!window.confirm(`¿Eliminar a "${nombre}"? Esta acción no se puede deshacer.`)) return
    try {
      await api.delete(`/usuarios/${id}`)
      toast.success('Usuario eliminado')
      setRecargar(r => r + 1)
    } catch {
      toast.error('Error al eliminar usuario')
    }
  }

  const fechaCorta = (iso) => new Date(iso).toLocaleDateString('es-BO', {
    day: '2-digit', month: 'short', year: 'numeric'
  })

  const formatearTelefono = (tel) => {
    if (!tel) return '—'
    let limpio = tel.trim()
    if (limpio.startsWith('+591')) limpio = limpio.substring(4)
    else if (limpio.startsWith('591') && limpio.length === 11) limpio = limpio.substring(3)
    return limpio
  }

  return (
    <Layout titulo="Usuarios">
      <div className="space-y-6">

        <div>
          <h2 className="text-xl font-bold text-gray-800">Gestión de usuarios</h2>
          <p className="text-gray-500 text-sm mt-1">
            {tab === 'todos' ? `${total} usuarios registrados` : `${verificaciones.length} verificaciones pendientes`}
          </p>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 border-b border-gray-200">
          <button
            onClick={() => setTab('todos')}
            className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition ${
              tab === 'todos'
                ? 'border-emerald-600 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            Todos los Usuarios
          </button>
          <button
            onClick={() => setTab('verificaciones')}
            className={`px-4 py-2.5 text-sm font-semibold border-b-2 transition flex items-center gap-2 ${
              tab === 'verificaciones'
                ? 'border-emerald-600 text-emerald-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            Verificaciones Pendientes
            {verificaciones.length > 0 && (
              <span className="px-1.5 py-0.5 rounded-full bg-amber-100 text-amber-700 text-xs font-bold">
                {verificaciones.length}
              </span>
            )}
          </button>
        </div>

        {tab === 'todos' ? (
          <>
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
                    placeholder="Buscar por nombre o email..."
                    className="w-full pl-9 pr-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent transition"
                  />
                </div>

                <select
                  value={rol}
                  onChange={(e) => { setRol(e.target.value); setPagina(1) }}
                  className="px-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                >
                  {ROLES.map((r) => (
                    <option key={r.valor} value={r.valor}>{r.label === 'Todos' ? 'Rol: Todos' : r.label}</option>
                  ))}
                </select>

                <select
                  value={activo}
                  onChange={(e) => { setActivo(e.target.value); setPagina(1) }}
                  className="px-3 py-2.5 rounded-xl border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                >
                  {ESTADOS_CUENTA.map((e) => (
                    <option key={e.valor} value={e.valor}>{e.label}</option>
                  ))}
                </select>

                <button
                  onClick={() => setVerMasFiltros(v => !v)}
                  className={`flex items-center gap-2 px-3 py-2.5 rounded-xl text-sm font-medium transition border ${
                    verMasFiltros || verificacion || desde || hasta
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
                <div className="px-4 pb-4 pt-1 border-t border-gray-100 grid grid-cols-1 sm:grid-cols-3 gap-4">
                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1.5">Verificación (propietarios)</label>
                    <select
                      value={verificacion}
                      onChange={(e) => { setVerificacion(e.target.value); setPagina(1) }}
                      className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                    >
                      {VERIFICACIONES.map((v) => (
                        <option key={v.valor} value={v.valor}>{v.label}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1.5">Registrado desde</label>
                    <input
                      type="date"
                      value={desde}
                      onChange={(e) => { setDesde(e.target.value); setPagina(1) }}
                      className="w-full px-3 py-2 rounded-lg border border-gray-200 bg-gray-50 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 transition"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-medium text-gray-500 mb-1.5">Registrado hasta</label>
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
              ) : usuarios.length === 0 ? (
                <div className="text-center py-20 text-gray-400">
                  <p className="text-lg font-medium">No hay usuarios</p>
                  <p className="text-sm mt-1">Cambiá los filtros para ver resultados</p>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead>
                      <tr className="bg-gray-50 border-b border-gray-100">
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Usuario</th>
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Rol</th>
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Estado</th>
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Actividad</th>
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Registro</th>
                        <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Acciones</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                      {usuarios.map((u) => (
                        <FilaUsuario key={u.id} usuario={u} onCambiarEstado={cambiarEstado} onEliminar={eliminar} />
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

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
          </>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
            {cargandoVer ? (
              <div className="flex items-center justify-center py-20">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
              </div>
            ) : verificaciones.length === 0 ? (
              <div className="text-center py-20 text-gray-400">
                <p className="text-lg font-medium">Sin verificaciones pendientes</p>
                <p className="text-sm mt-1">Todo al día 🎉</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="bg-gray-50 border-b border-gray-100">
                      <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Propietario</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Contacto</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Enviado</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Estado</th>
                      <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Acción</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {verificaciones.map((v) => (
                      <tr key={v.id} className="hover:bg-gray-50 transition">
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-3">
                            <div className="w-9 h-9 rounded-full bg-emerald-100 flex items-center justify-center font-bold text-emerald-700 text-sm flex-shrink-0">
                              {(v.nombreLegal || v.nombre)?.[0]?.toUpperCase()}
                            </div>
                            <div>
                              <p className="font-medium text-gray-800 text-sm">{v.nombreLegal || '—'}</p>
                              <p className="text-xs text-gray-400">Registro: {v.nombre}</p>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <p className="text-sm text-gray-600">{v.email}</p>
                          <p className="text-xs text-gray-400">{formatearTelefono(v.telefono)}</p>
                        </td>
                        <td className="px-4 py-3">
                          <span className="text-xs text-gray-400">{fechaCorta(v.actualizadoEn)}</span>
                        </td>
                        <td className="px-4 py-3">
                          <span className="px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                            Pendiente
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <button
                            onClick={() => setModalId(v.id)}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition"
                          >
                            Revisar
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </div>

      {modalId && (
        <ModalVerificacion
          propietarioId={modalId}
          onClose={() => setModalId(null)}
          onResuelto={() => setRecargarVer(r => r + 1)}
        />
      )}
    </Layout>
  )
}