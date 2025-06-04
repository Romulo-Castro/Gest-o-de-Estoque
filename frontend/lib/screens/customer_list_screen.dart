// frontend/lib/screens/customer_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/providers/customer_provider.dart";
import "/providers/store_provider.dart";
import "/screens/edit_customer_screen.dart";
import "/widgets/app_drawer.dart";

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  int? _currentStoreId; // Para rastrear a loja atual

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviderAndFetchData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storeProvider = Provider.of<StoreProvider>(context); // Pode escutar aqui
    if (storeProvider.selectedStoreId != _currentStoreId) {
      _initializeProviderAndFetchData();
    }
  }

  void _initializeProviderAndFetchData() {
    if (!mounted) return;
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    _currentStoreId = storeId; // Atualiza o ID rastreado
    // ★★★ CHAMADA CORRIGIDA ★★★
    Provider.of<CustomerProvider>(context, listen: false).setStoreIdAndFetchIfNeeded(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStoreId;
    // Não precisamos chamar setStoreIdAndFetchIfNeeded aqui, pois didChangeDependencies e initState cuidam disso.

    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Clientes")),
        drawer: const AppDrawer(),
        body: const Center(child: Text("Por favor, selecione uma loja primeiro.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clientes"),
        actions: [
          Consumer<CustomerProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : _initializeProviderAndFetchData, // Chama o método de inicialização
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<CustomerProvider>(
        builder: (ctx, customerProvider, child) {
          if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customerProvider.error != null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Erro: ${customerProvider.error}"),
                ElevatedButton(onPressed: _initializeProviderAndFetchData, child: const Text("Tentar Novamente")),
              ]),
            );
          }

          if (customerProvider.customers.isEmpty) {
            return const Center(child: Text("Nenhum cliente cadastrado."));
          }

          return ListView.builder(
            itemCount: customerProvider.customers.length,
            itemBuilder: (ctx, index) {
              final customer = customerProvider.customers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "?")),
                title: Text(customer.name),
                subtitle: Text(customer.email ?? customer.phone ?? "Sem contato"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctxDialog) => AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text("Tem certeza que deseja excluir o cliente ${customer.name}?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctxDialog).pop(false), child: const Text("Cancelar")),
                          TextButton(onPressed: () => Navigator.of(ctxDialog).pop(true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR CONTEXT ★★★
                    if (confirm == true && mounted) {
                      try {
                        // Usa context.read para a ação
                        await context.read<CustomerProvider>().deleteCustomer(customer.id);
                        // ★★★ VERIFICAÇÃO mounted ANTES DE USAR CONTEXT ★★★
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Cliente excluído!"), backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        // ★★★ VERIFICAÇÃO mounted ANTES DE USAR CONTEXT ★★★
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erro ao excluir: $e"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => EditCustomerScreen(customerId: customer.id)),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const EditCustomerScreen()),
          );
        },
      ),
    );
  }
}