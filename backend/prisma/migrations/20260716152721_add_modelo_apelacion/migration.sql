/*
  Warnings:

  - You are about to drop the column `apelacion` on the `inmuebles` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "inmuebles" DROP COLUMN "apelacion",
ADD COLUMN     "enApelacion" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "apelaciones" (
    "id" SERIAL NOT NULL,
    "reporteId" INTEGER NOT NULL,
    "inmuebleId" INTEGER NOT NULL,
    "texto" TEXT NOT NULL,
    "imagenes" JSONB,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "apelaciones_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "apelaciones_reporteId_key" ON "apelaciones"("reporteId");

-- CreateIndex
CREATE UNIQUE INDEX "apelaciones_inmuebleId_key" ON "apelaciones"("inmuebleId");

-- AddForeignKey
ALTER TABLE "apelaciones" ADD CONSTRAINT "apelaciones_reporteId_fkey" FOREIGN KEY ("reporteId") REFERENCES "reportes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "apelaciones" ADD CONSTRAINT "apelaciones_inmuebleId_fkey" FOREIGN KEY ("inmuebleId") REFERENCES "inmuebles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
