-- CreateEnum
CREATE TYPE "TipoPunto" AS ENUM ('UNIVERSIDAD', 'INSTITUTO', 'GENERAL');

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "puntoInteresId" INTEGER;

-- CreateTable
CREATE TABLE "PuntoInteres" (
    "id" SERIAL NOT NULL,
    "nombre" TEXT NOT NULL,
    "tipo" "TipoPunto" NOT NULL,
    "latitud" DOUBLE PRECISION NOT NULL,
    "longitud" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "PuntoInteres_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_puntoInteresId_fkey" FOREIGN KEY ("puntoInteresId") REFERENCES "PuntoInteres"("id") ON DELETE SET NULL ON UPDATE CASCADE;
