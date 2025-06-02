// src/controllers/storeController.js
const db = require('../data/database');

// Middleware para verificar acesso (re-exportado ou usado aqui)
// É mais comum colocar no middleware/authMiddleware.js, mas pode ficar aqui se for só para lojas.
exports.checkStoreAccessMiddleware = async (req, res, next) => {
     try {
        const storeId = parseInt(req.params.storeId, 10);
        const userId = req.user?.userId;
        if (isNaN(storeId)) return res.status(400).json({ message: 'ID da loja inválido.' });
        if (!userId) return res.status(401).json({ message: 'Usuário não autenticado.' });

        const roleInfo = await db.findUserStoreRoleDB(userId, storeId);
        if (!roleInfo) return res.status(403).json({ message: 'Acesso negado a esta loja.' });

        req.userStoreRole = roleInfo.role; // Adiciona role para uso futuro
        next();
    } catch (error) { next(error); }
};


// GET /api/stores - Listar lojas do usuário
exports.getUserStores = async (req, res, next) => {
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ message: 'Usuário não autenticado.' });
    try {
        const stores = await db.findStoresByUserIdDB(userId);
        res.status(200).json(stores);
    } catch (error) { next(error); }
};

// POST /api/stores - Criar nova loja
exports.createStore = async (req, res, next) => {
     const userId = req.user?.userId;
     if (!userId) return res.status(401).json({ message: 'Usuário não autenticado.' });
    const { name, address } = req.body;
     if (!name) return res.status(400).json({ message: 'Nome da loja é obrigatório.'}); // Validação básica

    // Usar transação se precisar garantir ambas inserções
    // const transaction = await db.beginTransaction(); // Precisa implementar beginTransaction no database.js
    try {
        const storeResult = await db.createStoreDB({ name, address });
        const storeId = storeResult.lastID;

        // Adiciona o criador como 'owner' da loja
        await db.addUserToStoreDB({ userId, storeId, role: 'owner' });

        // await db.commitTransaction(transaction); // Se usar transação

        const newStore = await db.findStoreByIdDB(storeId); // Busca para retornar
        res.status(201).json(newStore);

    } catch (error) {
        // await db.rollbackTransaction(transaction); // Se usar transação
        next(error);
    }
};

// GET /api/stores/:storeId - Obter detalhes (acesso já verificado pelo middleware)
exports.getStoreById = async (req, res, next) => {
    try {
        const storeId = parseInt(req.params.storeId, 10); // ID já validado implicitamente pelo middleware
        const store = await db.findStoreByIdDB(storeId);
        if (!store) return res.status(404).json({ message: 'Loja não encontrada.' }); // Segurança extra
        res.status(200).json(store);
    } catch (error) { next(error); }
};

// PUT /api/stores/:storeId - Atualizar loja (acesso já verificado)
exports.updateStore = async (req, res, next) => {
     try {
         const storeId = parseInt(req.params.storeId, 10);
         const { name, address } = req.body;
         // Adicionar verificação se é owner/manager para permitir update?
         // if (req.userStoreRole !== 'owner' && req.userStoreRole !== 'manager') {
         //    return res.status(403).json({ message: 'Permissão insuficiente para editar loja.' });
         // }
          if (!name) return res.status(400).json({ message: 'Nome da loja é obrigatório.'});

         const result = await db.updateStoreDB(storeId, { name, address });
         if (result.changes === 0) return res.status(404).json({ message: 'Loja não encontrada ou nenhum dado alterado.'});

         const updatedStore = await db.findStoreByIdDB(storeId);
         res.status(200).json(updatedStore);
     } catch (error) { next(error); }
};

// DELETE /api/stores/:storeId - Deletar loja (acesso já verificado)
exports.deleteStore = async (req, res, next) => {
     try {
         const storeId = parseInt(req.params.storeId, 10);
         // APENAS OWNER PODE DELETAR?
          if (req.userStoreRole !== 'owner') {
             return res.status(403).json({ message: 'Apenas o proprietário pode excluir a loja.' });
          }

         // CUIDADO: ON DELETE CASCADE removerá tudo relacionado!
         const result = await db.deleteStoreDB(storeId);
         if (result.changes === 0) return res.status(404).json({ message: 'Loja não encontrada.'});

         res.status(200).json({ message: 'Loja e todos os seus dados foram excluídos com sucesso.'}); // Ou 204 No Content
     } catch (error) { next(error); }
};