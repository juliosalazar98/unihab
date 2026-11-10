-- CreateTable
CREATE TABLE "listas_favoritos" (
    "id" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,
    "usuarioId" INTEGER NOT NULL,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "listas_favoritos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inmuebles_favoritos" (
    "id" SERIAL NOT NULL,
    "listaId" INTEGER NOT NULL,
    "inmuebleId" INTEGER NOT NULL,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inmuebles_favoritos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inmuebles_vistos" (
    "id" SERIAL NOT NULL,
    "usuarioId" INTEGER NOT NULL,
    "inmuebleId" INTEGER NOT NULL,
    "vistoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inmuebles_vistos_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "inmuebles_favoritos_listaId_inmuebleId_key" ON "inmuebles_favoritos"("listaId", "inmuebleId");

-- CreateIndex
CREATE UNIQUE INDEX "inmuebles_vistos_usuarioId_inmuebleId_key" ON "inmuebles_vistos"("usuarioId", "inmuebleId");

-- AddForeignKey
ALTER TABLE "listas_favoritos" ADD CONSTRAINT "listas_favoritos_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inmuebles_favoritos" ADD CONSTRAINT "inmuebles_favoritos_listaId_fkey" FOREIGN KEY ("listaId") REFERENCES "listas_favoritos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inmuebles_favoritos" ADD CONSTRAINT "inmuebles_favoritos_inmuebleId_fkey" FOREIGN KEY ("inmuebleId") REFERENCES "inmuebles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inmuebles_vistos" ADD CONSTRAINT "inmuebles_vistos_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inmuebles_vistos" ADD CONSTRAINT "inmuebles_vistos_inmuebleId_fkey" FOREIGN KEY ("inmuebleId") REFERENCES "inmuebles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
