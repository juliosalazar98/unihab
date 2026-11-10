import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import Layout from '../components/Layout'
import api from '../services/api'
import { useAuth } from '../context/useAuth'
import toast from 'react-hot-toast'
import { Camera, Trash2, User, Lock, Eye, EyeOff } from 'lucide-react'

export default function Perfil() {
    const { usuario, actualizarUsuario, logout } = useAuth()
    const navigate = useNavigate()
    const [perfil, setPerfil] = useState(usuario)
  const [cargando, setCargando] = useState(true)
  const [subiendoFoto, setSubiendoFoto] = useState(false)
  const [eliminandoFoto, setEliminandoFoto] = useState(false)
  const [mostrarConfirmar, setMostrarConfirmar] = useState(false)
  const inputRef = useRef(null)

  const [passwordActual, setPasswordActual] = useState('')
  const [passwordNueva, setPasswordNueva] = useState('')
  const [passwordConfirmar, setPasswordConfirmar] = useState('')
  const [verPasswords, setVerPasswords] = useState(false)
  const [cambiandoPassword, setCambiandoPassword] = useState(false)

  useEffect(() => {
    let cancelado = false
    const cargar = async () => {
      try {
        const res = await api.get('/auth/perfil')
        if (!cancelado) {
          setPerfil(res.data.datos)
          actualizarUsuario(res.data.datos)
        }
      } catch {
        if (!cancelado) toast.error('Error al cargar el perfil')
      } finally {
        if (!cancelado) setCargando(false)
      }
    }
    cargar()
    return () => { cancelado = true }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const handleSeleccionarFoto = () => {
    if (subiendoFoto || eliminandoFoto) return
    inputRef.current?.click()
  }

  const handleArchivoSeleccionado = async (e) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return

    setSubiendoFoto(true)
    try {
      const formData = new FormData()
      formData.append('foto', file)
      const res = await api.patch('/auth/foto-perfil', formData)
      setPerfil(res.data.datos)
      actualizarUsuario(res.data.datos)
      toast.success('Foto de perfil actualizada')
    } catch {
      toast.error('Error al subir la foto')
    } finally {
      setSubiendoFoto(false)
    }
  }

  const handleEliminarFoto = async () => {
    setMostrarConfirmar(false)
    setEliminandoFoto(true)
    try {
      const res = await api.delete('/auth/foto-perfil')
      setPerfil(res.data.datos)
      actualizarUsuario(res.data.datos)
      toast.success('Foto de perfil eliminada')
    } catch {
      toast.error('Error al quitar la foto')
    } finally {
      setEliminandoFoto(false)
    }
  }

  const handleCambiarPassword = async (e) => {
    e.preventDefault()

    if (!passwordActual || !passwordNueva || !passwordConfirmar) {
      toast.error('Completá todos los campos')
      return
    }
    if (passwordNueva.length < 6) {
      toast.error('La nueva contraseña debe tener al menos 6 caracteres')
      return
    }
    if (passwordNueva !== passwordConfirmar) {
      toast.error('Las contraseñas nuevas no coinciden')
      return
    }

    setCambiandoPassword(true)
    try {
      await api.patch('/auth/cambiar-password', { passwordActual, passwordNueva })
      toast.success('Contraseña actualizada. Iniciá sesión de nuevo.')
      logout()
      navigate('/login')
    } catch (err) {
      toast.error(err.response?.data?.mensaje || 'Error al cambiar la contraseña')
      setCambiandoPassword(false)
    }
  }

  if (cargando) {
    return (
      <Layout titulo="Mi Perfil">
        <div className="flex items-center justify-center py-20">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-emerald-600"></div>
        </div>
      </Layout>
    )
  }

  const nombre = perfil?.nombre || ''
  const email = perfil?.email || ''
  const foto = perfil?.fotoPerfil

  return (
    <Layout titulo="Mi Perfil">
      <div className="max-w-xl mx-auto space-y-6">
        <div className="bg-white rounded-xl shadow-sm p-8 flex flex-col items-center">
          <div className="relative">
            <div className="w-28 h-28 rounded-full overflow-hidden bg-emerald-50 flex items-center justify-center border-4 border-white shadow">
              {foto ? (
                <img src={foto} alt="Foto de perfil" className="w-full h-full object-cover" />
              ) : (
                <span className="text-4xl font-bold text-emerald-600">
                  {nombre ? nombre[0].toUpperCase() : <User size={40} />}
                </span>
              )}
            </div>

            {(subiendoFoto || eliminandoFoto) && (
              <div className="absolute inset-0 rounded-full bg-black/30 flex items-center justify-center">
                <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white"></div>
              </div>
            )}

            {!subiendoFoto && !eliminandoFoto && (
              <button
                onClick={handleSeleccionarFoto}
                className="absolute bottom-0 right-0 w-9 h-9 bg-emerald-600 rounded-full flex items-center justify-center text-white shadow hover:bg-emerald-700 transition"
                title="Cambiar foto"
              >
                <Camera size={16} />
              </button>
            )}
          </div>

          <input
            ref={inputRef}
            type="file"
            accept="image/png, image/jpeg, image/webp"
            className="hidden"
            onChange={handleArchivoSeleccionado}
          />

          <div className="flex gap-3 mt-4">
            <button
              onClick={handleSeleccionarFoto}
              disabled={subiendoFoto || eliminandoFoto}
              className="px-4 py-2 rounded-lg text-sm font-semibold bg-emerald-50 text-emerald-700 hover:bg-emerald-100 transition disabled:opacity-50"
            >
              Cambiar foto
            </button>
            {foto && (
              <button
                onClick={() => setMostrarConfirmar(true)}
                disabled={subiendoFoto || eliminandoFoto}
                className="px-4 py-2 rounded-lg text-sm font-semibold bg-red-50 text-red-600 hover:bg-red-100 transition disabled:opacity-50 flex items-center gap-1.5"
              >
                <Trash2 size={14} />
                Quitar foto
              </button>
            )}
          </div>

          <h2 className="text-lg font-bold text-gray-800 mt-5">{nombre}</h2>
          <p className="text-sm text-gray-500">{email}</p>
          <span className="mt-2 px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-600">
            ADMIN
          </span>
        </div>

        <div className="bg-white rounded-xl shadow-sm p-8">
          <div className="flex items-center gap-2 mb-1">
            <Lock size={16} className="text-gray-500" />
            <h3 className="text-base font-bold text-gray-800">Cambiar contraseña</h3>
          </div>
          <p className="text-sm text-gray-500 mb-6">
            Usá una contraseña de al menos 6 caracteres.
          </p>

          <form onSubmit={handleCambiarPassword} className="space-y-4">
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                Contraseña actual
              </label>
              <input
                type={verPasswords ? 'text' : 'password'}
                value={passwordActual}
                onChange={(e) => setPasswordActual(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                autoComplete="current-password"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                Nueva contraseña
              </label>
              <input
                type={verPasswords ? 'text' : 'password'}
                value={passwordNueva}
                onChange={(e) => setPasswordNueva(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                autoComplete="new-password"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5">
                Confirmar nueva contraseña
              </label>
              <input
                type={verPasswords ? 'text' : 'password'}
                value={passwordConfirmar}
                onChange={(e) => setPasswordConfirmar(e.target.value)}
                className="w-full px-3 py-2.5 rounded-lg border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                autoComplete="new-password"
              />
            </div>

            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={() => setVerPasswords(!verPasswords)}
                className="flex items-center gap-1.5 text-xs font-medium text-gray-500 hover:text-gray-700 transition"
              >
                {verPasswords ? <EyeOff size={14} /> : <Eye size={14} />}
                {verPasswords ? 'Ocultar' : 'Mostrar'} contraseñas
              </button>

              <button
                type="submit"
                disabled={cambiandoPassword}
                className="px-5 py-2.5 rounded-lg text-sm font-semibold bg-emerald-600 text-white hover:bg-emerald-700 transition disabled:opacity-50"
              >
                {cambiandoPassword ? 'Guardando...' : 'Actualizar contraseña'}
              </button>
            </div>
          </form>
        </div>
      </div>

      {mostrarConfirmar && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-sm w-full p-6">
            <h3 className="text-base font-bold text-gray-800 mb-2">Quitar foto</h3>
            <p className="text-sm text-gray-500 mb-6">
              ¿Seguro que querés quitar tu foto de perfil?
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setMostrarConfirmar(false)}
                className="px-4 py-2 rounded-lg text-sm font-semibold text-gray-600 hover:bg-gray-100 transition"
              >
                Cancelar
              </button>
              <button
                onClick={handleEliminarFoto}
                className="px-4 py-2 rounded-lg text-sm font-semibold bg-red-600 text-white hover:bg-red-700 transition"
              >
                Quitar
              </button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  )
}