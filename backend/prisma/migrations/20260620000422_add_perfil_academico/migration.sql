-- CreateEnum
CREATE TYPE "Genero" AS ENUM ('MASCULINO', 'FEMENINO', 'OTRO');

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "carrera" TEXT,
ADD COLUMN     "ciudadOrigen" TEXT,
ADD COLUMN     "genero" "Genero";
