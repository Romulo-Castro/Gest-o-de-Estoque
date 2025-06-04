// src/routes/documentRoutes.js
const express = require("express");
const documentController = require("../controllers/documentController");
// const { validateDocument, handleValidationErrors } = require("../middleware/validators"); // TODO: Criar validações

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Documentos dentro de uma Loja
router.get("/", documentController.getAllDocuments);
router.post("/", /* validateDocument(), handleValidationErrors, */ documentController.createDocument);
router.get("/:documentId", documentController.getDocumentById);

// PUT - Atualizar cabeçalho (limitado)
router.put("/:documentId", /* validateDocumentHeaderUpdate(), handleValidationErrors, */ documentController.updateDocumentHeader);

// DELETE - Cancelar documento (reverte estoque)
router.delete("/:documentId", documentController.cancelDocument);

// TODO: Rotas específicas para itens de documento? Geralmente não são necessárias,
// pois os itens são gerenciados junto com o documento principal.
// Ex: POST /:documentId/items - Adicionar item (complexo, geralmente feito na criação)
// Ex: DELETE /:documentId/items/:itemId - Remover item (complexo, geralmente não permitido após criação)

module.exports = router;

