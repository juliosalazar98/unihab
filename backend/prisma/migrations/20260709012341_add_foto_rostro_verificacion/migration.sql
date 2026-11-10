/*
  Warnings:

  - You are about to drop the column `fotoSelfieUrl` on the `usuarios` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "usuarios" DROP COLUMN "fotoSelfieUrl",
ADD COLUMN     "fotoRostroUrl" TEXT;
