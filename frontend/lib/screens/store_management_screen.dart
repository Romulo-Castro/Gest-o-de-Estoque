// lib/screens/store_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/store_model.dart';
import '/providers/store_provider.dart';
import '/screens/edit_store_screen.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      if (storeProvider.stores.isEmpty && !storeProvider.isLoading) {
        _fetchStores();
      }
    });
  }

  Future<void> _fetchStores() async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
    if (!mounted) return;
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    try {
      await storeProvider.fetchStores();
    } catch (e) {
       // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
      if(mounted) _showErrorSnackbar(context, "Erro ao buscar lojas: $e");
    }
  }

  Future<void> _navigateToEditStore({Store? store}) async {
     // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
     if (!mounted) return;
    // Não precisamos do resultado aqui, provider atualiza
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditStoreScreen(initialStore: store)),
    );
  }

  Future<void> _confirmDeleteStore(Store store) async {
     // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context para showDialog ★★★
     if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog( /* ... Diálogo ... */
          title: const Text('Confirmar Exclusão'), content: Text('Excluir loja "${store.name}"?\nTODOS os dados serão perdidos!'),
          actions: <Widget>[ TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(ctx).pop(false)), TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir'), onPressed: () => Navigator.of(ctx).pop(true)),],
      ),
    );

    if (confirmed == true) { // Não precisa checar mounted aqui pois showDialog só retorna se ainda montado
        final storeProvider = context.read<StoreProvider>(); // Usa read para ação
        final scaffoldMessenger = ScaffoldMessenger.of(context); // Guarda para usar depois do await
         scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Excluindo loja..."), duration: Duration(seconds: 5)));
        try {
            await storeProvider.deleteStore(store.id); // await
            // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context (scaffoldMessenger) ★★★
            if (mounted) {
               scaffoldMessenger.removeCurrentSnackBar();
               _showSuccessSnackbar(context, "Loja excluída com sucesso.");
            }
        } catch (e) {
             // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context (scaffoldMessenger) ★★★
            if (mounted) {
               scaffoldMessenger.removeCurrentSnackBar();
               _showErrorSnackbar(context, "Erro ao excluir loja: $e");
            }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = context.watch<StoreProvider>(); // Assiste mudanças

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Lojas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar Lojas',
            onPressed: storeProvider.isLoading ? null : _fetchStores,
          ),
        ],
      ),
      body: _buildStoreList(storeProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditStore(),
        tooltip: 'Adicionar Loja',
        child: const Icon(Icons.add_business),
      ),
    );
  }

  Widget _buildStoreList(StoreProvider storeProvider) {
    if (storeProvider.isLoading && storeProvider.stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (storeProvider.error != null && storeProvider.stores.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height:16), Text("Erro:", style: Theme.of(context).textTheme.titleMedium), const SizedBox(height:8), Text(storeProvider.error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])), const SizedBox(height:20), ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Tentar Novamente'), onPressed: _fetchStores,) ])));
    }
    if (storeProvider.stores.isEmpty) {
      return const Center(child: Text("Nenhuma loja encontrada.\nUse '+' para adicionar."));
    }

    return RefreshIndicator(
      onRefresh: _fetchStores, // Chama fetchStores
      child: ListView.separated(
        itemCount: storeProvider.stores.length,
        itemBuilder: (context, index) {
          final store = storeProvider.stores[index];
          final isSelected = store.id == storeProvider.selectedStore?.id;
          return ListTile(
            leading: Icon(isSelected ? Icons.storefront : Icons.store_outlined, color: isSelected ? Theme.of(context).primaryColor : null),
            title: Text(store.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(store.address ?? 'Sem endereço', maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: isSelected,
            selectedTileColor: Colors.indigo.withOpacity(0.08),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(Icons.edit_outlined), color: Colors.grey[600], visualDensity: VisualDensity.compact, tooltip: 'Editar', onPressed: () => _navigateToEditStore(store: store)),
              IconButton(icon: const Icon(Icons.delete_outline), color: Colors.red[700], visualDensity: VisualDensity.compact, tooltip: 'Excluir', onPressed: () => _confirmDeleteStore(store)),
            ]),
            onTap: () { if (!isSelected) { storeProvider.selectStore(store); /* Navigator.pop(context); // Opcional */ } },
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      ),
    );
  }

  // --- Funções Auxiliares SnackBar ---
  void _showErrorSnackbar(BuildContext ctx, String message) {
    // A verificação 'mounted' é feita antes de chamar esta função
    ScaffoldMessenger.of(ctx).removeCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar( SnackBar(content: Text(message), backgroundColor: Theme.of(ctx).colorScheme.error));
  }
  void _showSuccessSnackbar(BuildContext ctx, String message) {
     // A verificação 'mounted' é feita antes de chamar esta função
    ScaffoldMessenger.of(ctx).removeCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar( SnackBar(content: Text(message), backgroundColor: Colors.green[600]));
  }
} // Fim da classe _StoreManagementScreenState