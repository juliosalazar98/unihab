-- AlterTable
ALTER TABLE "perfiles_convivencia" ADD COLUMN     "presupuestoMax" INTEGER,
ADD COLUMN     "presupuestoMin" INTEGER,
ADD COLUMN     "zonasPreferidas" TEXT[] DEFAULT ARRAY[]::TEXT[];
