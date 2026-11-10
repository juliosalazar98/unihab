import { Navigate } from 'react-router-dom'
import { useAuth } from '../context/useAuth'


export default function ProtectedRoute({ children }) {
  const { token, usuario } = useAuth()
  console.log('TOKEN:', token)
console.log('USUARIO:', usuario)


  if (!token || usuario?.rol !== 'ADMIN') {
    return <Navigate to="/login" replace />
  }

  return children
}