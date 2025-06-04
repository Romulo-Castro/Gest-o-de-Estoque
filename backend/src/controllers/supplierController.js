// src/controllers/supplierController.js
const db = require("../data/database");

// GET /api/stores/:storeId/suppliers - Listar fornecedores da loja
exports.getAllSuppliers = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    try {
        const suppliers = await db.findSuppliersByStore(storeId);
        res.status(200).json(suppliers);
    } catch (error) {
        console.error(`[SupplierCtrl] Erro em getAllSuppliers para loja ${storeId}:`, error);
        next(error);
    }
};

// GET /api/stores/:storeId/suppliers/:supplierId - Obter fornecedor por ID
exports.getSupplierById = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const supplierId = parseInt(req.params.supplierId, 10);
    if (isNaN(supplierId)) return res.status(400).json({ message: "ID do fornecedor inválido." });

    try {
        const supplier = await db.findSupplierByIdAndStore(supplierId, storeId);
        if (!supplier) {
            return res.status(404).json({ message: "Fornecedor não encontrado nesta loja." });
        }
        res.status(200).json(supplier);
    } catch (error) {
        console.error(`[SupplierCtrl] Erro em getSupplierById (Fornecedor: ${supplierId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// POST /api/stores/:storeId/suppliers - Criar novo fornecedor
exports.createSupplier = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        return res.status(400).json({ message: "Nome do fornecedor é obrigatório." });
    }

    try {
        const result = await db.createSupplierInStore({
            storeId,
            name: name.trim(),
            email: email?.trim() || null,
            phone: phone?.trim() || null,
            address: address?.trim() || null,
            notes: notes?.trim() || null,
        });
        const newSupplier = await db.findSupplierByIdAndStore(result.lastID, storeId);
        res.status(201).json(newSupplier);
    } catch (error) {
        console.error(`[SupplierCtrl] Erro em createSupplier para loja ${storeId}:`, error);
        next(error);
    }
};

// PUT /api/stores/:storeId/suppliers/:supplierId - Atualizar fornecedor
exports.updateSupplier = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const supplierId = parseInt(req.params.supplierId, 10);
    const { name, email, phone, address, notes } = req.body;

    if (isNaN(supplierId)) return res.status(400).json({ message: "ID do fornecedor inválido." });
    if (!name || name.trim() === "") {
        return res.status(400).json({ message: "Nome do fornecedor é obrigatório." });
    }

    try {
        const existingSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
        if (!existingSupplier) {
            return res.status(404).json({ message: "Fornecedor não encontrado nesta loja." });
        }

        const result = await db.updateSupplierDetails(supplierId, storeId, {
            name: name.trim(),
            email: email?.trim() || null,
            phone: phone?.trim() || null,
            address: address?.trim() || null,
            notes: notes?.trim() || null,
        });

        if (result.changes === 0) {
            return res.status(304).end(); // Not Modified
        }

        const updatedSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
        res.status(200).json(updatedSupplier);
    } catch (error) {
        console.error(`[SupplierCtrl] Erro em updateSupplier (Fornecedor: ${supplierId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// DELETE /api/stores/:storeId/suppliers/:supplierId - Deletar fornecedor
exports.deleteSupplier = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const supplierId = parseInt(req.params.supplierId, 10);
    if (isNaN(supplierId)) return res.status(400).json({ message: "ID do fornecedor inválido." });

    try {
        const existingSupplier = await db.findSupplierByIdAndStore(supplierId, storeId);
        if (!existingSupplier) {
            return res.status(404).json({ message: "Fornecedor não encontrado nesta loja." });
        }

        // A constraint ON DELETE SET NULL cuidará dos documentos
        const result = await db.deleteSupplierFromStore(supplierId, storeId);

        if (result.changes > 0) {
            res.status(200).json({ message: "Fornecedor excluído com sucesso." });
        } else {
            res.status(404).json({ message: "Fornecedor não encontrado." });
        }
    } catch (error) {
        console.error(`[SupplierCtrl] Erro em deleteSupplier (Fornecedor: ${supplierId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

