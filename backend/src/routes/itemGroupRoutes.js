// src/routes/itemGroupRoutes.js
const express = require("express");
const itemGroupController = require("../controllers/itemGroupController");
const { validate } = require("../middleware/validators"); // Reutilizar se houver validações

// Usar mergeParams é crucial aqui porque este router será montado sob /stores/:storeId
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Grupos de Itens dentro de uma Loja
router.get("/", itemGroupController.getAllGroups);
router.post("/", /* TODO: Adicionar validação se necessário */ itemGroupController.createGroup);
router.get("/:groupId", itemGroupController.getGroupById);
router.put("/:groupId", /* TODO: Adicionar validação se necessário */ itemGroupController.updateGroup);
router.delete("/:groupId", itemGroupController.deleteGroup);

module.exports = router;

