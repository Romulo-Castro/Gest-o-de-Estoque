// src/controllers/customerController.js
const db = require("../data/database");

// GET /api/stores/:storeId/customers - Listar clientes da loja
exports.getAllCustomers = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    try {
        const customers = await db.findCustomersByStore(storeId);
        res.status(200).json(customers);
    } catch (error) {
        console.error(`[CustomerCtrl] Erro em getAllCustomers para loja ${storeId}:`, error);
        next(error);
    }
};

// GET /api/stores/:storeId/customers/:customerId - Obter cliente por ID
exports.getCustomerById = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const customerId = parseInt(req.params.customerId, 10);
    if (isNaN(customerId)) return res.status(400).json({ message: "ID do cliente inválido." });

    try {
        const customer = await db.findCustomerByIdAndStore(customerId, storeId);
        if (!customer) {
            return res.status(404).json({ message: "Cliente não encontrado nesta loja." });
        }
        res.status(200).json(customer);
    } catch (error) {
        console.error(`[CustomerCtrl] Erro em getCustomerById (Cliente: ${customerId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// POST /api/stores/:storeId/customers - Criar novo cliente
exports.createCustomer = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const { name, email, phone, address, notes } = req.body;

    if (!name || name.trim() === "") {
        return res.status(400).json({ message: "Nome do cliente é obrigatório." });
    }

    try {
        const result = await db.createCustomerInStore({
            storeId,
            name: name.trim(),
            email: email?.trim() || null,
            phone: phone?.trim() || null,
            address: address?.trim() || null,
            notes: notes?.trim() || null,
        });
        const newCustomer = await db.findCustomerByIdAndStore(result.lastID, storeId);
        res.status(201).json(newCustomer);
    } catch (error) {
        console.error(`[CustomerCtrl] Erro em createCustomer para loja ${storeId}:`, error);
        // TODO: Tratar erro de constraint UNIQUE se for implementado
        next(error);
    }
};

// PUT /api/stores/:storeId/customers/:customerId - Atualizar cliente
exports.updateCustomer = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const customerId = parseInt(req.params.customerId, 10);
    const { name, email, phone, address, notes } = req.body;

    if (isNaN(customerId)) return res.status(400).json({ message: "ID do cliente inválido." });
    if (!name || name.trim() === "") {
        return res.status(400).json({ message: "Nome do cliente é obrigatório." });
    }

    try {
        // Verificar se cliente existe na loja antes de atualizar
        const existingCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
        if (!existingCustomer) {
            return res.status(404).json({ message: "Cliente não encontrado nesta loja." });
        }

        const result = await db.updateCustomerDetails(customerId, storeId, {
            name: name.trim(),
            email: email?.trim() || null,
            phone: phone?.trim() || null,
            address: address?.trim() || null,
            notes: notes?.trim() || null,
        });

        if (result.changes === 0) {
            // Pode acontecer se os dados forem os mesmos
            return res.status(304).end(); // Not Modified
        }

        const updatedCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
        res.status(200).json(updatedCustomer);
    } catch (error) {
        console.error(`[CustomerCtrl] Erro em updateCustomer (Cliente: ${customerId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// DELETE /api/stores/:storeId/customers/:customerId - Deletar cliente
exports.deleteCustomer = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const customerId = parseInt(req.params.customerId, 10);
    if (isNaN(customerId)) return res.status(400).json({ message: "ID do cliente inválido." });

    try {
        // Verificar se cliente existe
        const existingCustomer = await db.findCustomerByIdAndStore(customerId, storeId);
        if (!existingCustomer) {
            return res.status(404).json({ message: "Cliente não encontrado nesta loja." });
        }

        // A constraint ON DELETE SET NULL cuidará dos documentos
        const result = await db.deleteCustomerFromStore(customerId, storeId);

        if (result.changes > 0) {
            res.status(200).json({ message: "Cliente excluído com sucesso." });
        } else {
            res.status(404).json({ message: "Cliente não encontrado." }); // Segurança
        }
    } catch (error) {
        console.error(`[CustomerCtrl] Erro em deleteCustomer (Cliente: ${customerId}, Loja: ${storeId}):`, error);
        // TODO: Tratar erro se houver alguma constraint inesperada (ex: documentos futuros?)
        next(error);
    }
};

