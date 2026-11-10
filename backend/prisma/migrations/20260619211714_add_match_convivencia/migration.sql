-- CreateEnum
CREATE TYPE "EstadoMatch" AS ENUM ('PENDIENTE', 'ACEPTADO', 'RECHAZADO');

-- CreateTable
CREATE TABLE "matches_convivencia" (
    "id" SERIAL NOT NULL,
    "solicitanteId" INTEGER NOT NULL,
    "receptorId" INTEGER NOT NULL,
    "estado" "EstadoMatch" NOT NULL DEFAULT 'PENDIENTE',
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "matches_convivencia_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "matches_convivencia_solicitanteId_receptorId_key" ON "matches_convivencia"("solicitanteId", "receptorId");

-- AddForeignKey
ALTER TABLE "matches_convivencia" ADD CONSTRAINT "matches_convivencia_solicitanteId_fkey" FOREIGN KEY ("solicitanteId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "matches_convivencia" ADD CONSTRAINT "matches_convivencia_receptorId_fkey" FOREIGN KEY ("receptorId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
