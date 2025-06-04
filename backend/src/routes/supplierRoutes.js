// src/routes/supplierRoutes.js
const express = require("express");
const supplierController = require("../controllers/supplierController");
// const { validateSupplier, handleValidationErrors } = require("../middleware/validators"); // TODO: Criar validações se necessário

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Fornecedores dentro de uma Loja
router.get("/", supplierController.getAllSuppliers);
router.post("/", /* validateSupplier(), handleValidationErrors, */ supplierController.createSupplier);
router.get("/:supplierId", supplierController.getSupplierById);
router.put("/:supplierId", /* validateSupplier(), handleValidationErrors, */ supplierController.updateSupplier);
router.delete("/:supplierId", supplierController.deleteSupplier);

module.exports = router;

