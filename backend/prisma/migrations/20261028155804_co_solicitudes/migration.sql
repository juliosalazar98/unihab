-- CreateEnum
CREATE TYPE "EstadoCoSolicitud" AS ENUM ('PENDIENTE', 'ACEPTADA', 'RECHAZADA');

-- AlterTable
ALTER TABLE "Solicitud" ADD COLUMN     "coSolicitudId" INTEGER;

-- CreateTable
CREATE TABLE "co_solicitudes" (
    "id" SERIAL NOT NULL,
    "remitenteId" INTEGER NOT NULL,
    "receptorId" INTEGER NOT NULL,
    "inmuebleId" INTEGER NOT NULL,
    "estado" "EstadoCoSolicitud" NOT NULL DEFAULT 'PENDIENTE',
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "actualizadoEn" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "co_solicitudes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "co_solicitudes_remitenteId_receptorId_inmuebleId_key" ON "co_solicitudes"("remitenteId", "receptorId", "inmuebleId");

-- AddForeignKey
ALTER TABLE "co_solicitudes" ADD CONSTRAINT "co_solicitudes_remitenteId_fkey" FOREIGN KEY ("remitenteId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "co_solicitudes" ADD CONSTRAINT "co_solicitudes_receptorId_fkey" FOREIGN KEY ("receptorId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "co_solicitudes" ADD CONSTRAINT "co_solicitudes_inmuebleId_fkey" FOREIGN KEY ("inmuebleId") REFERENCES "inmuebles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
