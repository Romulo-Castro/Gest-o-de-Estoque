# Lista de Tarefas - Aprimoramento do Sistema de Gestão de Estoques

## Correções e Implementações Concluídas

### Frontend
- [x] Corrigir fluxo de seleção de loja após o login
- [x] Implementar navegação para a tela de criação de loja quando não houver lojas disponíveis
- [x] Corrigir erros de valores nulos em document_provider.dart
- [x] Remover imports não utilizados em todos os arquivos
- [x] Implementar filtros na tela de documentos
- [x] Implementar método deleteItemImage no ApiService
- [x] Corrigir orElse em edit_stock_item_screen.dart para retornar ItemGroup? explicitamente
- [x] Implementar fetchDocumentsWithFilters no DocumentProvider
- [x] Implementar método para remover imagem do item no ApiService
- [x] Atualizar assinaturas dos métodos de ItemGroup para usar objetos completos
- [x] Implementar diálogo de filtros na tela de documentos
- [x] Corrigir problemas de nulidade em todos os providers

### Backend
- [x] Validar rotas de grupos de itens
- [x] Implementar endpoint para remover imagem de item
- [x] Implementar filtros na API de documentos

## Melhorias Adicionais
- [x] Padronizar todos os providers para uso com ProxyProvider
- [x] Implementar métodos updateAuthToken e setStoreId em todos os providers
- [x] Eliminar instâncias locais conflitantes de providers nas telas
- [x] Adicionar dependência intl no pubspec.yaml para formatação de datas
- [x] Melhorar tratamento de erros em todas as chamadas de API

## Funcionalidades Completas e Validadas
- [x] Autenticação e gerenciamento de usuários
- [x] Gerenciamento de lojas
- [x] Gerenciamento de estoque
- [x] Grupos de itens
- [x] Clientes e fornecedores
- [x] Documentos (entrada/saída/ajuste)

## Próximos Passos (Baixa Prioridade)
- [ ] Implementar relatórios básicos
- [ ] Adicionar tela de configurações avançadas
- [ ] Integrar leitor de código de barras
- [ ] Adicionar testes automatizados
