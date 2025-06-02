// src/data/database.js
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
// Corrigido o path para o .env na raiz do backend
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

// Usa variável de ambiente ou um padrão seguro
const dbPath = process.env.SQLITE_PATH || path.resolve(__dirname, '../../inventory_data.db');
let db; // Instância do banco de dados

// Função para conectar ao banco de dados
function connectDb() {
    return new Promise((resolve, reject) => {
        db = new sqlite3.Database(dbPath, sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE, (err) => {
            if (err) {
                console.error("Erro ao conectar/criar SQLite:", err.message);
                reject(err);
            } else {
                console.log("Conectado ao banco de dados SQLite:", dbPath);
                db.run('PRAGMA foreign_keys = ON;', (fkErr) => {
                    if (fkErr) {
                        console.error("Erro ao habilitar foreign keys:", fkErr.message);
                        reject(fkErr);
                    } else {
                        console.log("Foreign key constraints habilitadas.");
                        resolve(db);
                    }
                });
            }
        });
    });
}

// Função para criar as tabelas se não existirem
async function createTables() {
    if (!db) throw new Error("Banco de dados não conectado para criar tabelas.");

    const createScripts = [
        // --- Usuários e Lojas ---
        `CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL, createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );`,
        `CREATE TABLE IF NOT EXISTS stores (
            id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, address TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
        );`,
        `CREATE TABLE IF NOT EXISTS user_stores (
            user_id INTEGER NOT NULL, store_id INTEGER NOT NULL,
            role TEXT CHECK(role IN ('owner', 'manager', 'staff')) NOT NULL DEFAULT 'staff',
            PRIMARY KEY (user_id, store_id),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        );`,
        // --- Grupos de Itens ---
        `CREATE TABLE IF NOT EXISTS item_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL, name TEXT NOT NULL,
            parent_group_id INTEGER, createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
            FOREIGN KEY (parent_group_id) REFERENCES item_groups(id) ON DELETE SET NULL
        );`,
        // --- Itens de Estoque ---
        `CREATE TABLE IF NOT EXISTS stock_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL, group_id INTEGER,
            name TEXT NOT NULL, quantity REAL DEFAULT 0, properties TEXT, image_filename TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
            FOREIGN KEY (group_id) REFERENCES item_groups(id) ON DELETE SET NULL
        );`,
        // --- Clientes ---
        `CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL, name TEXT NOT NULL,
            email TEXT, phone TEXT, address TEXT, notes TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
            -- UNIQUE(store_id, email) WHERE email IS NOT NULL -- Opcional
            -- UNIQUE(store_id, name) -- Opcional
        );`,
        // --- Fornecedores ---
         `CREATE TABLE IF NOT EXISTS suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL, name TEXT NOT NULL,
            email TEXT, phone TEXT, address TEXT, notes TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
            -- UNIQUE(store_id, email) WHERE email IS NOT NULL -- Opcional
            -- UNIQUE(store_id, name) -- Opcional
        );`,
        // --- Documentos (Entradas/Saídas) ---
        `CREATE TABLE IF NOT EXISTS documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL,
            type TEXT NOT NULL CHECK(type IN ('sale', 'purchase', 'adjustment_in', 'adjustment_out')),
            document_date DATE NOT NULL,
            customer_id INTEGER, -- Nulo se não for venda
            supplier_id INTEGER, -- Nulo se não for compra
            notes TEXT,
            total_amount REAL, -- Pode ser calculado ou armazenado
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE,
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL, -- Não deletar doc se cliente for excluído
            FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL -- Não deletar doc se fornecedor for excluído
        );`,
        // --- Itens do Documento ---
        `CREATE TABLE IF NOT EXISTS document_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT, document_id INTEGER NOT NULL, item_id INTEGER NOT NULL,
            quantity REAL NOT NULL, -- Quantidade movimentada
            unit_price REAL, -- Preço no momento da transação
            -- line_total REAL,
            FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE, -- Se deletar doc, deleta itens
            FOREIGN KEY (item_id) REFERENCES stock_items(id) ON DELETE RESTRICT -- IMPORTANTE: Não permite deletar item usado em documento
        );`,
        // --- Despesas ---
         `CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT, store_id INTEGER NOT NULL,
            expense_date DATE NOT NULL, description TEXT NOT NULL, amount REAL NOT NULL,
            category TEXT, notes TEXT,
            createdAt DATETIME DEFAULT CURRENT_TIMESTAMP, updatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
        );`
    ];

    console.log("Iniciando criação/verificação de tabelas...");
    try {
        for (const script of createScripts) {
            await runQuery(script);
        }
        console.log("Tabelas verificadas/criadas com sucesso.");
    } catch (error) {
        console.error("Erro durante a criação de tabelas:", error);
        throw error; // Re-lança o erro
    }
}

// --- Funções Auxiliares de Query ---
function runQuery(query, params = []) {
    return new Promise((resolve, reject) => {
        if (!db) return reject(new Error("Banco de dados não conectado."));
        db.run(query, params, function (err) {
            if (err) { console.error('Erro SQL (run):', query, params, err.message); reject(err); }
            else { resolve({ lastID: this.lastID, changes: this.changes }); }
        });
    });
}
function getQuery(query, params = []) {
     return new Promise((resolve, reject) => {
         if (!db) return reject(new Error("Banco de dados não conectado."));
         db.get(query, params, (err, row) => {
             if (err) { console.error('Erro SQL (get):', query, params, err.message); reject(err); }
             else { resolve(row); }
         });
     });
}
function allQuery(query, params = []) {
     return new Promise((resolve, reject) => {
         if (!db) return reject(new Error("Banco de dados não conectado."));
         db.all(query, params, (err, rows) => {
              if (err) { console.error('Erro SQL (all):', query, params, err.message); reject(err); }
              else { resolve(rows); }
         });
     });
}

// --- Função para parsear JSON das propriedades ---
function parseItemProperties(item) {
    if (item && item.properties) {
        try { item.properties = JSON.parse(item.properties); }
        catch (e) { console.error(`Erro parse JSON ${item?.id}:`, e); item.properties = {}; }
    } else if (item) { item.properties = {}; }
    return item;
}

// --- Funções de Acesso Específicas ao Banco de Dados ---

// -- Users --
const findUserByEmail = (email) => getQuery('SELECT * FROM users WHERE email = ?', [email]);
const createUser = ({ name, email, passwordHash }) => runQuery('INSERT INTO users (name, email, password_hash) VALUES (?, ?, ?)', [name, email, passwordHash]);
const findUserById = (id) => getQuery('SELECT id, name, email, createdAt, updatedAt FROM users WHERE id = ?', [id]);

// -- Stores --
const createStoreDB = ({ name, address }) => runQuery('INSERT INTO stores (name, address) VALUES (?, ?)', [name, address]);
const findStoresByUserIdDB = (userId) => allQuery(`SELECT s.* FROM stores s JOIN user_stores us ON s.id = us.store_id WHERE us.user_id = ? ORDER BY s.name`, [userId]);
const findStoreByIdDB = (id) => getQuery('SELECT * FROM stores WHERE id = ?', [id]);
const updateStoreDB = (id, { name, address }) => runQuery('UPDATE stores SET name = ?, address = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ?', [name, address, id]);
const deleteStoreDB = (id) => runQuery('DELETE FROM stores WHERE id = ?', [id]);

// -- UserStores (Acesso) --
const addUserToStoreDB = ({ userId, storeId, role = 'staff' }) => runQuery('INSERT INTO user_stores (user_id, store_id, role) VALUES (?, ?, ?) ON CONFLICT(user_id, store_id) DO UPDATE SET role=excluded.role', [userId, storeId, role]);
const findUserStoreRoleDB = (userId, storeId) => getQuery('SELECT role FROM user_stores WHERE user_id = ? AND store_id = ?', [userId, storeId]);

// -- StockItems --
const findStockItemsByStore = (storeId, groupId = null) => {
    let sql = 'SELECT * FROM stock_items WHERE store_id = ?';
    const params = [storeId];
    if (groupId !== null && groupId !== undefined && groupId !== '') {
        sql += ' AND group_id = ?'; params.push(groupId);
    } else { sql += ' AND (group_id IS NULL OR group_id = 0 OR group_id = \'\')'; } // Abrange mais casos de 'sem grupo'
    sql += ' ORDER BY name ASC';
    return allQuery(sql, params).then(rows => rows.map(parseItemProperties));
};
const findStockItemByIdAndStore = (itemId, storeId) => getQuery('SELECT * FROM stock_items WHERE id = ? AND store_id = ?', [itemId, storeId]).then(row => row ? parseItemProperties(row) : null);
const createStockItemInStore = ({ storeId, groupId = null, name, quantity = 0, properties = {} }) => runQuery('INSERT INTO stock_items (store_id, group_id, name, quantity, properties) VALUES (?, ?, ?, ?, ?)', [storeId, groupId, name, quantity, JSON.stringify(properties)]);
const updateStockItemDetails = (itemId, storeId, { name, quantity, properties, groupId }) => runQuery('UPDATE stock_items SET name = ?, quantity = ?, properties = ?, group_id = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ? AND store_id = ?', [name, quantity, JSON.stringify(properties), groupId, itemId, storeId]);
const updateStockItemImageFilename = (itemId, storeId, imageFilename) => runQuery('UPDATE stock_items SET image_filename = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ? AND store_id = ?', [imageFilename, itemId, storeId]);
const deleteStockItemFromStore = (itemId, storeId) => runQuery('DELETE FROM stock_items WHERE id = ? AND store_id = ?', [itemId, storeId]);

// -- Customers --
const findCustomersByStore = (storeId) => allQuery('SELECT * FROM customers WHERE store_id = ? ORDER BY name ASC', [storeId]);
const findCustomerByIdAndStore = (customerId, storeId) => getQuery('SELECT * FROM customers WHERE id = ? AND store_id = ?', [customerId, storeId]);
const createCustomerInStore = ({ storeId, name, email = null, phone = null, address = null, notes = null }) => runQuery('INSERT INTO customers (store_id, name, email, phone, address, notes) VALUES (?, ?, ?, ?, ?, ?)', [storeId, name, email, phone, address, notes]);
const updateCustomerDetails = (customerId, storeId, { name, email, phone, address, notes }) => runQuery('UPDATE customers SET name = ?, email = ?, phone = ?, address = ?, notes = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ? AND store_id = ?', [name, email, phone, address, notes, customerId, storeId]);
const deleteCustomerFromStore = (customerId, storeId) => runQuery('DELETE FROM customers WHERE id = ? AND store_id = ?', [customerId, storeId]); // ON DELETE SET NULL nos documentos

// -- Suppliers --
const findSuppliersByStore = (storeId) => allQuery('SELECT * FROM suppliers WHERE store_id = ? ORDER BY name ASC', [storeId]);
const findSupplierByIdAndStore = (supplierId, storeId) => getQuery('SELECT * FROM suppliers WHERE id = ? AND store_id = ?', [supplierId, storeId]);
const createSupplierInStore = ({ storeId, name, email = null, phone = null, address = null, notes = null }) => runQuery('INSERT INTO suppliers (store_id, name, email, phone, address, notes) VALUES (?, ?, ?, ?, ?, ?)', [storeId, name, email, phone, address, notes]);
const updateSupplierDetails = (supplierId, storeId, { name, email, phone, address, notes }) => runQuery('UPDATE suppliers SET name = ?, email = ?, phone = ?, address = ?, notes = ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ? AND store_id = ?', [name, email, phone, address, notes, supplierId, storeId]);
const deleteSupplierFromStore = (supplierId, storeId) => runQuery('DELETE FROM suppliers WHERE id = ? AND store_id = ?', [supplierId, storeId]); // ON DELETE SET NULL nos documentos


// --- Adicionar funções para DOCUMENTOS e DESPESAS ---
// Exemplo: Criar documento e ajustar estoque (PRECISA DE TRANSAÇÃO!)
async function createDocumentAndAdjustStock(documentData, documentItems) {
     if (!db) throw new Error("Banco de dados não conectado.");
     // Iniciar transação
     await runQuery('BEGIN TRANSACTION');
     try {
         // 1. Inserir o documento principal
         const docSql = `INSERT INTO documents (store_id, type, document_date, customer_id, supplier_id, notes, total_amount)
                         VALUES (?, ?, ?, ?, ?, ?, ?)`;
         const docParams = [
             documentData.storeId, documentData.type, documentData.documentDate,
             documentData.customerId, documentData.supplierId, documentData.notes, documentData.totalAmount
         ];
         const docResult = await runQuery(docSql, docParams);
         const documentId = docResult.lastID;

         // 2. Inserir itens do documento e ajustar estoque
         const itemInsertSql = 'INSERT INTO document_items (document_id, item_id, quantity, unit_price) VALUES (?, ?, ?, ?)';
         const stockUpdateSql = 'UPDATE stock_items SET quantity = quantity + ?, updatedAt = CURRENT_TIMESTAMP WHERE id = ? AND store_id = ?'; // Ajusta estoque

         for (const item of documentItems) {
             // Insere no document_items
             await runQuery(itemInsertSql, [documentId, item.itemId, item.quantity, item.unitPrice]);

             // Ajusta estoque em stock_items
             let quantityChange = 0;
             if (documentData.type === 'purchase' || documentData.type === 'adjustment_in') {
                 quantityChange = item.quantity; // Aumenta estoque
             } else if (documentData.type === 'sale' || documentData.type === 'adjustment_out') {
                 quantityChange = -item.quantity; // Diminui estoque
                 // Opcional: Verificar se há estoque suficiente antes de diminuir
                 // const currentStock = await getQuery('SELECT quantity FROM stock_items WHERE id = ?', [item.itemId]);
                 // if (currentStock.quantity < item.quantity) throw new Error(`Estoque insuficiente para ${item.name}`);
             }
             if (quantityChange !== 0) {
                 await runQuery(stockUpdateSql, [quantityChange, item.itemId, documentData.storeId]);
             }
         }

         // 3. Commit da transação se tudo deu certo
         await runQuery('COMMIT');
         return documentId; // Retorna ID do documento criado

     } catch (error) {
         // 4. Rollback em caso de erro
         console.error("Erro na transação de documento, fazendo rollback:", error);
         await runQuery('ROLLBACK');
         throw error; // Re-lança o erro para o controller
     }
}


// --- Exportações ---
module.exports = {
    connectDb,
    createTables,
    // Funções Auxiliares (Opcional)
    // runQuery, getQuery, allQuery,

    // Users
    findUserByEmail,
    createUser,
    findUserById,

    // Stores
    createStoreDB,
    findStoresByUserIdDB,
    findStoreByIdDB,
    updateStoreDB,
    deleteStoreDB,

    // UserStores
    addUserToStoreDB,
    findUserStoreRoleDB,

    // StockItems
    findStockItemsByStore,
    findStockItemByIdAndStore,
    createStockItemInStore,
    updateStockItemDetails,
    updateStockItemImageFilename,
    deleteStockItemFromStore,

    // Customers
    findCustomersByStore,
    findCustomerByIdAndStore,
    createCustomerInStore,
    updateCustomerDetails,
    deleteCustomerFromStore,

    // Suppliers
    findSuppliersByStore,
    findSupplierByIdAndStore,
    createSupplierInStore,
    updateSupplierDetails,
    deleteSupplierFromStore,

    // Documents & Stock Adjustment (Exemplo de função complexa)
    createDocumentAndAdjustStock,
    // Adicionar findDocuments, findDocumentItems, etc.

    // Expenses
    // Adicionar createExpense, findExpenses, etc.
};