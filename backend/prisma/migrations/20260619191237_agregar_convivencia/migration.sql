/*
  Warnings:

  - You are about to drop the column `activo` on the `perfiles_convivencia` table. All the data in the column will be lost.
  - You are about to drop the column `descripcion` on the `perfiles_convivencia` table. All the data in the column will be lost.
  - You are about to drop the column `presupuesto` on the `perfiles_convivencia` table. All the data in the column will be lost.
  - You are about to drop the column `zona` on the `perfiles_convivencia` table. All the data in the column will be lost.
  - Added the required column `aceptaMascotas` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `actualizadoEn` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ambienteEstudio` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `cronotipo` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `descripcionSobreMi` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `fumaTabaco` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `nivelOrden` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.
  - Added the required column `politicaVisitas` to the `perfiles_convivencia` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "OpcionConvivencia" AS ENUM ('SI', 'NO_TOLERO', 'INDIFERENTE');

-- CreateEnum
CREATE TYPE "Cronotipo" AS ENUM ('DIURNO', 'NOCTURNO');

-- CreateEnum
CREATE TYPE "AmbienteEstudio" AS ENUM ('SILENCIO', 'ACTIVO');

-- CreateEnum
CREATE TYPE "PoliticaVisitas" AS ENUM ('FRECUENTE', 'MODERADO', 'RESTRINGIDO');

-- CreateEnum
CREATE TYPE "NivelOrden" AS ENUM ('RIGUROSO', 'RELAJADO');

-- DropForeignKey
ALTER TABLE "perfiles_convivencia" DROP CONSTRAINT "perfiles_convivencia_usuarioId_fkey";

-- AlterTable
ALTER TABLE "perfiles_convivencia" DROP COLUMN "activo",
DROP COLUMN "descripcion",
DROP COLUMN "presupuesto",
DROP COLUMN "zona",
ADD COLUMN     "aceptaMascotas" "OpcionConvivencia" NOT NULL,
ADD COLUMN     "actualizadoEn" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "ambienteEstudio" "AmbienteEstudio" NOT NULL,
ADD COLUMN     "cronotipo" "Cronotipo" NOT NULL,
ADD COLUMN     "descripcionSobreMi" TEXT NOT NULL,
ADD COLUMN     "fumaTabaco" "OpcionConvivencia" NOT NULL,
ADD COLUMN     "nivelOrden" "NivelOrden" NOT NULL,
ADD COLUMN     "politicaVisitas" "PoliticaVisitas" NOT NULL;

-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "fotoPerfil" TEXT;

-- AddForeignKey
ALTER TABLE "perfiles_convivencia" ADD CONSTRAINT "perfiles_convivencia_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
