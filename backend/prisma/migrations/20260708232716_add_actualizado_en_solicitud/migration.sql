/*
  Warnings:

  - Added the required column `actualizadoEn` to the `Solicitud` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
-- AlterTable
ALTER TABLE "Solicitud" ADD COLUMN "actualizadoEn" TIMESTAMP(3);

-- Backfill: usar creadoEn como valor inicial para filas existentes
UPDATE "Solicitud" SET "actualizadoEn" = "creadoEn" WHERE "actualizadoEn" IS NULL;

-- Ahora sí, hacer la columna obligatoria
ALTER TABLE "Solicitud" ALTER COLUMN "actualizadoEn" SET NOT NULL;
