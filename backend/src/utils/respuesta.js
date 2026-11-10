const ok = (res, datos, mensaje = 'OK', codigo = 200) => {
    return res.status(codigo).json({ ok: true, mensaje, datos })
  }
  
  const error = (res, mensaje = 'Error del servidor', codigo = 500) => {
    return res.status(codigo).json({ ok: false, mensaje })
  }
  
  module.exports = { ok, error }