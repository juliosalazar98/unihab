export const getTokenInicial = () => localStorage.getItem('token')

export const getUsuarioInicial = () => {
  const u = localStorage.getItem('usuario')
  return u ? JSON.parse(u) : null
}