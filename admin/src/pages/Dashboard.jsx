import { useState, useEffect } from 'react'
import Layout from '../components/Layout'
import api from '../services/api'
import toast from 'react-hot-toast'
import { useNavigate } from 'react-router-dom'
import {
  Users, ShieldAlert, Home, Handshake, FileText, FileDown,
} from 'lucide-react'
import { descargarPdf } from '../services/descargarPdf'
import {
  AreaChart, Area, BarChart, Bar, XAxis, YAxis,
  CartesianGrid, Tooltip, ResponsiveContainer, Legend,
} from 'recharts'

function KpiCard({ icono: Icono, label, valor, colorIcono, colorFondo }) {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500 font-medium">{label}</p>
          <p className={`text-3xl font-bold mt-2 ${colorIcono}`}>{valor}</p>
        </div>
        <div className={`w-12 h-12 rounded-full flex items-center justify-center ${colorFondo}`}>
          <Icono size={22} className={colorIcono} />
        </div>
      </div>
    </div>
  )
}

export default function Dashboard() {
  const navigate = useNavigate()
  const [datos, setDatos] = useState(null)
  const [cargando, setCargando] = useState(true)

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      try {
        const res = await api.get('/estadisticas/admin')
        if (!cancelado) setDatos(res.data.datos)
      } catch {
        if (!cancelado) toast.error('Error al cargar el dashboard')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
  }, [])

  const fechaCorta = (iso) => new Date(iso).toLocaleDateString('es-BO', {
    day: '2-digit', month: 'short', year: 'numeric'
  })

  const exportarGeneral = () => descargarPdf('/reporteria/general', {}, 'general')

  return (
    <Layout titulo="Panel principal">
      <div className="space-y-6">

        <div>
          <h2 className="text-2xl font-bold text-gray-800 mb-2">Bienvenido al panel</h2>
          <p className="text-gray-500">Desde aquí puedes gestionar las publicaciones y usuarios de UniHab.</p>
        </div>

        {cargando ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
          </div>
        ) : (
          <>
            {/* ── KPIs ─────────────────────────────── */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
              <KpiCard
                icono={Users}
                label="Arrendatarios Registrados"
                valor={datos.totalEstudiantes}
                colorIcono="text-emerald-600"
                colorFondo="bg-emerald-50"
              />
              <KpiCard
                icono={Users}
                label="Propietarios Registrados"
                valor={datos.totalPropietarios}
                colorIcono="text-emerald-600"
                colorFondo="bg-emerald-50"
              />
              <KpiCard
                icono={ShieldAlert}
                label="Verificaciones Pendientes"
                valor={datos.verificacionesPendientes}
                colorIcono="text-amber-600"
                colorFondo="bg-amber-50"
              />
              <KpiCard
                icono={Home}
                label="Inmuebles Publicados"
                valor={datos.inmueblesPublicados}
                colorIcono="text-emerald-600"
                colorFondo="bg-emerald-50"
              />
              <KpiCard
                icono={Handshake}
                label="Matches Exitosos"
                valor={datos.matchesExitosos}
                colorIcono="text-emerald-600"
                colorFondo="bg-emerald-50"
              />
            </div>

            {/* ── Gráficos ─────────────────────────── */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <div className="bg-white rounded-xl shadow-sm p-6">
                <h3 className="text-sm font-semibold text-gray-700 mb-4">
                  Registro mensual de usuarios
                </h3>
                <ResponsiveContainer width="100%" height={260}>
                  <AreaChart data={datos.registroMensual}>
                    <defs>
                      <linearGradient id="colorEstudiantes" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#10B981" stopOpacity={0.4} />
                        <stop offset="95%" stopColor="#10B981" stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="colorPropietarios" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="#059669" stopOpacity={0.3} />
                        <stop offset="95%" stopColor="#059669" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
                    <XAxis dataKey="mes" tick={{ fontSize: 12, fill: '#6B7280' }} />
                    <YAxis tick={{ fontSize: 12, fill: '#6B7280' }} allowDecimals={false} />
                    <Tooltip />
                    <Legend wrapperStyle={{ fontSize: 12 }} />
                    <Area
                      type="monotone" dataKey="estudiantes" name="Estudiantes"
                      stroke="#10B981" fill="url(#colorEstudiantes)" strokeWidth={2}
                    />
                    <Area
                      type="monotone" dataKey="propietarios" name="Propietarios"
                      stroke="#059669" fill="url(#colorPropietarios)" strokeWidth={2}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              </div>

              <div className="bg-white rounded-xl shadow-sm p-6">
                <h3 className="text-sm font-semibold text-gray-700 mb-4">
                  Inmuebles por tipo
                </h3>
                <ResponsiveContainer width="100%" height={260}>
                  <BarChart data={datos.inmueblesPorTipo}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6" />
                    <XAxis dataKey="tipo" tick={{ fontSize: 12, fill: '#6B7280' }} />
                    <YAxis tick={{ fontSize: 12, fill: '#6B7280' }} allowDecimals={false} />
                    <Tooltip />
                    <Bar dataKey="cantidad" fill="#10B981" radius={[8, 8, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* ── Tablas rápidas ───────────────────── */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
              {/* Alertas de verificación */}
              <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-100">
                  <h3 className="text-sm font-semibold text-gray-700">
                    Alertas de verificación recientes
                  </h3>
                </div>
                {datos.ultimasVerificaciones.length === 0 ? (
                  <p className="text-center text-gray-400 text-sm py-8">
                    Sin verificaciones pendientes
                  </p>
                ) : (
                  <div className="divide-y divide-gray-100">
                    {datos.ultimasVerificaciones.map((v) => (
                      <div key={v.id} className="flex items-center justify-between px-6 py-3">
                        <div>
                          <p className="text-sm font-medium text-gray-800">{v.nombre}</p>
                          <p className="text-xs text-gray-400">{fechaCorta(v.actualizadoEn)}</p>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className="px-2 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700">
                            Pendiente
                          </span>
                          <button
                            onClick={() => navigate('/usuarios')}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition"
                          >
                            Revisar
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Últimas publicaciones */}
              <div className="bg-white rounded-xl shadow-sm overflow-hidden">
                <div className="px-6 py-4 border-b border-gray-100">
                  <h3 className="text-sm font-semibold text-gray-700">
                    Últimas publicaciones por aprobar
                  </h3>
                </div>
                {datos.ultimasPublicaciones.length === 0 ? (
                  <p className="text-center text-gray-400 text-sm py-8">
                    Sin publicaciones pendientes
                  </p>
                ) : (
                  <div className="divide-y divide-gray-100">
                    {datos.ultimasPublicaciones.map((p) => (
                      <div key={p.id} className="flex items-center justify-between px-6 py-3">
                        <div className="min-w-0">
                          <p className="text-sm font-medium text-gray-800 truncate">{p.titulo}</p>
                          <p className="text-xs text-gray-400">
                            {p.propietario?.nombre} — {fechaCorta(p.creadoEn)}
                          </p>
                        </div>
                        <button
                          onClick={() => navigate('/publicaciones')}
                          className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition flex-shrink-0 ml-3"
                        >
                          Revisar
                        </button>
                        </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* ── Reporte general ──────────────────── */}
            <div className="bg-white rounded-xl shadow-sm p-6 flex flex-col sm:flex-row sm:items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-emerald-50 flex items-center justify-center flex-shrink-0">
                <FileText size={22} className="text-emerald-600" />
              </div>
              <div className="flex-1">
                <h3 className="text-base font-bold text-gray-800">
                  Reporte general del sistema
                </h3>
                <p className="text-sm text-gray-500 mt-0.5">
                  Resumen consolidado de usuarios, publicaciones, actividad y moderación.
                </p>
              </div>
              <button
                onClick={exportarGeneral}
                className="flex items-center justify-center gap-2 px-5 py-2.5 rounded-xl text-sm font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition flex-shrink-0"
              >
                <FileDown size={15} />
                Descargar PDF
              </button>
            </div>
          </>
        )}
      </div>
    </Layout>
  )
}