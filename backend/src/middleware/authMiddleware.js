// src/middleware/authMiddleware.js
const jwt = require('jsonwebtoken');
const db = require('../data/database'); // Para checar acesso à loja
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET;

const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    // Formato esperado: "Bearer TOKEN"
    const token = authHeader && authHeader.split(' ')[1];

    if (token == null) {
        return res.status(401).json({ message: 'Token de autenticação não fornecido.' }); // Unauthorized
    }

    jwt.verify(token, JWT_SECRET, (err, userPayload) => {
        if (err) {
            console.error("Erro na verificação do token:", err.message);
            if (err.name === 'TokenExpiredError') {
                 return res.status(401).json({ message: 'Token expirado.' });
            }
            return res.status(403).json({ message: 'Token inválido ou corrompido.' }); // Forbidden
        }
        // Adiciona o payload decodificado (ex: { userId: 1, email: '...' }) ao objeto req
        req.user = userPayload;
        next(); // Token válido, prossegue para a próxima etapa
    });
};

// Middleware para verificar se o usuário logado tem acesso à loja especificada na URL
const checkStoreAccess = async (req, res, next) => {
    try {
        const storeId = parseInt(req.params.storeId, 10);
        const userId = req.user?.userId; // Pega userId do payload do token (adicionado por authenticateToken)

        if (isNaN(storeId)) {
            return res.status(400).json({ message: 'ID da loja inválido na URL.' });
        }
        if (!userId) {
             // Isso não deveria acontecer se authenticateToken rodou antes, mas é uma segurança extra
             return res.status(401).json({ message: 'Usuário não autenticado.' });
        }

        // Consulta o banco para ver se existe uma entrada em user_stores
        const roleInfo = await db.findUserStoreRoleDB(userId, storeId);

        if (!roleInfo) {
            // Usuário não tem acesso a esta loja específica
            return res.status(403).json({ message: 'Acesso negado a esta loja.' }); // Forbidden
        }

        // Opcional: Adicionar a role ao req para verificações mais finas nos controllers
        req.userStoreRole = roleInfo.role;

        next(); // Usuário tem acesso, pode prosseguir

    } catch (error) {
         console.error("Erro em checkStoreAccess:", error);
         next(error); // Passa para o error handler geral
    }

};


module.exports = { authenticateToken, checkStoreAccess };