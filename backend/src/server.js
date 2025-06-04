// src/server.js

// Carrega variáveis do .env O MAIS CEDO POSSÍVEL, especialmente se DB config depende delas
require('dotenv').config({ path: require('path').resolve(__dirname, '/.env') }); // Garante que carrega da pasta backend

const express = require('express');
const cors = require('cors');
const path = require('path');
const dbSetup = require('./data/database'); // Importa o setup do DB SQLite

// Importar arquivos de ROTA PRINCIPAL (outras rotas serão montadas dentro delas)
const authRoutes = require('./routes/authRoutes'); // Assumindo que você criará este
const storeRoutes = require('./routes/storeRoutes'); // Assumindo que você criará este (e ele montará stockRoutes)
// Não importar stockRoutes diretamente aqui se for montado DENTRO de storeRoutes

const app = express();
const PORT = process.env.PORT || 3000;
const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';

// --- Função Async para Iniciar o Servidor ---
async function startServer() {
    try {
        // 1. Conectar ao DB e Criar/Verificar Tabelas ANTES de iniciar o servidor web
        console.log("Iniciando conexão com o banco de dados...");
        await dbSetup.connectDb();
        console.log("Iniciando criação/verificação de tabelas...");
        await dbSetup.createTables();
        console.log("Configuração do banco de dados concluída.");

        // === Middleware Essencial ===
        app.use(cors()); // Habilitar CORS
        app.use(express.json()); // Parsear JSON
        app.use(express.urlencoded({ extended: true })); // Parsear URL-encoded (menos comum, mas pode ser útil)

        // Servir arquivos estáticos da pasta de uploads
        const uploadsAbsolutePath = path.join(__dirname, '../', UPLOAD_DIR);
        console.log(`Configurando rota estática para /${UPLOAD_DIR} em ${uploadsAbsolutePath}`);
        // IMPORTANTE: A URL base será relativa à raiz do servidor. Ex: http://localhost:3000/uploads/arquivo.jpg
        app.use(`/${UPLOAD_DIR}`, express.static(uploadsAbsolutePath));


        // === Rotas da API ===
        console.log("Configurando rotas da API...");
        // Rota raiz da API para teste
        app.get('/api', (req, res) => {
            res.send('API Gestão de Estoques (SQLite) está funcionando!');
        });

        // Montar rotas de Autenticação
        // Exemplo: /api/auth/login, /api/auth/register
        app.use('/api/auth', authRoutes);

        // Montar rotas de Lojas (que incluirão as rotas de estoque aninhadas)
        // Exemplo: GET /api/stores, POST /api/stores, GET /api/stores/:storeId,
        //          GET /api/stores/:storeId/stock, POST /api/stores/:storeId/stock/:itemId/image etc.
        app.use('/api/stores', storeRoutes);

        // Montar outras rotas de nível superior ou aninhadas aqui (ex: usuários, relatórios gerais)
        // app.use('/api/users', userRoutes); // Se houver rotas diretas de usuário
        // app.use('/api/reports', reportRoutes); // Se houver relatórios gerais

        console.log("Rotas configuradas.");

        // === Tratamento de Erros (DEPOIS das rotas) ===
        // Middleware 404 (Rota não encontrada)
        app.use((req, res, next) => {
            if (!res.headersSent) { // Verifica se a resposta já não foi enviada
                 res.status(404).json({ message: 'Endpoint não encontrado.' });
            }
            // Não chamar next() aqui se for 404 definitivo
        });

        // Middleware Genérico de Tratamento de Erros
        // Precisa ter 4 argumentos (err, req, res, next) para ser reconhecido como error handler
        app.use((err, req, res, next) => {
            if (res.headersSent) {
                return next(err); // Delega se resposta já iniciou
            }

            console.error("ERRO CAPTURADO:", err.stack || err); // Log detalhado

            // Tratamento específico para erros conhecidos (ex: Multer) pode ser feito aqui
            // mas é melhor se o erro já vier tratado do controller/middleware anterior
            // if (err instanceof multer.MulterError) { ... } // 'multer' precisaria ser importado aqui para isso

            // Resposta de erro genérica
            const statusCode = err.status || (err.code === 'SQLITE_CONSTRAINT' ? 400 : 500); // Tenta mapear erros de constraint para 400
            res.status(statusCode).json({
                message: err.message || 'Ocorreu um erro interno no servidor.',
                // Opcional: incluir detalhes do erro em DEV
                // error: process.env.NODE_ENV === 'development' ? { code: err.code, stack: err.stack } : undefined
            });
        });

        // === Iniciar o Servidor ===
        app.listen(PORT, () => {
            console.log(`\nServidor backend (SQLite) rodando na porta ${PORT}`);
            console.log(`Ambiente: ${process.env.NODE_ENV || 'produção (padrão)'}`);
            console.log(`Uploads em: ${uploadsAbsolutePath}`);
            console.log(`URL base para imagens: ${process.env.BASE_URL || `http://localhost:${PORT}`}/${UPLOAD_DIR}/`);
            console.log(`Acesse a API em: http://localhost:${PORT}/api`);
        });

    } catch (error) {
        console.error("!!! FALHA CRÍTICA AO INICIAR O SERVIDOR !!!");
        console.error(error);
        process.exit(1); // Encerra o processo se a inicialização falhar
    }
}

// --- Executar a inicialização ---
startServer();