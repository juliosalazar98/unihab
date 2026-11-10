-- DropForeignKey
ALTER TABLE "inmuebles" DROP CONSTRAINT "inmuebles_propietarioId_fkey";

-- DropForeignKey
ALTER TABLE "reportes" DROP CONSTRAINT "reportes_reportanteId_fkey";

-- AlterTable
ALTER TABLE "reportes" ALTER COLUMN "reportanteId" DROP NOT NULL;

-- AddForeignKey
ALTER TABLE "inmuebles" ADD CONSTRAINT "inmuebles_propietarioId_fkey" FOREIGN KEY ("propietarioId") REFERENCES "usuarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "reportes" ADD CONSTRAINT "reportes_reportanteId_fkey" FOREIGN KEY ("reportanteId") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;
