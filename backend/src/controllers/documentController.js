// src/controllers/documentController.js
const db = require("../data/database");

// GET /api/stores/:storeId/documents - Listar documentos da loja
exports.getAllDocuments = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    // TODO: Adicionar filtros (tipo, data, cliente/fornecedor) via query params
    try {
        const documents = await db.findDocumentsByStore(storeId);
        res.status(200).json(documents);
    } catch (error) {
        console.error(`[DocumentCtrl] Erro em getAllDocuments para loja ${storeId}:`, error);
        next(error);
    }
};

// GET /api/stores/:storeId/documents/:documentId - Obter documento por ID com itens
exports.getDocumentById = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const documentId = parseInt(req.params.documentId, 10);
    if (isNaN(documentId)) return res.status(400).json({ message: "ID do documento inválido." });

    try {
        const document = await db.findDocumentByIdAndStore(documentId, storeId);
        if (!document) {
            return res.status(404).json({ message: "Documento não encontrado nesta loja." });
        }
        const items = await db.findDocumentItemsByDocumentId(documentId);
        res.status(200).json({ ...document, items });
    } catch (error) {
        console.error(`[DocumentCtrl] Erro em getDocumentById (Doc: ${documentId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// POST /api/stores/:storeId/documents - Criar novo documento com itens
exports.createDocument = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const { type, document_date, customerId, supplierId, notes, items, total_amount } = req.body;

    // Validações básicas - aceita tipos em inglês conforme o banco de dados
    if (!["sale", "purchase", "adjustment_in", "adjustment_out"].includes(type)) {
        return res.status(400).json({ message: "Tipo de documento inválido. Use: sale, purchase, adjustment_in ou adjustment_out" });
    }
    if (!document_date) {
        return res.status(400).json({ message: "Data do documento é obrigatória." });
    }
    if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ message: "Documento deve ter pelo menos um item." });
    }
    // TODO: Validar estrutura dos itens (itemId, quantity, price)
    // TODO: Validar se customerId/supplierId existem na loja, se fornecidos

    try {
        await db.beginTransaction();

        // 1. Criar o cabeçalho do documento
        const docResult = await db.createDocumentHeader({
            storeId,
            type,
            date: document_date,
            customerId: customerId || null,
            supplierId: supplierId || null,
            notes: notes?.trim() || null,
            totalAmount: total_amount || 0
        });
        const documentId = docResult.lastID;

        // 2. Criar os itens do documento e ajustar estoque
        for (const item of items) {
            // Aceita tanto itemId quanto item_id para compatibilidade
            const itemId = item.itemId || item.item_id;
            const itemQuantity = item.quantity;
            
            if (!itemId || !itemQuantity || itemQuantity <= 0) {
                throw new Error("Item inválido no documento: ID e quantidade positiva são obrigatórios.");
            }
            // TODO: Validar se itemId existe na loja

            await db.createDocumentItem({
                documentId,
                itemId: item.itemId,
                quantity: item.quantity,
                unitPrice: item.unitPrice || 0, // Preço pode ser opcional dependendo do tipo
            });

            // Ajustar estoque
            const quantityChange = (type === "ENTRADA" || type === "AJUSTE_ENTRADA") ? item.quantity : -item.quantity;
            await db.updateStockQuantity(item.itemId, storeId, quantityChange);
            // TODO: Verificar se estoque ficou negativo se a regra de negócio exigir
        }

        await db.commitTransaction();

        // Retornar o documento criado com os itens
        const newDocument = await db.findDocumentByIdAndStore(documentId, storeId);
        const newItems = await db.findDocumentItemsByDocumentId(documentId);
        res.status(201).json({ ...newDocument, items: newItems });

    } catch (error) {
        await db.rollbackTransaction();
        console.error(`[DocumentCtrl] Erro em createDocument para loja ${storeId}:`, error);
        next(error);
    }
};

// PUT /api/stores/:storeId/documents/:documentId - Atualizar documento (cabeçalho apenas?)
// **NOTA:** Atualizar itens de um documento finalizado geralmente não é permitido.
// A edição pode ser limitada a campos como 'notes' ou status (se houver).
// Uma abordagem mais segura seria CANCELAR o documento e criar um novo.
// Por simplicidade, vamos permitir atualizar apenas 'notes', 'date', 'customerId', 'supplierId'.
exports.updateDocumentHeader = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const documentId = parseInt(req.params.documentId, 10);
    const { date, customerId, supplierId, notes } = req.body;

    if (isNaN(documentId)) return res.status(400).json({ message: "ID do documento inválido." });

    try {
        const existingDoc = await db.findDocumentByIdAndStore(documentId, storeId);
        if (!existingDoc) {
            return res.status(404).json({ message: "Documento não encontrado nesta loja." });
        }
        // TODO: Adicionar lógica para impedir edição se o documento estiver "fechado" ou "processado"

        const result = await db.updateDocumentHeaderDetails(documentId, storeId, {
            date: date || existingDoc.date, // Manter data se não fornecida
            customerId: customerId === undefined ? existingDoc.customer_id : customerId, // Permite setar para null
            supplierId: supplierId === undefined ? existingDoc.supplier_id : supplierId, // Permite setar para null
            notes: notes === undefined ? existingDoc.notes : notes?.trim() || null,
        });

        if (result.changes === 0) {
            return res.status(304).end(); // Not Modified
        }

        const updatedDocument = await db.findDocumentByIdAndStore(documentId, storeId);
        const items = await db.findDocumentItemsByDocumentId(documentId); // Itens não mudam aqui
        res.status(200).json({ ...updatedDocument, items });

    } catch (error) {
        console.error(`[DocumentCtrl] Erro em updateDocumentHeader (Doc: ${documentId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// DELETE /api/stores/:storeId/documents/:documentId - Deletar/Cancelar documento
// **NOTA:** A exclusão física pode ser perigosa. Uma abordagem melhor é "cancelar" o documento.
// Cancelar envolveria REVERTER os ajustes de estoque feitos pelo documento original.
exports.cancelDocument = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const documentId = parseInt(req.params.documentId, 10);
    if (isNaN(documentId)) return res.status(400).json({ message: "ID do documento inválido." });

    try {
        await db.beginTransaction();

        const document = await db.findDocumentByIdAndStore(documentId, storeId);
        if (!document) {
            await db.rollbackTransaction();
            return res.status(404).json({ message: "Documento não encontrado nesta loja." });
        }
        if (document.status === "CANCELADO") { // Assumindo um campo status
             await db.rollbackTransaction();
             return res.status(400).json({ message: "Documento já está cancelado." });
        }

        // 1. Buscar os itens do documento para saber o que reverter
        const items = await db.findDocumentItemsByDocumentId(documentId);

        // 2. Reverter os ajustes de estoque
        for (const item of items) {
            // A quantidade a reverter é o OPOSTO do ajuste original
            const quantityToReverse = (document.type === "ENTRADA" || document.type === "AJUSTE_ENTRADA") ? -item.quantity : item.quantity;
            await db.updateStockQuantity(item.item_id, storeId, quantityToReverse);
             // TODO: Verificar se estoque ficou negativo se a regra de negócio exigir
        }

        // 3. Marcar o documento como cancelado (ou deletar, se preferir - menos seguro)
        // await db.deleteDocumentAndItems(documentId, storeId); // Opção 1: Deletar
        await db.updateDocumentStatus(documentId, storeId, "CANCELADO"); // Opção 2: Marcar como cancelado

        await db.commitTransaction();

        // res.status(200).json({ message: "Documento excluído com sucesso." }); // Se deletou
        res.status(200).json({ message: "Documento cancelado com sucesso." }); // Se marcou

    } catch (error) {
        await db.rollbackTransaction();
        console.error(`[DocumentCtrl] Erro em cancelDocument (Doc: ${documentId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

