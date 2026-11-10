import { NavLink, Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'
import toast from 'react-hot-toast'
import {
  LayoutDashboard,
  Home,
  Users,
  Flag,
  LogOut,
  Menu,
  X
} from 'lucide-react'
import { useState } from 'react'

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/publicaciones', icon: Home, label: 'Publicaciones' },
  { to: '/usuarios', icon: Users, label: 'Usuarios' },
  { to: '/reportes', icon: Flag, label: 'Reportes' },
]
export default function Sidebar() {
  const { usuario, logout } = useAuth()
  const navigate = useNavigate()
  const [abierto, setAbierto] = useState(false)

  const handleLogout = () => {
    logout()
    toast.success('Sesión cerrada')
    navigate('/login')
  }

  return (
    <>
      {/* Botón hamburguesa móvil */}
      <button
        onClick={() => setAbierto(!abierto)}
        className="lg:hidden fixed top-4 left-4 z-50 p-2 bg-emerald-600 text-white rounded-xl shadow-lg"
      >
        {abierto ? <X size={20} /> : <Menu size={20} />}
      </button>

      {/* Overlay móvil */}
      {abierto && (
        <div
          className="lg:hidden fixed inset-0 bg-black/40 z-30"
          onClick={() => setAbierto(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed top-0 left-0 h-full w-64 bg-gray-900 text-white z-40
        flex flex-col transition-transform duration-300
        ${abierto ? 'translate-x-0' : '-translate-x-full'}
        lg:translate-x-0 lg:static lg:flex
      `}>

        {/* Logo */}
        <div className="p-6 border-b border-gray-700">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-emerald-600 rounded-xl flex items-center justify-center font-bold text-lg shadow">
              U
            </div>
            <div>
              <p className="font-bold text-white text-lg leading-none">UniHab</p>
              <p className="text-gray-400 text-xs">Panel Admin</p>
            </div>
          </div>
        </div>

        {/* Nav links */}
        <nav className="flex-1 p-4 space-y-1">
          {links.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={() => setAbierto(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-xl transition font-medium text-sm
                ${isActive
                  ? 'bg-emerald-600 text-white shadow'
                  : 'text-gray-400 hover:bg-gray-800 hover:text-white'
                }`
              }
            >
              <Icon size={18} />
              {label}
            </NavLink>
          ))}
        </nav>

        {/* Usuario y logout */}
                {/* Usuario y logout */}
                <div className="p-4 border-t border-gray-700">
          <Link
            to="/perfil"
            onClick={() => setAbierto(false)}
            className="flex items-center gap-3 px-4 py-3 mb-2 rounded-xl hover:bg-gray-800 transition"
          >
            <div className="w-8 h-8 rounded-full overflow-hidden bg-emerald-500 flex items-center justify-center text-sm font-bold flex-shrink-0">
              {usuario?.fotoPerfil ? (
                <img
                  src={usuario.fotoPerfil}
                  alt="Foto de perfil"
                  className="w-full h-full object-cover"
                />
              ) : (
                usuario?.nombre?.[0]?.toUpperCase()
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate">{usuario?.nombre}</p>
              <p className="text-gray-400 text-xs truncate">{usuario?.email}</p>
            </div>
          </Link>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-gray-400 hover:bg-red-900/30 hover:text-red-400 transition text-sm font-medium"
          >
            <LogOut size={18} />
            Cerrar sesión
          </button>
        </div>
      </aside>
    </>
  )
}