-- CreateEnum
CREATE TYPE "TipoOferta" AS ENUM ('ALQUILER', 'ANTICRETICO');

-- AlterTable
ALTER TABLE "inmuebles" ADD COLUMN     "tipoOferta" "TipoOferta" NOT NULL DEFAULT 'ALQUILER';
