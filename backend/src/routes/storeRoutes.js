// src/routes/storeRoutes.js
const express = require('express');
const storeController = require('../controllers/storeController'); // Assumindo que você criará este
const stockRoutes = require('./stockRoutes'); // Importa as rotas de estoque para aninhar
const { authenticateToken } = require('../middleware/authMiddleware'); // Middleware de autenticação
// const { validateStore, handleValidationErrors } = require('../middleware/validators'); // Validador para loja

const router = express.Router();

// --- Proteger todas as rotas de loja com autenticação ---
router.use(authenticateToken);

// === Rotas para Lojas (Stores) ===

// GET /api/stores - Listar lojas do usuário logado
router.get('/', storeController.getUserStores);

// POST /api/stores - Criar uma nova loja
router.post('/',
    // validateStore(),
    // handleValidationErrors,
    storeController.createStore
);

// GET /api/stores/:storeId - Obter detalhes de uma loja específica (verifica acesso)
router.get('/:storeId',
    storeController.checkStoreAccessMiddleware, // Middleware específico do controller para checar acesso
    storeController.getStoreById
);

// PUT /api/stores/:storeId - Atualizar uma loja (verifica acesso)
router.put('/:storeId',
    storeController.checkStoreAccessMiddleware,
    // validateStore(),
    // handleValidationErrors,
    storeController.updateStore
);

// DELETE /api/stores/:storeId - Deletar uma loja (verifica acesso, cuidado!)
router.delete('/:storeId',
    storeController.checkStoreAccessMiddleware,
    storeController.deleteStore
);

// (Opcional) Rotas para adicionar/remover usuários de uma loja
// POST /api/stores/:storeId/users
// DELETE /api/stores/:storeId/users/:userId

// === Aninhamento das Rotas de Estoque ===
// Monta o stockRoutes no caminho /api/stores/:storeId/stock
// O middleware `checkStoreAccessMiddleware` já foi aplicado acima e garante
// que o usuário tem acesso à :storeId antes de chegar nas rotas de estoque.
// O `mergeParams: true` em stockRoutes permitirá que ele acesse :storeId.
router.use('/:storeId/stock', stockRoutes);


// === Aninhamento de OUTRAS Rotas (Clientes, Fornecedores, Documentos, etc.) ===
// Siga o mesmo padrão para outros recursos relacionados a uma loja específica
// Exemplo:
// const customerRoutes = require('./customerRoutes');
// router.use('/:storeId/customers', customerRoutes);

// const documentRoutes = require('./documentRoutes');
// router.use('/:storeId/documents', documentRoutes);


module.exports = router;