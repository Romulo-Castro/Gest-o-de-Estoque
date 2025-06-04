// src/routes/customerRoutes.js
const express = require("express");
const customerController = require("../controllers/customerController");
// const { validateCustomer, handleValidationErrors } = require("../middleware/validators"); // TODO: Criar validações se necessário

// Usar mergeParams para acessar :storeId da rota pai (storeRoutes)
const router = express.Router({ mergeParams: true });

// Middleware de autenticação e acesso à loja já aplicado em storeRoutes

// Rotas para Clientes dentro de uma Loja
router.get("/", customerController.getAllCustomers);
router.post("/", /* validateCustomer(), handleValidationErrors, */ customerController.createCustomer);
router.get("/:customerId", customerController.getCustomerById);
router.put("/:customerId", /* validateCustomer(), handleValidationErrors, */ customerController.updateCustomer);
router.delete("/:customerId", customerController.deleteCustomer);

module.exports = router;

