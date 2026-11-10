export default function Navbar({ titulo }) {
  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center px-6 shadow-sm">
      <h1 className="text-lg font-semibold text-gray-700 ml-10 lg:ml-0">
        {titulo}
      </h1>
    </header>
  )
}