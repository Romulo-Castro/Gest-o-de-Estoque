// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/main.dart'; // Para AppRoutes
import '/providers/store_provider.dart';
import '/widgets/app_drawer.dart'; // Importar o Drawer
import '/widgets/home_card.dart'; // Importar o Card

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper para mostrar snackbar de TODO
  void _showTodoSnackbar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$featureName ainda não implementado."), duration: const Duration(seconds: 2))
    );
  }

  // Helper para criar uma nova loja
  void _navigateToCreateStore(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.storeManagement, arguments: null);
  }

  // Helper para o conteúdo principal da tela
  Widget _buildBody(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>();

    if (storeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (storeProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Erro ao carregar lojas: ${storeProvider.error}", textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => storeProvider.fetchStores(), child: const Text("Tentar Novamente")),
          ],
        ),
      );
    }

    if (storeProvider.hasNoStores) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Nenhuma loja encontrada.", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Crie sua primeira loja para começar.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_business_outlined),
              label: const Text("Criar Nova Loja"),
              onPressed: () => _navigateToCreateStore(context),
            ),
          ],
        ),
      );
    }

    // Se chegou aqui, tem lojas e não está carregando nem com erro
    final selectedStoreName = storeProvider.selectedStore?.name ?? "Nenhuma Loja Selecionada";
    
    // Se não há loja selecionada mas existem lojas, seleciona a primeira
    if (storeProvider.selectedStore == null && storeProvider.stores.isNotEmpty) {
      // Seleciona a primeira loja automaticamente
      WidgetsBinding.instance.addPostFrameCallback((_) {
        storeProvider.selectStore(storeProvider.stores.first);
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return Column(
      children: [
        // --- Seletor de Loja Visível ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          color: Colors.grey[200], // Ou cor do tema
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  "Loja: $selectedStoreName",
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Selecionar Loja"),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: storeProvider.stores.length,
                          itemBuilder: (ctx, index) {
                            final store = storeProvider.stores[index];
                            final isSelected = store.id == storeProvider.selectedStoreId;
                            return ListTile(
                              title: Text(store.name),
                              subtitle: store.address != null && store.address!.isNotEmpty 
                                ? Text(store.address!) 
                                : null,
                              selected: isSelected,
                              leading: isSelected 
                                ? const Icon(Icons.check_circle, color: Colors.green) 
                                : const Icon(Icons.store_outlined),
                              onTap: () {
                                storeProvider.selectStore(store);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => _navigateToCreateStore(context),
                          child: const Text("Nova Loja"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // --- Grid de Cards ---
        Expanded(
          child: GridView.count(
            crossAxisCount: crossAxisCount,
            padding: const EdgeInsets.all(16.0),
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            children: <Widget>[
              // --- Cards de Funcionalidade ---
              HomeCard(
                title: "Mercadorias",
                icon: Icons.inventory_2_outlined,
                onTap: () {
                  if (storeProvider.selectedStoreId == null) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Selecione uma loja primeiro."))
                     );
                     return;
                  }
                  Navigator.pushNamed(context, AppRoutes.stockList);
                },
              ),
              HomeCard(
                title: "Documentos",
                icon: Icons.receipt_long_outlined,
                iconColor: Colors.orange[700],
                onTap: () => Navigator.pushNamed(context, AppRoutes.documentList),
              ),
              HomeCard(
                title: "Relatórios",
                icon: Icons.assessment_outlined,
                iconColor: Colors.blue[700],
                onTap: () => _showTodoSnackbar(context, "Relatórios"), // TODO
              ),
              HomeCard(
                title: "Despesas",
                icon: Icons.wallet_outlined,
                iconColor: Colors.red[700],
                onTap: () => _showTodoSnackbar(context, "Despesas"), // TODO
              ),
              HomeCard(
                title: "Nova Entrada",
                icon: Icons.add_shopping_cart_outlined,
                iconColor: Colors.green[700],
                onTap: () => Navigator.pushNamed(
                  context, 
                  AppRoutes.editDocument, 
                  arguments: {'type': 'ENTRADA'}
                ),
              ),
              HomeCard(
                title: "Nova Saída",
                icon: Icons.remove_shopping_cart_outlined,
                iconColor: Colors.redAccent[700],
                onTap: () => Navigator.pushNamed(
                  context, 
                  AppRoutes.editDocument, 
                  arguments: {'type': 'SAIDA'}
                ),
              ),
              HomeCard(
                title: "Ler Código",
                icon: Icons.qr_code_scanner_outlined,
                iconColor: Colors.purple[700],
                onTap: () => _showTodoSnackbar(context, "Leitor de Código"), // TODO
              ),
              HomeCard(
                title: "Ajuda",
                icon: Icons.help_outline_outlined,
                iconColor: Colors.teal[700],
                onTap: () => _showTodoSnackbar(context, "Ajuda"), // TODO
              ),
              HomeCard(
                title: "Clientes",
                icon: Icons.people_alt_outlined,
                iconColor: Colors.lightBlue[700],
                onTap: () => Navigator.pushNamed(context, AppRoutes.customerList),
              ),
              HomeCard(
                title: "Fornecedores",
                icon: Icons.groups_outlined,
                iconColor: Colors.brown[700],
                onTap: () => Navigator.pushNamed(context, AppRoutes.supplierList),
              ),
              HomeCard(
                title: "Grupos",
                icon: Icons.category_outlined,
                iconColor: Colors.amber[700],
                onTap: () => Navigator.pushNamed(context, AppRoutes.itemGroupList),
              ),
              HomeCard(
                title: "Configurações",
                icon: Icons.settings_outlined,
                iconColor: Colors.grey[700],
                onTap: () => _showTodoSnackbar(context, "Configurações"), // TODO
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Stock e Inventário"),
        actions: [
          IconButton(onPressed: () => _showTodoSnackbar(context, "Busca Rápida"), icon: const Icon(Icons.search), tooltip: "Busca Rápida"),
        ],
      ),
      body: _buildBody(context), // Chama o helper para construir o corpo
    );
  }
}
