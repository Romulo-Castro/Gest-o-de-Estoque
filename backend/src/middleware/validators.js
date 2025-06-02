// src/middleware/validators.js
const { body, validationResult, param, check } = require('express-validator'); // Adiciona 'check'

// Middleware Handler
const handleValidationErrors = (req, res, next) => { /* ... (código anterior) ... */
    const errors = validationResult(req);
    if (!errors.isEmpty()) { return res.status(400).json({ errors: errors.array() }); }
    next();
};

// Regras de Validação
const validateRegistration = () => [ /* ... (código anterior) ... */
    body('name').trim().notEmpty().withMessage('Nome obrigatório.').isLength({ min: 2 }),
    body('email').trim().notEmpty().isEmail().withMessage('Email inválido.'),
    body('password').notEmpty().isLength({ min: 6 }).withMessage('Senha deve ter >= 6 caracteres.')
];
const validateLogin = () => [ /* ... (código anterior) ... */
    body('email').trim().notEmpty().isEmail().withMessage('Email inválido.'),
    body('password').notEmpty().withMessage('Senha obrigatória.')
];
const validateStore = () => [ /* ... (código anterior) ... */
    body('name').trim().notEmpty().withMessage('Nome da loja obrigatório.').isLength({ min: 3 }),
    body('address').optional({ checkFalsy: true }).trim().isLength({ min: 5 })
];
const validateStockItem = () => [ /* ... (código anterior - ajustado para REAL) ... */
    check('name').trim().notEmpty().withMessage('Nome do item obrigatório.').isLength({ min: 2 }),
    check('quantity').notEmpty().withMessage('Quantidade obrigatória.').isFloat({ min: 0.0 }).withMessage('Quantidade inválida.').toFloat(),
    check('category').optional({ checkFalsy: true }).trim().isString(),
    check('properties').optional().isObject().withMessage('Propriedades devem ser um objeto JSON.'),
    check('properties.barcode').optional({ checkFalsy: true }).isString().trim(),
    check('properties.description').optional({ checkFalsy: true }).isString().trim(),
    // Adicionar validações para outros campos em properties
];

// Validação para parâmetros de ID (reutilizável)
const validateIdParam = (paramName = 'id') => [
    param(paramName).isInt({ min: 1 }).withMessage(`ID inválido para '${paramName}'.`)
];


module.exports = {
    handleValidationErrors, validateRegistration, validateLogin,
    validateStore, validateStockItem, validateIdParam
};