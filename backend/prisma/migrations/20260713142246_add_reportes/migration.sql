-- CreateEnum
CREATE TYPE "EstadoReporte" AS ENUM ('PENDIENTE', 'RESUELTO');

-- CreateTable
CREATE TABLE "reportes" (
    "id" SERIAL NOT NULL,
    "inmuebleId" INTEGER NOT NULL,
    "reportanteId" INTEGER NOT NULL,
    "motivo" TEXT NOT NULL,
    "comentario" TEXT,
    "estado" "EstadoReporte" NOT NULL DEFAULT 'PENDIENTE',
    "sancionado" BOOLEAN NOT NULL DEFAULT false,
    "creadoEn" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resueltoEn" TIMESTAMP(3),

    CONSTRAINT "reportes_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_inmuebleId_fkey" FOREIGN KEY ("inmuebleId") REFERENCES "inmuebles"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_reportanteId_fkey" FOREIGN KEY ("reportanteId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;
