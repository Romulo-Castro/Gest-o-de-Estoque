// src/controllers/authController.js
const db = require('../data/database'); // Para interagir com o DB (buscar/criar usuário)
const bcrypt = require('bcryptjs'); // Para comparar/hash de senhas
const jwt = require('jsonwebtoken'); // Para criar tokens JWT
require('dotenv').config(); // Para acessar JWT_SECRET

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
    console.error("ERRO CRÍTICO: JWT_SECRET não definido no .env");
    process.exit(1);
}

// --- Função de Registro ---
exports.register = async (req, res, next) => {
    const { name, email, password } = req.body;

    try {
        // 1. Verificar se email já existe
        const existingUser = await db.findUserByEmail(email); // Precisa criar essa função no database.js
        if (existingUser) {
            return res.status(409).json({ message: 'Email já cadastrado.' }); // 409 Conflict
        }

        // 2. Hash da senha
        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        // 3. Criar usuário no DB
        const newUserResult = await db.createUser({ // Precisa criar essa função no database.js
            name,
            email,
            passwordHash
        });

        // 4. Buscar o usuário recém-criado (opcional, para retornar dados)
        const newUser = await db.findUserById(newUserResult.lastID); // Precisa criar essa função no database.js

        // 5. Gerar Token JWT para login automático (ou pedir para logar)
         const payload = { userId: newUser.id, email: newUser.email };
         const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' }); // Token expira em 1 dia

        // 6. Responder com sucesso (e talvez o token/dados do usuário)
        res.status(201).json({
             message: 'Usuário registrado com sucesso!',
             token: token, // Envia token para login automático no frontend
             user: { // Não enviar hash da senha!
                 id: newUser.id,
                 name: newUser.name,
                 email: newUser.email
             }
         });

    } catch (error) {
        console.error("Erro no registro:", error);
        // Passa o erro para o middleware de erro genérico
        next(error); // IMPORTANTE: usar next(error) para erros async
    }
};

// --- Função de Login ---
exports.login = async (req, res, next) => {
    const { email, password } = req.body;

    try {
        // 1. Buscar usuário pelo email
         const user = await db.findUserByEmail(email);
        if (!user) {
             // Resposta genérica para não revelar se o email existe ou não
            return res.status(401).json({ message: 'Credenciais inválidas.' }); // 401 Unauthorized
        }

        // 2. Comparar a senha enviada com o hash no DB
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
             return res.status(401).json({ message: 'Credenciais inválidas.' });
        }

        // 3. Gerar Token JWT
         const payload = { userId: user.id, email: user.email };
         const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' }); // Ou um tempo menor/maior

        // 4. Responder com sucesso e o token
        res.status(200).json({
            message: 'Login bem-sucedido!',
            token: token,
             user: { // Retorna dados básicos do usuário
                 id: user.id,
                 name: user.name,
                 email: user.email
             }
        });

    } catch (error) {
        console.error("Erro no login:", error);
        next(error); // Passa para o error handler
    }
};


// (Opcional) Função para obter dados do usuário logado
exports.getMe = async (req, res, next) => {
    // O middleware authenticateToken (se usado na rota) já colocou req.user
    if (!req.user || !req.user.userId) {
        return res.status(401).json({ message: 'Não autorizado ou token inválido.' });
    }

    try {
        const user = await db.findUserById(req.user.userId); // Busca dados frescos do DB
        if (!user) {
            return res.status(404).json({ message: 'Usuário não encontrado.'});
        }
         res.status(200).json({
             id: user.id,
             name: user.name,
             email: user.email
             // Não retornar o hash da senha!
         });
    } catch (error) {
        console.error("Erro em getMe:", error);
        next(error);
    }

};