-- AlterTable
ALTER TABLE "usuarios" ADD COLUMN     "ciExtension" TEXT,
ADD COLUMN     "ciNumero" TEXT,
ADD COLUMN     "estadoVerificacion" TEXT NOT NULL DEFAULT 'NO_VERIFICADO',
ADD COLUMN     "fotoAnversoUrl" TEXT,
ADD COLUMN     "fotoReversoUrl" TEXT;
