-- CreateEnum
CREATE TYPE "EstadoSolicitud" AS ENUM ('PENDIENTE', 'ATENDIDA', 'RECHAZADA');

-- AlterTable
ALTER TABLE "Solicitud" ADD COLUMN     "estado" "EstadoSolicitud" NOT NULL DEFAULT 'PENDIENTE';
