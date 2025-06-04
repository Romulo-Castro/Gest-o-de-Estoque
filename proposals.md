# Proposta de Melhorias e Novas Funcionalidades - App Gestão de Estoque

Com base na análise detalhada do código-fonte (resumida em `analysis_report.md`), propomos o seguinte conjunto de melhorias e novas funcionalidades para tornar o aplicativo de gestão de estoque mais completo, robusto e fácil de usar.

## I. Implementação de Funcionalidades Essenciais (Prioridade Alta)

Estas são as funcionalidades centrais que estão ausentes e são cruciais para um sistema de gestão de estoque funcional.

1.  **Módulo de Documentos (Entrada/Saída/Ajuste):**
    *   **Backend:** Criar APIs (rotas, controllers, funções de DB com transações) para registrar documentos de compra, venda, ajuste de entrada e ajuste de saída. Cada documento deve referenciar um cliente ou fornecedor (quando aplicável) e conter múltiplos itens (`document_items`) com suas respectivas quantidades e preços (se aplicável). A criação/atualização/deleção de um documento deve **atomicamente** ajustar as quantidades no `stock_items`.
    *   **Frontend:** Criar telas para listar, visualizar, criar e editar documentos. Implementar formulários intuitivos para adicionar itens ao documento, buscando produtos existentes no estoque. Desenvolver a lógica nos providers para gerenciar o estado dos documentos.

2.  **Módulo de Clientes e Fornecedores:**
    *   **Backend:** As APIs básicas de CRUD já existem em `database.js`, mas precisam ser expostas via rotas e controllers dedicados (ex: `/api/stores/:storeId/customers`, `/api/stores/:storeId/suppliers`). Garantir validação e tratamento de erros adequados.
    *   **Frontend:** Criar telas para listar, visualizar, criar, editar e excluir clientes e fornecedores associados à loja selecionada. Integrar com o módulo de documentos para seleção de cliente/fornecedor.

3.  **Módulo de Grupos/Categorias de Itens:**
    *   **Backend:** Implementar APIs para CRUD de `item_groups`, permitindo a criação de hierarquias (usando `parent_group_id`). Associar `stock_items` a esses grupos.
    *   **Frontend:** Permitir a visualização e gerenciamento de grupos/categorias. Na tela de estoque (`StockScreen`), adicionar a opção de filtrar/navegar por grupo. No formulário de edição de item (`EditStockItemScreen`), permitir a seleção de um grupo.

4.  **Módulo de Despesas:**
    *   **Backend:** Criar APIs para CRUD de `expenses`, associando cada despesa à loja.
    *   **Frontend:** Criar tela para registrar e listar despesas da loja, permitindo filtros por data ou categoria.

5.  **API de Deleção de Imagem:**
    *   **Backend:** Criar um endpoint (ex: `DELETE /api/stores/:storeId/stock/:itemId/image`) que remova a referência `image_filename` do item no banco de dados e delete o arquivo físico correspondente no diretório de uploads.
    *   **Frontend:** Chamar esta API a partir do `EditStockItemScreen` quando o usuário remover a imagem e salvar o item.

## II. Melhorias Técnicas e de Robustez (Prioridade Média)

Estas melhorias visam aumentar a confiabilidade, segurança e manutenibilidade do sistema.

1.  **Gerenciamento de Funções e Permissões (Backend):**
    *   Implementar verificações de `role` (`owner`, `manager`, `staff`) nos controllers do backend para ações sensíveis (ex: editar/deletar loja, adicionar/remover usuários da loja, talvez deletar itens/documentos).
    *   Criar APIs para gerenciamento de usuários em uma loja (convidar, definir role, remover) - *Nova Funcionalidade*.

2.  **Transações Explícitas (Backend):**
    *   Implementar funções auxiliares `beginTransaction`, `commitTransaction`, `rollbackTransaction` em `database.js`.
    *   Utilizar transações em todas as operações que envolvam múltiplas escritas interdependentes (CRUD de documentos, criação/deleção de loja, etc.).

3.  **Tratamento de Erros Aprimorado:**
    *   **Backend:** Refinar o middleware de erro genérico para identificar tipos específicos de erro (SQLite, validação, etc.) e retornar códigos de status HTTP e mensagens de erro mais significativas e consistentes.
    *   **Frontend:** No `ApiService` e nos Providers, capturar e interpretar melhor os erros da API, exibindo mensagens mais claras e úteis para o usuário na UI, em vez de apenas `e.toString()`.

4.  **Refatoração e Simplificação (Frontend):**
    *   Analisar a lógica de estado em `StockScreen` e `EditStockItemScreen`. Avaliar a extração de lógica para providers dedicados (ex: `StockProvider` para gerenciar a lista de itens da loja selecionada) para reduzir a complexidade dos widgets `StatefulWidget`.
    *   Otimizar o recarregamento de dados: Ao salvar/deletar um item, atualizar a lista local no provider em vez de recarregar toda a lista da API, melhorando a performance percebida.

5.  **Validação de Dados (Backend):**
    *   Aprimorar a validação do campo `properties` (JSON) no backend, talvez definindo um esquema esperado ou regras mais estritas no `express-validator` para garantir a integridade dos dados.

## III. Melhorias de Experiência do Usuário (UX) e Funcionalidades Adicionais (Prioridade Média/Baixa)

Estas melhorias focam em tornar o aplicativo mais agradável e eficiente de usar.

1.  **Busca, Filtro e Ordenação (Frontend):**
    *   Implementar uma barra de busca na `StockScreen` para filtrar itens por nome ou outras propriedades.
    *   Adicionar opções para ordenar a lista de itens (por nome, quantidade, data de atualização).
    *   Implementar filtros semelhantes nas futuras telas de Documentos, Clientes, Fornecedores.

2.  **Leitor de Código de Barras (Frontend):**
    *   Integrar um pacote Flutter de leitura de código de barras (ex: `barcode_scan2` ou similar).
    *   Implementar a funcionalidade no `HomeCard` "Ler Código" para abrir o scanner.
    *   Ao escanear um código, buscar o item correspondente no estoque (requer que o código de barras seja armazenado em `properties`) e/ou permitir adicionar rapidamente a um documento de entrada/saída.

3.  **Feedback Visual Aprimorado (Frontend):**
    *   Utilizar indicadores de progresso mais contextuais (ex: dentro de botões, shimmer effect em listas) durante o carregamento de dados.
    *   Melhorar a apresentação de mensagens de sucesso e erro (ex: usando Toasts ou Snackbars mais informativos).

4.  **Suporte Offline/Cache (Frontend):**
    *   Implementar um cache local básico (ex: usando `sqflite` no frontend ou pacotes de cache como `hive`) para os dados das lojas e itens de estoque. Isso permitiria visualizar dados mesmo offline e melhoraria a velocidade de carregamento inicial.
    *   Desenvolver uma estratégia de sincronização para atualizar o cache quando online.

5.  **Relatórios Básicos:**
    *   **Backend & Frontend:** Implementar relatórios simples iniciais, como: Valor total do estoque, Itens abaixo do estoque mínimo, Histórico de movimentação de um item, Resumo de vendas/compras por período.

6.  **Configurações:**
    *   **Backend & Frontend:** Criar tela de configurações para permitir ao usuário gerenciar preferências (como as propriedades ativas dos itens, casas decimais - já parcialmente feito com `AppPrefs`), e potencialmente configurações da loja (se for `owner`/`manager`).

7.  **Testes Automatizados:**
    *   Adicionar testes unitários para a lógica de negócios nos providers e serviços.
    *   Adicionar testes de widget para as telas principais.
    *   Adicionar testes de integração para os fluxos críticos (login, CRUD de itens, etc.).

## Próximos Passos Sugeridos

Recomendamos focar inicialmente na **Prioridade Alta (Funcionalidades Essenciais)**, começando pelo Módulo de Documentos, que é central para a gestão de estoque. Em paralelo ou na sequência, abordar as melhorias técnicas de **Prioridade Média**, especialmente o Gerenciamento de Funções/Permissões e Transações no backend, pois impactam a segurança e a integridade dos dados das funcionalidades essenciais.

As melhorias de UX e funcionalidades adicionais podem ser implementadas iterativamente após a conclusão das funcionalidades essenciais.
