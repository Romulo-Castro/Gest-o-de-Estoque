// frontend/lib/screens/supplier_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "/providers/supplier_provider.dart";
import "/providers/store_provider.dart";
import "/screens/edit_supplier_screen.dart";
import "/widgets/app_drawer.dart";

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
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
    final storeProvider = Provider.of<StoreProvider>(context);
    if (storeProvider.selectedStoreId != _currentStoreId) {
      _initializeProviderAndFetchData();
    }
  }

  void _initializeProviderAndFetchData() {
    if (!mounted) return;
    final storeId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
    _currentStoreId = storeId;
    // ★★★ CHAMADA CORRIGIDA ★★★
    Provider.of<SupplierProvider>(context, listen: false).setStoreIdAndFetchIfNeeded(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<StoreProvider>().selectedStoreId;

    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Fornecedores")),
        drawer: const AppDrawer(),
        body: const Center(child: Text("Por favor, selecione uma loja primeiro.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fornecedores"),
        actions: [
          Consumer<SupplierProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : _initializeProviderAndFetchData,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<SupplierProvider>(
        builder: (ctx, supplierProvider, child) {
          if (supplierProvider.isLoading && supplierProvider.suppliers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (supplierProvider.error != null) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Erro: ${supplierProvider.error}"),
                ElevatedButton(onPressed: _initializeProviderAndFetchData, child: const Text("Tentar Novamente")),
              ]),
            );
          }

          if (supplierProvider.suppliers.isEmpty) {
            return const Center(child: Text("Nenhum fornecedor cadastrado."));
          }

          return ListView.builder(
            itemCount: supplierProvider.suppliers.length,
            itemBuilder: (ctx, index) {
              final supplier = supplierProvider.suppliers[index];
              return ListTile(
                leading: CircleAvatar(child: Text(supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : "?")),
                title: Text(supplier.name),
                subtitle: Text(supplier.email ?? supplier.phone ?? "Sem contato"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctxDialog) => AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text("Tem certeza que deseja excluir o fornecedor ${supplier.name}?"),
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
                        await context.read<SupplierProvider>().deleteSupplier(supplier.id);
                        // ★★★ VERIFICAÇÃO mounted ANTES DE USAR CONTEXT ★★★
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Fornecedor excluído!"), backgroundColor: Colors.green),
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
                    MaterialPageRoute(builder: (ctx) => EditSupplierScreen(supplierId: supplier.id)),
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
            MaterialPageRoute(builder: (ctx) => const EditSupplierScreen()),
          );
        },
      ),
    );
  }
}