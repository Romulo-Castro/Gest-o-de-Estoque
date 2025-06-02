// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/main.dart'; // Para AppRoutes
import '/providers/auth_provider.dart';
import '/providers/store_provider.dart';
// Importar outras telas que serão acessadas pelo drawer
// import 'package:gestao_estoque_app/screens/stock_screen.dart';
// import 'package:gestao_estoque_app/screens/documents_screen.dart'; // Exemplo
// import 'package:gestao_estoque_app/screens/settings_screen.dart'; // Exemplo

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // Helper para navegação (fecha drawer antes de navegar)
  void _navigateTo(BuildContext context, String routeName, {Object? arguments}) {
     Navigator.pop(context); // Fecha o drawer
      // Aguarda um frame para evitar problemas de transição
     WidgetsBinding.instance.addPostFrameCallback((_) {
       // Usa pushNamed para rotas nomeadas
       // Se a rota já estiver na pilha, pode usar popAndPushNamed ou similar
       Navigator.pushNamed(context, routeName, arguments: arguments);
     });
  }

   // Helper para mostrar snackbar de TODO
   void _showTodoSnackbar(BuildContext context, String featureName) {
      Navigator.pop(context); // Fecha drawer
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$featureName ainda não implementado."), duration: const Duration(seconds: 2))
      );
   }


  @override
  Widget build(BuildContext context) {
    // Obtém os providers (pode usar read ou watch dependendo da necessidade)
    final authProvider = context.watch<AuthProvider>(); // Watch para reagir ao logout/user
    final storeProvider = context.watch<StoreProvider>(); // Watch para reagir a lojas/seleção
    final user = authProvider.userData;
    final stores = storeProvider.stores;
    final selectedStore = storeProvider.selectedStore;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Cabeçalho com dados do usuário
          UserAccountsDrawerHeader(
            accountName: Text(user?['name'] ?? 'Usuário'),
            accountEmail: Text(user?['email'] ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              child: Text(
                user?['name']?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(fontSize: 40.0, color: Theme.of(context).colorScheme.primary),
              ),
            ),
             decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary, // Cor de fundo do header
            ),
          ),

          // --- Seletor de Loja ---
          ListTile(
             // Mostra a loja selecionada ou "Todas as Lojas" (se implementar) ou "Nenhuma Loja"
            title: Text(selectedStore?.name ?? '- Nenhuma Loja -', style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.arrow_drop_down), // Ícone de dropdown
            onTap: () {
               // Abre diálogo ou navega para tela de seleção/gerenciamento de lojas
               Navigator.pop(context); // Fecha drawer primeiro
               Navigator.pushNamed(context, AppRoutes.storeManagement);
            },
          ),
          // Opcional: Linha divisória
           const Divider(height: 1),

          // --- Menu Principal ---
           const ListTile(
              title: Text('Menu Principal', style: TextStyle(color: Colors.grey, fontSize: 12)),
              dense: true, // Torna menor
           ),
           ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Mercadorias'),
            selected: ModalRoute.of(context)?.settings.name == AppRoutes.home, // Exemplo de seleção
            onTap: () => _navigateTo(context, AppRoutes.home), // Navega para Home (que mostra StockScreen)
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Documentos'),
            onTap: () => _showTodoSnackbar(context, 'Documentos'), // TODO
          ),
           ListTile(
            leading: const Icon(Icons.wallet_outlined), // Ícone diferente para Despesas
            title: const Text('Despesas'),
            onTap: () => _showTodoSnackbar(context, 'Despesas'), // TODO
          ),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('Relatórios'),
            onTap: () => _showTodoSnackbar(context, 'Relatórios'), // TODO
          ),
           const Divider(),
           ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Fornecedores'),
            onTap: () => _showTodoSnackbar(context, 'Fornecedores'), // TODO
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Clientes'),
            onTap: () => _showTodoSnackbar(context, 'Clientes'), // TODO
          ),
           ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('Lojas'),
             selected: ModalRoute.of(context)?.settings.name == AppRoutes.storeManagement,
            onTap: () => _navigateTo(context, AppRoutes.storeManagement),
          ),
           const Divider(),
           ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configurações'),
            onTap: () => _showTodoSnackbar(context, 'Configurações'), // TODO
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ajuda / Suporte'),
            onTap: () => _showTodoSnackbar(context, 'Ajuda'), // TODO
          ),
           // --- Logout ---
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sair', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context); // Fecha drawer ANTES de deslogar
              await context.read<AuthProvider>().logout(); // Usa read para ação
              // AuthWrapper cuidará da navegação para Login
            },
          ),
        ],
      ),
    );
  }
}