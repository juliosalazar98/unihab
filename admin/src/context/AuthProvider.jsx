import { useState } from 'react'
import { AuthContext } from './AuthContext'
import { getTokenInicial, getUsuarioInicial } from './authHelpers'

export function AuthProvider({ children }) {
  const [usuario, setUsuario] = useState(getUsuarioInicial)
  const [token, setToken] = useState(getTokenInicial)

  const login = (tkn, usr) => {
    localStorage.setItem('token', tkn)
    localStorage.setItem('usuario', JSON.stringify(usr))
    setToken(tkn)
    setUsuario(usr)
  }

  const actualizarUsuario = (usr) => {
    localStorage.setItem('usuario', JSON.stringify(usr))
    setUsuario(usr)
  }

  const logout = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('usuario')
    setToken(null)
    setUsuario(null)
  }

  return (
    <AuthContext.Provider value={{ usuario, token, cargando: false, login, actualizarUsuario, logout }}>
      {children}
    </AuthContext.Provider>
  )
}