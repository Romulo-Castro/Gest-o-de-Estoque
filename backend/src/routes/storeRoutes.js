// src/routes/storeRoutes.js
const express = require("express");
const storeController = require("../controllers/storeController");
const stockRoutes = require("./stockRoutes");
const itemGroupRoutes = require("./itemGroupRoutes");
const customerRoutes = require("./customerRoutes");
const supplierRoutes = require("./supplierRoutes");
const documentRoutes = require("./documentRoutes"); // Importa as rotas de documentos
const { authenticateToken } = require("../middleware/authMiddleware");
// const { validateStore, handleValidationErrors } = require(\'../middleware/validators\');

const router = express.Router();

// --- Proteger todas as rotas de loja com autenticação ---
router.use(authenticateToken);

// === Rotas para Lojas (Stores) ===
router.get("/", storeController.getUserStores);
router.post(
  "/",
  // validateStore(),
  // handleValidationErrors,
  storeController.createStore
);

// --- Middleware para verificar acesso à loja específica (:storeId) ---
router.use("/:storeId", storeController.checkStoreAccessMiddleware);

// GET /api/stores/:storeId
router.get("/:storeId", storeController.getStoreById);

// PUT /api/stores/:storeId
router.put(
  "/:storeId",
  // validateStore(),
  // handleValidationErrors,
  storeController.updateStore
);

// DELETE /api/stores/:storeId
router.delete("/:storeId", storeController.deleteStore);

// === Aninhamento das Rotas de Estoque ===
router.use("/:storeId/stock", stockRoutes);

// === Aninhamento das Rotas de Grupos de Itens ===
router.use("/:storeId/groups", itemGroupRoutes);

// === Aninhamento das Rotas de Clientes ===
router.use("/:storeId/customers", customerRoutes);

// === Aninhamento das Rotas de Fornecedores ===
router.use("/:storeId/suppliers", supplierRoutes);

// === Aninhamento das Rotas de Documentos ===
router.use("/:storeId/documents", documentRoutes);


module.exports = router;
