# Relatório de Análise e Levantamento de Melhorias - App Gestão de Estoque

## Introdução

Este documento apresenta uma análise detalhada do código-fonte do projeto "Gestão de Estoque", clonado a partir do repositório GitHub fornecido (`https://github.com/Romulo-Castro/Gest-o-de-Estoque.git`). O objetivo desta análise é compreender a arquitetura atual, identificar funcionalidades implementadas, pontos pendentes (marcados como TODO ou implícitos), áreas de melhoria e oportunidades para novas funcionalidades, conforme solicitado.

A análise abrange tanto o backend, desenvolvido em Node.js com Express e utilizando SQLite como banco de dados, quanto o frontend, desenvolvido em Flutter e utilizando o Provider para gerenciamento de estado.

## Análise do Backend (Node.js/Express/SQLite)

O backend demonstra uma estrutura organizada, seguindo padrões comuns em aplicações Express, com separação de responsabilidades em rotas, controladores, middlewares e uma camada de acesso a dados. A utilização de `dotenv` para configuração, `cors` para permissões de acesso e `bcryptjs` para hashing de senhas são boas práticas observadas.

**Estrutura e Pontos Positivos:**

*   **Organização:** A divisão em diretórios `controllers`, `routes`, `middleware` e `data` facilita a manutenção e compreensão do código.
*   **Rotas:** O aninhamento de rotas (ex: `stockRoutes` dentro de `storeRoutes`) é bem implementado, utilizando `mergeParams: true` corretamente.
*   **Autenticação:** A autenticação via JWT (`jsonwebtoken`) está implementada, com middleware (`authenticateToken`) para proteger rotas e verificação de acesso por loja (`checkStoreAccessMiddleware`, `checkStoreAccess`).
*   **Validação:** O uso de `express-validator` (`validators.js`) para validar entradas nas rotas de autenticação e estoque adiciona uma camada importante de segurança e consistência de dados.
*   **Upload de Imagens:** O middleware `uploadMiddleware.js` utiliza `multer` para lidar com uploads de imagens de produtos, incluindo criação de diretório, geração de nomes únicos e filtro básico por tipo de arquivo (imagem).
*   **Banco de Dados:** O arquivo `database.js` centraliza a interação com o SQLite, utilizando `sqlite3`. Ele inclui funções para conectar, criar tabelas (com `PRAGMA foreign_keys = ON;` habilitado) e funções específicas para CRUD de usuários, lojas, itens de estoque, clientes e fornecedores. O uso de `async/await` e funções auxiliares (`runQuery`, `getQuery`, `allQuery`) torna o código mais legível.

**Pontos de Atenção e Melhorias:**

*   **Funcionalidades Incompletas:** As tabelas para `item_groups`, `documents` (vendas, compras, ajustes), `document_items` e `expenses` foram definidas no `database.js`, mas as APIs (rotas, controllers, funções de DB) para manipulá-las não estão implementadas ou estão apenas esboçadas (como a função `createDocumentAndAdjustStock`). Esta é a maior lacuna funcional do backend.
*   **Gerenciamento de Transações:** A função `createDocumentAndAdjustStock` corretamente identifica a necessidade de uma transação (`BEGIN TRANSACTION`, `COMMIT`, `ROLLBACK`) para garantir a atomicidade da criação de um documento e o ajuste do estoque. No entanto, as funções auxiliares para iniciar, commitar e reverter transações não foram implementadas no `database.js`. Além disso, outras operações que modificam múltiplos registros relacionados (como criar loja e adicionar owner, ou deletar loja com `ON DELETE CASCADE`) poderiam se beneficiar de transações explícitas para maior robustez.
*   **Tratamento de Erros:** O tratamento de erros é básico. O `server.js` possui um middleware genérico de erro, mas poderia ser aprimorado para lidar com tipos específicos de erro (ex: erros de validação, erros do SQLite como `SQLITE_CONSTRAINT`) de forma mais granular, retornando códigos de status e mensagens mais informativas para o frontend. A função `deleteStockItem` tenta tratar `SQLITE_CONSTRAINT_FOREIGNKEY`, o que é bom, mas essa abordagem poderia ser padronizada.
*   **Segurança e Permissões:** A verificação de permissão (`checkStoreAccessMiddleware`) garante que um usuário só acesse dados de lojas às quais pertence. No entanto, dentro de uma loja, as permissões baseadas em `role` (`owner`, `manager`, `staff`) não são consistentemente verificadas. Por exemplo, `updateStore` e `deleteStore` possuem comentários indicando a necessidade de verificar se o usuário é `owner` ou `manager`, mas a lógica não está implementada.
*   **TODOs no Código:** Existem comentários `TODO` explícitos, como a necessidade de implementar a deleção de imagem no backend quando ela é removida no frontend (`edit_stock_item_screen.dart` menciona isso, implicando uma API faltante no backend).
*   **Consistência de Dados:** A validação de `properties` nos controllers (`stockController.js`) é básica. Uma validação mais robusta, talvez usando esquemas ou regras mais detalhadas no `express-validator`, poderia garantir maior consistência dos dados armazenados como JSON.
*   **Mock Database:** Existe um arquivo `mockDatabase.js` que parece não estar sendo utilizado ativamente, dado que `database.js` implementa a lógica com SQLite. Seria bom remover ou clarificar seu propósito.

## Análise do Frontend (Flutter)

O frontend em Flutter utiliza o Provider para gerenciamento de estado, `http` para comunicação com a API, e `flutter_secure_storage` para persistência segura do token e dados do usuário. A estrutura segue uma organização padrão com `models`, `providers`, `screens`, `services`, `utils` e `widgets`.

**Estrutura e Pontos Positivos:**

*   **Gerenciamento de Estado:** O uso do Provider (`AuthProvider`, `StoreProvider`) e `ChangeNotifierProxyProvider` para gerenciar o estado de autenticação e dados das lojas é adequado, permitindo que a UI reaja às mudanças de estado.
*   **Estrutura de Navegação:** O uso de rotas nomeadas (`AppRoutes` em `main.dart`) e um `AuthWrapper` para controlar o fluxo inicial (Login vs. Welcome/Home) é uma boa prática.
*   **UI:** A aplicação utiliza Material 3 e possui um tema customizado (`ThemeData` em `main.dart`), proporcionando uma base visual consistente. A `HomeScreen` utiliza um `GridView` responsivo e `HomeCard`s para apresentar as funcionalidades. A `StockScreen` oferece layouts de lista e grid (`_useCardLayout`).
*   **Interação com API:** O `ApiService` encapsula a lógica de comunicação com o backend, tratando a adição de headers (incluindo token), codificação/decodificação JSON e tratamento básico de erros HTTP e de conexão.
*   **Persistência:** O uso de `flutter_secure_storage` para o token JWT e dados básicos do usuário, e `shared_preferences` (via `AppPrefs`) para preferências de UI (layout, casas decimais, campos ativos) é apropriado.
*   **Edição de Itens:** A tela `EditStockItemScreen` demonstra uma lógica complexa para lidar com campos dinâmicos baseados nas preferências (`AppPrefs.getItemProperties`), incluindo upload/seleção de imagem.

**Pontos de Atenção e Melhorias:**

*   **Funcionalidades Ausentes/TODOs:** A `HomeScreen` e o `AppDrawer` estão repletos de funcionalidades marcadas como não implementadas através de `_showTodoSnackbar`. Isso inclui módulos cruciais como Documentos, Relatórios, Despesas, Nova Entrada/Saída, Leitor de Código, Clientes, Fornecedores e Configurações. A implementação dessas telas e suas integrações com a API (que também precisa ser criada no backend) é a principal pendência.
*   **Complexidade em `StockScreen` e `EditStockItemScreen`:** Essas telas contêm lógica complexa para gerenciar estado local (`_isLoading`, `_errorMessage`, `_stockItems`, controllers), lidar com mudanças no `StoreProvider` (`_storeChangeListener`), garantir a presença do token (`_ensureApiServiceToken`) e gerenciar o ciclo de vida (`initState`, `didChangeDependencies`, `dispose`). Há múltiplas verificações `if (mounted)` para evitar erros após `await`, o que é correto, mas indica a complexidade. Refatorar essa lógica, talvez extraindo partes para outros providers ou usando abordagens de gerenciamento de estado mais avançadas (como Riverpod ou Bloc, embora Provider seja suficiente se bem estruturado), poderia simplificar o código.
*   **Gerenciamento de Erros:** O tratamento de erros no `ApiService` é básico. Erros específicos da API (como validação, permissão negada, item não encontrado) poderiam ser tratados de forma mais granular no frontend para exibir mensagens mais úteis ao usuário, em vez de apenas `e.toString()`.
*   **Feedback Visual:** O feedback de loading e erro é implementado (ex: `CircularProgressIndicator`, `_errorMessage`), mas poderia ser aprimorado. Por exemplo, desabilitar botões durante o loading é feito, mas indicadores de progresso mais específicos (ex: em um botão de salvar) poderiam melhorar a UX.
*   **Upload/Deleção de Imagem:** O upload de imagem está implementado em `EditStockItemScreen`, mas a deleção da imagem no backend é um TODO explícito. A lógica de exibir a imagem (local vs. rede) e tratar erros de carregamento também está presente.
*   **Campos Dinâmicos:** A lógica para lidar com propriedades dinâmicas em `EditStockItemScreen` funciona, mas depende muito de `AppPrefs`. Uma abordagem mais robusta poderia envolver a definição desses campos no backend ou um sistema de configuração mais flexível.
*   **Navegação e Estado:** Ao navegar para `EditStockItemScreen` e retornar `true` (indicando sucesso), a `StockScreen` recarrega toda a lista. Para operações de atualização, seria mais eficiente atualizar apenas o item modificado na lista local, ou buscar apenas o item atualizado da API, em vez de recarregar tudo.
*   **Offline/Cache:** Não há indicação de suporte offline ou cache de dados. Para uma melhor experiência, especialmente em conexões instáveis, implementar algum nível de cache (ex: usando `sqflite` no frontend ou pacotes de cache) seria uma melhoria significativa.
*   **Testes:** Não há arquivos de teste visíveis no repositório. Adicionar testes unitários, de widget e de integração aumentaria a confiabilidade do código.

## Consolidação de TODOs e Funcionalidades Pendentes

Baseado na análise, os principais pontos pendentes são:

1.  **Módulos Principais Faltantes:** Implementação completa (Backend API + Frontend Telas/Providers) para: Documentos (Entrada/Saída/Ajuste), Relatórios, Despesas, Clientes, Fornecedores, Grupos de Itens, Configurações da Aplicação/Loja.
2.  **API de Deleção de Imagem:** Criar o endpoint no backend para remover a `image_filename` de um `stock_item` e deletar o arquivo físico, e chamar essa API a partir do `EditStockItemScreen` no frontend.
3.  **Gerenciamento de Funções/Permissões:** Implementar verificações de `role` (`owner`, `manager`, `staff`) no backend para restringir ações como edição/deleção de lojas, gerenciamento de usuários na loja (funcionalidade também pendente), etc.
4.  **Transações no Backend:** Implementar funções auxiliares para transações no `database.js` e utilizá-las em operações críticas (criação de documentos, criação/deleção de lojas).
5.  **Melhorias no Tratamento de Erros:** Detalhar o tratamento de erros tanto no backend (códigos/mensagens específicas) quanto no frontend (exibição granular para o usuário).
6.  **Funcionalidades da HomeScreen:** Implementar as ações associadas aos `HomeCard`s que atualmente exibem `_showTodoSnackbar`.
7.  **Busca, Filtro e Ordenação:** Implementar funcionalidades de busca, filtro e ordenação na `StockScreen` e potencialmente em outras listas (Lojas, Documentos, etc.).
8.  **Leitor de Código de Barras:** Implementar a funcionalidade associada ao `HomeCard` "Ler Código".

## Conclusão e Próximos Passos

O projeto possui uma base sólida tanto no backend quanto no frontend, com boas práticas de organização e uso de tecnologias adequadas. No entanto, há um número significativo de funcionalidades essenciais para um sistema de gestão de estoque que ainda precisam ser implementadas. A prioridade deve ser a conclusão dos módulos principais (Documentos, Clientes, Fornecedores, etc.) e a resolução dos TODOs técnicos identificados (deleção de imagem, transações, permissões).

O próximo passo, conforme o plano, será propor um conjunto de melhorias e novas funcionalidades detalhadas, priorizando as pendências mais críticas e oportunidades de aprimoramento da experiência do usuário e da robustez do sistema.
