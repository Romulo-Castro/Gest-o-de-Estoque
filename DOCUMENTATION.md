# Documentação do Projeto: Gestão de Estoques

## Visão Geral

O sistema de Gestão de Estoques é uma aplicação completa para gerenciamento de inventário, clientes, fornecedores e movimentações de estoque. Desenvolvido com Flutter (frontend) e Node.js (backend), o sistema oferece uma solução robusta e escalável para pequenos e médios negócios.

## Arquitetura

### Frontend (Flutter)
- **Linguagem**: Dart
- **Framework**: Flutter
- **Padrão de Arquitetura**: Provider para gerenciamento de estado
- **Principais Dependências**:
  - provider: Gerenciamento de estado
  - http: Comunicação com API
  - shared_preferences: Armazenamento local
  - intl: Formatação de datas e números
  - image_picker: Seleção de imagens

### Backend (Node.js)
- **Linguagem**: JavaScript
- **Framework**: Express.js
- **Banco de Dados**: MySQL
- **Autenticação**: JWT (JSON Web Tokens)
- **Principais Dependências**:
  - express: Framework web
  - mysql2: Conexão com banco de dados
  - jsonwebtoken: Autenticação
  - bcrypt: Criptografia de senhas
  - multer: Upload de arquivos

## Funcionalidades Principais

### 1. Autenticação e Usuários
- Registro de novos usuários
- Login com email e senha
- Autenticação via JWT
- Proteção de rotas

### 2. Gerenciamento de Lojas
- Criação, edição e exclusão de lojas
- Seleção de loja ativa
- Associação de usuários a lojas

### 3. Gerenciamento de Estoque
- Cadastro de itens com propriedades customizáveis
- Controle de quantidade
- Upload de imagens para itens
- Organização por grupos de itens

### 4. Clientes e Fornecedores
- Cadastro completo de clientes
- Cadastro completo de fornecedores
- Associação com documentos

### 5. Documentos de Movimentação
- Entrada de produtos
- Saída de produtos
- Ajustes de estoque (positivos e negativos)
- Cancelamento de documentos com reversão automática

### 6. Grupos de Itens
- Organização hierárquica de produtos
- Categorização para relatórios e filtros

## Configuração e Instalação

### Requisitos
- Node.js 14+ (backend)
- Flutter 3.0+ (frontend)
- MySQL 8.0+ (banco de dados)

### Backend
1. Navegue até a pasta `backend`
2. Execute `npm install` para instalar as dependências
3. Configure o arquivo `.env` com as credenciais do banco de dados:
   ```
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=sua_senha
   DB_NAME=gestao_estoque
   JWT_SECRET=seu_segredo_jwt
   PORT=3000
   ```
4. Execute `npm run dev` para iniciar o servidor em modo de desenvolvimento

### Frontend
1. Navegue até a pasta `frontend`
2. Execute `flutter pub get` para instalar as dependências
3. Configure o arquivo `lib/services/api_service.dart` com o endereço correto do backend:
   ```dart
   static const String _baseUrl = 'http://seu_ip:3000/api';
   ```
4. Execute `flutter run` para iniciar o aplicativo

## Estrutura de Diretórios

### Backend
```
backend/
├── src/
│   ├── controllers/     # Controladores de rotas
│   ├── middleware/      # Middlewares (auth, upload, etc.)
│   ├── routes/          # Definição de rotas
│   ├── data/            # Conexão com banco de dados
│   └── server.js        # Ponto de entrada
├── .env                 # Variáveis de ambiente
└── package.json         # Dependências
```

### Frontend
```
frontend/
├── lib/
│   ├── models/          # Modelos de dados
│   ├── providers/       # Gerenciamento de estado
│   ├── screens/         # Telas da aplicação
│   ├── services/        # Serviços (API, etc.)
│   ├── utils/           # Utilitários
│   ├── widgets/         # Componentes reutilizáveis
│   └── main.dart        # Ponto de entrada
└── pubspec.yaml         # Dependências
```

## Fluxos de Uso

### Fluxo de Autenticação
1. Usuário acessa a tela de login
2. Insere credenciais (email e senha)
3. Sistema valida e gera token JWT
4. Token é armazenado localmente
5. Usuário é redirecionado para a tela inicial

### Fluxo de Seleção de Loja
1. Após login, usuário é direcionado para a tela de seleção de loja
2. Se não houver lojas, é apresentada opção para criar uma nova
3. Ao selecionar uma loja, o ID é armazenado e usado em todas as operações

### Fluxo de Gestão de Estoque
1. Usuário acessa a tela de estoque
2. Visualiza lista de itens da loja selecionada
3. Pode adicionar, editar ou excluir itens
4. Pode associar itens a grupos para melhor organização

### Fluxo de Documentos
1. Usuário acessa a tela de documentos
2. Cria novo documento (entrada, saída ou ajuste)
3. Adiciona itens ao documento
4. Finaliza o documento, atualizando automaticamente o estoque
5. Pode visualizar histórico de documentos e filtrar por tipo ou data

## Melhorias Recentes

### Correções de Bugs
- Corrigido fluxo de seleção de loja após o login
- Resolvidos problemas de valores nulos em diversos providers
- Corrigidos erros de compilação relacionados a tipos nulos
- Implementada verificação adequada de nulidade em todos os componentes

### Novas Funcionalidades
- Implementados filtros na tela de documentos (tipo, data, cliente, fornecedor)
- Adicionada funcionalidade para remover imagens de itens
- Melhorada integração entre grupos de itens e produtos
- Implementada navegação direta para criação de loja quando necessário

### Otimizações
- Padronizados todos os providers para uso com ProxyProvider
- Implementados métodos updateAuthToken e setStoreId em todos os providers
- Eliminadas instâncias locais conflitantes de providers nas telas
- Melhorado tratamento de erros em todas as chamadas de API

## Próximos Passos

### Melhorias Planejadas
- Implementação de relatórios básicos
- Adição de tela de configurações avançadas
- Integração com leitor de código de barras
- Desenvolvimento de testes automatizados

## Suporte e Contato

Para suporte técnico ou dúvidas sobre o sistema, entre em contato através do email: suporte@gestaodeestoques.com.br
