/*
  Warnings:

  - A unique constraint covering the columns `[nombre]` on the table `PuntoInteres` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "PuntoInteres_nombre_key" ON "PuntoInteres"("nombre");
