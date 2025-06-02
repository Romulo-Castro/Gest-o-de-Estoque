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


  @override
  Widget build(BuildContext context) {
     // Obtém a loja selecionada para exibir o nome
    final selectedStoreName = context.watch<StoreProvider>().selectedStore?.name ?? "Nenhuma Loja";
     // Obtém o ID da loja para navegação, se necessário diretamente daqui
     final selectedStoreId = context.watch<StoreProvider>().selectedStoreId;

    // Define o número de colunas baseado na largura da tela
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4); // Ex: 2, 3 ou 4 colunas

    return Scaffold(
      // Inclui o Drawer
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Stock e Inventário"), // Título Fixo
        // Opcional: Adicionar ações na AppBar, como busca ou sync
        actions: [
           IconButton(onPressed: () => _showTodoSnackbar(context, "Busca Rápida"), icon: const Icon(Icons.search), tooltip: "Busca Rápida"),
           // Adicionar outros botões se necessário
        ],
      ),
      body: Column(
          children: [
            // --- Seletor de Loja Visível (Opcional) ---
            Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               width: double.infinity,
               color: Colors.grey[200], // Ou cor do tema
               child: Text(
                   "Loja: $selectedStoreName",
                   style: Theme.of(context).textTheme.titleSmall,
                   textAlign: TextAlign.center,
               ),
            ),
             const Divider(height: 1),

             // --- Grid de Cards ---
             Expanded(
                child: GridView.count(
                    crossAxisCount: crossAxisCount, // Número de colunas
                    padding: const EdgeInsets.all(16.0),
                    mainAxisSpacing: 16.0, // Espaçamento vertical
                    crossAxisSpacing: 16.0, // Espaçamento horizontal
                    children: <Widget>[
                      // --- Cards de Funcionalidade ---
                       HomeCard(
                          title: "Mercadorias",
                          icon: Icons.inventory_2_outlined,
                          // Exemplo de subtitle (pode vir de um provider de contagem)
                          // subtitle: "15 itens",
                          onTap: () {
                             // Navega para a StockScreen (que agora está na rota 'home')
                             Navigator.pushNamed(context, AppRoutes.stockList);
                          },
                       ),
                       HomeCard(
                          title: "Documentos",
                          icon: Icons.receipt_long_outlined,
                           // subtitle: "3 novos",
                           iconColor: Colors.orange[700],
                          onTap: () => _showTodoSnackbar(context, "Documentos"), // TODO
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
                          onTap: () => _showTodoSnackbar(context, "Nova Entrada"), // TODO
                       ),
                        HomeCard(
                          title: "Nova Saída",
                          icon: Icons.remove_shopping_cart_outlined,
                           iconColor: Colors.redAccent[700],
                          onTap: () => _showTodoSnackbar(context, "Nova Saída"), // TODO
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
                          onTap: () => _showTodoSnackbar(context, "Clientes"), // TODO
                       ),
                        HomeCard(
                          title: "Fornecedores",
                           icon: Icons.groups_outlined,
                            iconColor: Colors.brown[700],
                          onTap: () => _showTodoSnackbar(context, "Fornecedores"), // TODO
                       ),
                       HomeCard(
                          title: "Configurações",
                           icon: Icons.settings_outlined,
                            iconColor: Colors.grey[700],
                          onTap: () => _showTodoSnackbar(context, "Configurações"), // TODO
                       ),
                        // Adicionar mais cards se necessário

                    ],
                ),
             ),
          ],
       ),
       // Opcional: Adicionar FloatingActionButton para ação rápida (ex: Nova Entrada/Saída)
       // floatingActionButton: FloatingActionButton(...)
    );
  }
}