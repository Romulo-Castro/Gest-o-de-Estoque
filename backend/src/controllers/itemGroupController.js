// src/controllers/itemGroupController.js
const db = require('../data/database');

// GET /api/stores/:storeId/groups - Listar grupos da loja
exports.getAllGroups = async (req, res, next) => {
    // Acesso à loja já verificado pelo middleware em storeRoutes
    const storeId = parseInt(req.params.storeId, 10);
    try {
        const groups = await db.findGroupsByStore(storeId);
        res.status(200).json(groups);
    } catch (error) {
        console.error(`[GroupCtrl] Erro em getAllGroups para loja ${storeId}:`, error);
        next(error);
    }
};

// GET /api/stores/:storeId/groups/:groupId - Obter grupo por ID
exports.getGroupById = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const groupId = parseInt(req.params.groupId, 10);
    if (isNaN(groupId)) return res.status(400).json({ message: 'ID do grupo inválido.' });

    try {
        const group = await db.findGroupByIdAndStore(groupId, storeId);
        if (!group) {
            return res.status(404).json({ message: 'Grupo não encontrado nesta loja.' });
        }
        res.status(200).json(group);
    } catch (error) {
        console.error(`[GroupCtrl] Erro em getGroupById (Grupo: ${groupId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// POST /api/stores/:storeId/groups - Criar novo grupo
exports.createGroup = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const { name, parent_group_id } = req.body;

    if (!name || name.trim() === '') {
        return res.status(400).json({ message: 'Nome do grupo é obrigatório.' });
    }

    // TODO: Validar se parent_group_id (se fornecido) pertence à mesma storeId?

    try {
        const result = await db.createGroupInStore({
            storeId,
            name: name.trim(),
            parentGroupId: parent_group_id ? parseInt(parent_group_id, 10) : null
        });
        const newGroup = await db.findGroupByIdAndStore(result.lastID, storeId);
        res.status(201).json(newGroup);
    } catch (error) {
        console.error(`[GroupCtrl] Erro em createGroup para loja ${storeId}:`, error);
        // Tratar erro de constraint se parent_group_id for inválido?
        next(error);
    }
};

// PUT /api/stores/:storeId/groups/:groupId - Atualizar grupo
exports.updateGroup = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const groupId = parseInt(req.params.groupId, 10);
    const { name, parent_group_id } = req.body;

    if (isNaN(groupId)) return res.status(400).json({ message: 'ID do grupo inválido.' });
    if (!name || name.trim() === '') {
        return res.status(400).json({ message: 'Nome do grupo é obrigatório.' });
    }
    // TODO: Validar se parent_group_id (se fornecido) pertence à mesma storeId e não cria ciclo?

    try {
        const existingGroup = await db.findGroupByIdAndStore(groupId, storeId);
        if (!existingGroup) {
            return res.status(404).json({ message: 'Grupo não encontrado nesta loja.' });
        }

        const result = await db.updateGroupDetails(groupId, storeId, {
            name: name.trim(),
            parentGroupId: parent_group_id !== undefined ? (parent_group_id ? parseInt(parent_group_id, 10) : null) : existingGroup.parent_group_id
        });

        if (result.changes === 0) {
            // Pode acontecer se os dados forem os mesmos
            return res.status(304).end(); // Not Modified
        }

        const updatedGroup = await db.findGroupByIdAndStore(groupId, storeId);
        res.status(200).json(updatedGroup);
    } catch (error) {
        console.error(`[GroupCtrl] Erro em updateGroup (Grupo: ${groupId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// DELETE /api/stores/:storeId/groups/:groupId - Deletar grupo
exports.deleteGroup = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const groupId = parseInt(req.params.groupId, 10);
    if (isNaN(groupId)) return res.status(400).json({ message: 'ID do grupo inválido.' });

    try {
        // Verificar se o grupo existe antes de deletar
        const existingGroup = await db.findGroupByIdAndStore(groupId, storeId);
        if (!existingGroup) {
            return res.status(404).json({ message: 'Grupo não encontrado nesta loja.' });
        }

        // A constraint ON DELETE SET NULL cuidará dos itens e subgrupos
        const result = await db.deleteGroupFromStore(groupId, storeId);

        if (result.changes > 0) {
            res.status(200).json({ message: 'Grupo excluído com sucesso.' });
        } else {
            // Deveria ter sido encontrado acima, mas como segurança
            res.status(404).json({ message: 'Grupo não encontrado.' });
        }
    } catch (error) {
        console.error(`[GroupCtrl] Erro em deleteGroup (Grupo: ${groupId}, Loja: ${storeId}):`, error);
        // TODO: Tratar erro se houver alguma constraint inesperada
        next(error);
    }
};

