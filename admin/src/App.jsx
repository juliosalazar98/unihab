import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './context/useAuth'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Publicaciones from './pages/Publicaciones'
import Usuarios from './pages/Usuarios'
import Reportes from './pages/Reportes'

function RutaProtegida({ children }) {
  const { token } = useAuth()
  if (!token) return <Navigate to="/login" replace />
  return children
}

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/" element={
          <RutaProtegida><Dashboard /></RutaProtegida>
        } />
        <Route path="/publicaciones" element={
          <RutaProtegida><Publicaciones /></RutaProtegida>
        } />
        <Route path="/usuarios" element={
          <RutaProtegida><Usuarios /></RutaProtegida>
        } />
        <Route path="/reportes" element={
          <RutaProtegida><Reportes /></RutaProtegida>
        } />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

export default App