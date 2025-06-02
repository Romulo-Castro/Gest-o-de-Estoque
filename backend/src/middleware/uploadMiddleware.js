// src/middleware/uploadMiddleware.js

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Lê o diretório de upload da variável de ambiente ou usa um padrão
const UPLOAD_DIR = process.env.UPLOAD_FOLDER || 'uploads';
const uploadPath = path.join(__dirname, '../../', UPLOAD_DIR); // Caminho absoluto

// Cria o diretório de uploads se ele não existir
if (!fs.existsSync(uploadPath)) {
    try {
        fs.mkdirSync(uploadPath, { recursive: true }); // recursive: true cria diretórios pais se necessário
        console.log(`Diretório de uploads criado em: ${uploadPath}`);
    } catch (err) {
        console.error(`Erro ao criar diretório de uploads (${uploadPath}):`, err);
        // Decide se quer parar a aplicação ou continuar sem upload funcional
        // process.exit(1); // Descomente para parar se o diretório for essencial
    }
} else {
     console.log(`Usando diretório de uploads existente: ${uploadPath}`);
}


// Configuração de armazenamento do Multer
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadPath); // Define o diretório de destino
    },
    filename: function (req, file, cb) {
        // Define um nome de arquivo único para evitar colisões
        const itemId = req.params.id || 'unknown'; // Pega o ID do item da rota
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const extension = path.extname(file.originalname); // Pega a extensão original
        cb(null, `item-${itemId}-${uniqueSuffix}${extension}`);
    }
});

// Filtro de arquivo (opcional): Aceitar apenas imagens
const fileFilter = (req, file, cb) => {
    // --- DEBUGGING ---
    console.log('--- Informações do Arquivo Recebido ---');
    console.log('Nome original:', file.originalname);
    console.log('MIME Type recebido:', file.mimetype); // <-- O log mais importante!
    console.log('Encoding:', file.encoding);
    console.log('Tamanho:', file.size);
    console.log('---------------------------------------');
    // --- FIM DEBUGGING ---

    if (file.mimetype && file.mimetype.startsWith('image/')) { // Adiciona verificação se mimetype existe
        console.log(`MIME Type "${file.mimetype}" aceito.`);
        cb(null, true); // Aceitar arquivo
    } else {
        console.log(`MIME Type "${file.mimetype}" REJEITADO.`);
        // Rejeitar arquivo, passando o erro específico
        cb(new Error('Tipo de arquivo inválido. Apenas imagens são permitidas.'), false);
    }
};

// Cria a instância do multer com as configurações
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 1024 * 1024 * 5 // Limite de 5MB (opcional)
    }
});

module.exports = upload; // Exporta a instância configurada do multer