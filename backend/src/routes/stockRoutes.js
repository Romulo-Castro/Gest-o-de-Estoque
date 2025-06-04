// src/routes/stockRoutes.js
const express = require('express');
const stockController = require('../controllers/stockController');
const upload = require('../middleware/uploadMiddleware');
const { validateStockItem, validateIdParam, handleValidationErrors } = require('../middleware/validators');
// Autenticação e acesso à loja já foram verificados pelo storeRoutes

const router = express.Router({ mergeParams: true }); // ESSENCIAL para pegar :storeId

// GET /api/stores/:storeId/stock - Obter todos
router.get('/', stockController.getAllStockItems);

// POST /api/stores/:storeId/stock - Criar novo
router.post('/',
    validateStockItem(), // Valida corpo
    handleValidationErrors,
    stockController.createStockItem
);

// GET /api/stores/:storeId/stock/:itemId - Obter por ID
router.get('/:itemId',
    validateIdParam('itemId'), // Valida parâmetro itemId
    handleValidationErrors,
    stockController.getStockItemById // Implementado no controller agora
);

// PUT /api/stores/:storeId/stock/:itemId - Atualizar
router.put('/:itemId',
    validateIdParam('itemId'),
    validateStockItem(), // Valida corpo
    handleValidationErrors,
    stockController.updateStockItem
);

// DELETE /api/stores/:storeId/stock/:itemId - Deletar
router.delete('/:itemId',
    validateIdParam('itemId'),
    handleValidationErrors,
    stockController.deleteStockItem
);

// POST /api/stores/:storeId/stock/:itemId/image - Upload
router.post('/:itemId/image',
    validateIdParam('itemId'),
    handleValidationErrors, // Valida ID antes de tentar upload
    upload.single('productImage'), // Processa upload
    stockController.uploadStockItemImage // Associa ao item
);

module.exports = router;