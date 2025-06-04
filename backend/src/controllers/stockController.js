// src/controllers/stockController.js
const db = require('../data/database'); // Importa funções do DB SQLite
const path = require('path');
const fs = require('fs');
// Garante que dotenv seja carregado para ler process.env
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';
// Lê BASE_URL do .env ou usa localhost como fallback
const BASE_URL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;

// Função Helper para construir a URL completa da imagem
const buildImageUrl = (filename) => {
    if (!filename) return null;
    return `${BASE_URL}/${UPLOAD_DIR}/${filename}`;
};

// GET /api/stores/:storeId/stock
exports.getAllStockItems = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    try {
        const items = await db.findStockItemsByStore(storeId);
        const itemsWithFullUrls = items.map(item => ({
            ...item,
            image_filename: undefined,
            imageUrl: buildImageUrl(item.image_filename)
        }));
        res.status(200).json(itemsWithFullUrls);
    } catch (error) {
        console.error(`[StockCtrl] Erro em getAllStockItems para loja ${storeId}:`, error);
        next(error);
    }
};

// GET /api/stores/:storeId/stock/:itemId
exports.getStockItemById = async (req, res, next) => {
     const storeId = parseInt(req.params.storeId, 10);
     const itemId = parseInt(req.params.itemId, 10);
     if (isNaN(itemId)) return res.status(400).json({ message: 'ID do item inválido.' });
     try {
        const item = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!item) {
            return res.status(404).json({ message: 'Item não encontrado nesta loja.' });
        }
        res.status(200).json({
            ...item,
            image_filename: undefined,
            imageUrl: buildImageUrl(item.image_filename)
        });
    } catch (error) {
         console.error(`[StockCtrl] Erro em getStockItemById (Item: ${itemId}, Loja: ${storeId}):`, error);
         next(error);
    }
};

// POST /api/stores/:storeId/stock
exports.createStockItem = async (req, res, next) => {
     const storeId = parseInt(req.params.storeId, 10);
    try {
        // ★★★ CORREÇÃO: Pega 'properties' e 'groupId' do corpo ★★★
        const { name, quantity, properties, groupId } = req.body;
        console.log(`[StockCtrl] Tentando criar item na loja ${storeId}:`, { name, quantity, properties, groupId });

        if (!name) return res.status(400).json({ message: "Nome do item é obrigatório." });

        // Validação básica de 'properties' (pode ser melhorada com express-validator)
        if (properties && typeof properties !== 'object') {
            return res.status(400).json({ message: "'properties' deve ser um objeto JSON." });
        }

        // Cria o item passando o objeto properties (ou um objeto vazio) e groupId
        // A função createStockItemInStore no database.js fará o JSON.stringify
        const result = await db.createStockItemInStore({
            storeId,
            name,
            quantity: parseFloat(quantity) || 0.0,
            groupId: groupId || null, // Processa o groupId enviado pelo frontend
            properties: properties || {} // Garante que é um objeto
        });
        console.log(`[StockCtrl] Item criado com ID: ${result.lastID}`);

        const newItem = await db.findStockItemByIdAndStore(result.lastID, storeId);
        if (!newItem) {
             console.error(`[StockCtrl] Erro crítico: Não encontrou item ${result.lastID} após criação.`);
             return res.status(500).json({ message: "Erro ao buscar item após criação." });
        }
        console.log(`[StockCtrl] Retornando item criado ID: ${newItem.id}`);
        res.status(201).json({
            ...newItem, // newItem.properties já foi parseado pelo findStockItemByIdAndStore
            image_filename: undefined,
            imageUrl: buildImageUrl(newItem.image_filename)
        });
    } catch (error) {
        console.error(`[StockCtrl] Erro em createStockItem para loja ${storeId}:`, error);
        next(error);
    }
};

// PUT /api/stores/:storeId/stock/:itemId
exports.updateStockItem = async (req, res, next) => {
     const storeId = parseInt(req.params.storeId, 10);
     const itemId = parseInt(req.params.itemId, 10);
     if (isNaN(itemId)) return res.status(400).json({ message: 'ID do item inválido.' });
    try {
        // ★★★ CORREÇÃO: Pega 'properties' como um objeto do corpo ★★★
        const { name, quantity, properties, groupId } = req.body;
        console.log(`[StockCtrl] Tentando atualizar item ${itemId} na loja ${storeId}:`, { name, quantity, properties, groupId });
        if (!name) return res.status(400).json({ message: "Nome do item é obrigatório." });

        // Validação básica de 'properties'
        if (properties && typeof properties !== 'object') {
             return res.status(400).json({ message: "'properties' deve ser um objeto JSON." });
        }

        const existingItem = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!existingItem) {
            return res.status(404).json({ message: "Item não encontrado nesta loja." });
        }

        // ★★★ CORREÇÃO: Passa o objeto 'properties' recebido ★★★
        // A função updateStockItemDetails no database.js fará o JSON.stringify
        // Se 'properties' não for enviado no PUT, existingItem.properties será usado (preservando dados)
        const result = await db.updateStockItemDetails(itemId, storeId, {
            name,
            quantity: parseFloat(quantity) ?? existingItem.quantity, // Usa ?? para fallback seguro
            properties: properties ?? existingItem.properties, // Usa properties recebido ou o existente
            groupId: groupId !== undefined ? groupId : existingItem.group_id
        });

        if (result.changes === 0) {
             console.log(`[StockCtrl] Nenhuma linha alterada para item ${itemId} na loja ${storeId}.`);
             // Pode ser que os dados enviados sejam iguais aos existentes
             // Retorna 200 com os dados atuais ou 304 Not Modified? Vamos retornar 200.
             // return res.status(304).end(); // Alternativa Not Modified
        }
        console.log(`[StockCtrl] Item ${itemId} atualizado/verificado.`);

        const updatedItem = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!updatedItem) {
             console.error(`[StockCtrl] Erro crítico: Não encontrou item ${itemId} após atualização.`);
             return res.status(500).json({ message: "Erro ao buscar item após atualização." });
        }
        console.log(`[StockCtrl] Retornando item atualizado ID: ${updatedItem.id}`);
        res.status(200).json({
            ...updatedItem, // updatedItem.properties já foi parseado
            image_filename: undefined,
            imageUrl: buildImageUrl(updatedItem.image_filename)
        });
    } catch (error) {
        console.error(`[StockCtrl] Erro em updateStockItem (Item: ${itemId}, Loja: ${storeId}):`, error);
        next(error);
    }
};

// DELETE /api/stores/:storeId/stock/:itemId
exports.deleteStockItem = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const itemId = parseInt(req.params.itemId, 10);
    if (isNaN(itemId)) return res.status(400).json({ message: 'ID do item inválido.' });
    try {
        console.log(`[StockCtrl] Tentando deletar item ${itemId} da loja ${storeId}.`);
        const item = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!item) {
            return res.status(404).json({ message: "Item não encontrado." });
        }
        const imageFilename = item.image_filename;

        const result = await db.deleteStockItemFromStore(itemId, storeId);

        if (result.changes > 0) {
            console.log(`[StockCtrl] Item ${itemId} deletado do DB.`);
            if (imageFilename) {
                 const imagePath = path.resolve(__dirname, '../../', UPLOAD_DIR, imageFilename);
                 fs.unlink(imagePath, (err) => { /* ... tratamento de erro unlink ... */ });
            }
            res.status(200).json({ message: "Item deletado com sucesso." });
        } else {
             res.status(404).json({ message: "Item não encontrado." }); // Caso raro
        }
    } catch (error) {
        console.error(`[StockCtrl] Erro em deleteStockItem (Item: ${itemId}, Loja: ${storeId}):`, error);
        if (error.code === 'SQLITE_CONSTRAINT_FOREIGNKEY' || (error.message && error.message.includes('FOREIGN KEY constraint failed'))) {
             return res.status(400).json({ message: "Não é possível excluir o item, pois ele está associado a documentos existentes." });
        }
        next(error);
     }
};

// POST /api/stores/:storeId/stock/:itemId/image
exports.uploadStockItemImage = async (req, res, next) => {
    const storeId = parseInt(req.params.storeId, 10);
    const itemId = parseInt(req.params.itemId, 10);
    if (isNaN(itemId)) return res.status(400).json({ message: 'ID do item inválido.' });
    if (!req.file) return res.status(400).json({ message: 'Nenhuma imagem foi enviada.' });

    const imageFilename = req.file.filename;
    console.log(`[StockCtrl] Recebido upload de imagem ${imageFilename} para item ${itemId} na loja ${storeId}.`);
    let oldImagePath = null;

    try {
        const item = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!item) {
            fs.unlink(req.file.path, (err) => { if (err) console.error(`Erro ao remover ${req.file.path}:`, err);});
            return res.status(404).json({ message: "Item não encontrado." });
        }
        if (item.image_filename) { oldImagePath = path.resolve(__dirname, '../../', UPLOAD_DIR, item.image_filename); }

        await db.updateStockItemImageFilename(itemId, storeId, imageFilename);
        console.log(`[StockCtrl] DB atualizado com novo nome de imagem ${imageFilename} para item ${itemId}.`);

        if (oldImagePath) { fs.unlink(oldImagePath, (err) => { /* ... tratamento erro unlink ... */ }); }

        const updatedItem = await db.findStockItemByIdAndStore(itemId, storeId);
        if (!updatedItem) { return res.status(500).json({ message: "Erro ao buscar item após upload." }); }

        console.log(`[StockCtrl] Retornando item ${itemId} atualizado com imagem.`);
        res.status(200).json({
            ...updatedItem, // properties já parseadas aqui
            image_filename: undefined,
            imageUrl: buildImageUrl(updatedItem.image_filename)
        });

    } catch (error) {
        console.error(`[StockCtrl] Erro em uploadStockItemImage (Item: ${itemId}, Loja: ${storeId}):`, error);
        fs.unlink(req.file.path, (err) => { if (err) console.error(`Erro ao remover ${req.file.path} após falha:`, err); });
        next(error);
    }
};