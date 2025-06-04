// lib/screens/stock_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/stock_item.dart';
import '/models/store_model.dart';
import '/providers/store_provider.dart';
import '/providers/auth_provider.dart';
import '/services/api_service.dart';
import '/screens/edit_stock_item_screen.dart';
import '/utils/app_prefs.dart';
import '/main.dart'; // Para AppRoutes

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<StockItem> _stockItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _useCardLayout = false;
  int? _currentStoreId;
  int _quantityDecimals = 0;

  final ApiService _apiService = ApiService();
  StoreProvider? _storeProviderRef; // Referência para usar no dispose

  @override
  void initState() {
    super.initState();
    // Carrega preferências primeiro de forma síncrona (ou com await se necessário)
    // mas o carregamento inicial dos dados é feito depois que o provider estiver pronto
    _loadPreferencesAndInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obter a referência ao provider e adicionar listener AQUI
    // É mais seguro que no initState
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    // Remove listener antigo (se houver) e adiciona o novo
    _storeProviderRef?.removeListener(_storeChangeListener);
    _storeProviderRef = storeProvider;
    _storeProviderRef?.addListener(_storeChangeListener);

    // Verifica se a loja mudou desde a última vez (ex: ao voltar para esta tela)
    // e se os dados ainda não foram carregados para a loja atual
    if (_currentStoreId != storeProvider.selectedStoreId) {
        _storeChangeListener(); // Força a atualização se a loja mudou enquanto fora da tela
    }
  }

  @override
  void dispose() {
    // Remove o listener usando a referência guardada
    _storeProviderRef?.removeListener(_storeChangeListener);
    super.dispose();
  }

  // Carrega preferências e dados iniciais (chamado pelo initState)
  Future<void> _loadPreferencesAndInitialData() async {
    await _loadLayoutPreference();
    await _loadQuantityDecimalPreference();

    // Não busca dados aqui, espera didChangeDependencies e/ou _storeChangeListener
    // Apenas atualiza o estado de loading inicial se necessário
     if (mounted) {
         // Pega a loja atual do provider (listen: false)
         final initialStoreId = Provider.of<StoreProvider>(context, listen: false).selectedStoreId;
         _currentStoreId = initialStoreId; // Define o ID inicial
         if (_currentStoreId == null) {
             setState(() => _isLoading = false); // Para loading se não há loja
         } else {
             // Tenta carregar os itens da loja inicial
             _loadStockItems(storeId: _currentStoreId!, showLoading: true);
         }
     }
  }

  // Listener chamado QUANDO A LOJA MUDA NO PROVIDER
  void _storeChangeListener() {
    // Usa listen: false pois estamos apenas reagindo à notificação
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final newStoreId = storeProvider.selectedStoreId;

    debugPrint("[StockScreen] _storeChangeListener chamado. newStoreId: $newStoreId, _currentStoreId: $_currentStoreId");

    // Verifica se a loja realmente mudou
    if (newStoreId != _currentStoreId) {
      // ★★★ VERIFICAÇÃO mounted ★★★
      if (!mounted) {
         debugPrint("[StockScreen] _storeChangeListener: Widget desmontado, saindo.");
         return;
      }

      debugPrint("[StockScreen] Listener: Loja alterada para ID: $newStoreId.");
      _currentStoreId = newStoreId; // Atualiza o ID local

      if (_currentStoreId != null) {
        // Limpa lista antiga, mostra loading e busca novos itens
        setState(() { _stockItems = []; _isLoading = true; _errorMessage = null; });
        _loadStockItems(storeId: _currentStoreId!); // Dispara o carregamento
      } else {
        // Nenhuma loja selecionada, limpa tudo
        setState(() { _stockItems = []; _isLoading = false; _errorMessage = null; });
      }
    }
  }

  // Carrega preferência de layout
  Future<void> _loadLayoutPreference() async {
    final useCards = await AppPrefs.getUseCardLayout();
    // ★★★ VERIFICAÇÃO mounted ★★★
    if (mounted) {
      setState(() => _useCardLayout = useCards);
    }
  }

   // Carrega preferência de decimais
   Future<void> _loadQuantityDecimalPreference() async {
      final decimals = await AppPrefs.getQuantityDecimals();
      // ★★★ VERIFICAÇÃO mounted ★★★
      if (mounted) {
          setState(() => _quantityDecimals = decimals);
      }
   }

  // Carrega os itens de estoque da API
  Future<void> _loadStockItems({required int storeId, bool showLoading = true}) async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE QUALQUER COISA ASYNC ★★★
    if (!mounted) return;
    if (!_ensureApiServiceToken()) {
        if (mounted) setState(() => _isLoading = false); // Para loading se não autenticado
        return;
    }

    // Define loading APENAS se montado
    if (showLoading || _errorMessage != null) {
      setState(() { _isLoading = true; _errorMessage = null; });
    }

    try {
      debugPrint("[StockScreen] Buscando itens para loja $storeId...");
      final items = await _apiService.fetchStockItems(storeId); // await
      // ★★★ VERIFICAÇÃO mounted APÓS await ★★★
      if (mounted) {
        setState(() { _stockItems = items; _isLoading = false; });
        debugPrint("[StockScreen] Itens carregados: ${items.length}");
      }
    } catch (e) {
      // ★★★ VERIFICAÇÃO mounted APÓS await (implícito no catch) ★★★
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _isLoading = false; _stockItems = []; });
         debugPrint("[StockScreen] Erro ao carregar itens: $e");
      }
    }
    // Finally não é estritamente necessário se try/catch cobrir todos os setState
  }

  // Garante que o ApiService tem o token atual do AuthProvider
  bool _ensureApiServiceToken() {
    // Usa listen: false pois é chamado em initState/ações
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      // ★★★ VERIFICAÇÃO mounted ANTES DE setState ★★★
      if (mounted) {
          // Evita chamar setState diretamente aqui se _loadStockItems já faz
          // Apenas define a mensagem de erro para ser mostrada no build
          _errorMessage = "Sessão inválida. Faça login.";
          // Garante que _isLoading seja false para exibir o erro
          if (_isLoading) _isLoading = false;
          // Força rebuild para mostrar erro se necessário (cuidado com loops)
          // setState((){}); // Descomentar com cautela
      }
      debugPrint("[StockScreen] _ensureApiServiceToken: Falha - Usuário não autenticado.");
      return false;
    }
    _apiService.setAuthToken(token); // Define token no serviço
    return true;
  }

  // Navega para a tela de adição/edição de item
  Future<void> _navigateToEditItem(int storeId, {StockItem? item}) async {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context (Navigator) ★★★
    if (!mounted) return;
    if (!_ensureApiServiceToken()) return;

    final result = await Navigator.push<bool>( // await
      context,
      MaterialPageRoute(
        builder: (context) => EditStockItemScreen(storeId: storeId, initialItem: item),
      ),
    );

    // ★★★ VERIFICAÇÃO mounted APÓS await (pop da tela de edição) ★★★
    if (result == true && mounted) {
      _showSnackbar("Operação realizada. Atualizando lista...", Colors.green);
      // Recarrega usando o storeId atual (já deve estar correto)
      if (_currentStoreId != null) {
        // showLoading: false para não mostrar o indicator central, só o RefreshIndicator se puxar
        _loadStockItems(storeId: _currentStoreId!, showLoading: false);
      }
    }
  }

  // Exibe uma SnackBar
  void _showSnackbar(String message, [Color? backgroundColor]) {
    // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2) // Duração padrão
      ),
    );
  }

  // Alterna o layout e salva a preferência
  void _toggleLayout() {
    // setState é síncrono, OK aqui
    setState(() { _useCardLayout = !_useCardLayout; });
    // Salva preferência (async, mas não esperamos nem atualizamos UI com base nisso)
    AppPrefs.setUseCardLayout(_useCardLayout);
  }

  // Formata a quantidade
  String _formatQuantity(double quantity) {
    return quantity.toStringAsFixed(_quantityDecimals);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    // Assiste (watch) para reagir a mudanças na loja selecionada
    final storeProvider = Provider.of<StoreProvider>(context);
    // Lê (read) para ações que não precisam de rebuild (logout)
    final authProviderRead = context.read<AuthProvider>();
    final selectedStore = storeProvider.selectedStore;

    // Log para ajudar a entender o estado atual durante o build
    // debugPrint("[StockScreen build] isLoading: $_isLoading, error: $_errorMessage, selectedStore: ${selectedStore?.id}, items: ${_stockItems.length}");

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedStore?.name ?? 'Nenhuma Loja'),
        actions: [ /* ... Ações como antes (já usam _isLoading) ... */
          IconButton( icon: Icon(_useCardLayout ? Icons.view_list_outlined : Icons.view_module_outlined), tooltip: 'Alternar Layout', onPressed: _toggleLayout,),
          IconButton( icon: const Icon(Icons.refresh), tooltip: 'Atualizar Lista', onPressed: (_isLoading || selectedStore == null) ? null : () => _loadStockItems(storeId: selectedStore.id), ),
          IconButton( icon: const Icon(Icons.logout), tooltip: 'Sair', onPressed: () async { await authProviderRead.logout(); }, ),
        ],
      ),
      drawer: _buildAppDrawer(context), // O Drawer já usa Provider.of
      body: _buildBody(selectedStore), // Passa a loja selecionada para o método de build do corpo
      floatingActionButton: selectedStore == null
          ? null
          : FloatingActionButton(
              onPressed: _isLoading ? null : () => _navigateToEditItem(selectedStore.id),
              tooltip: 'Adicionar Item',
              child: const Icon(Icons.add),
            ),
    );
  }

  // --- Build Helpers ---

  // Constrói o Drawer (sem mudanças significativas, adicionando consts)
  Widget _buildAppDrawer(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final authProviderRead = context.read<AuthProvider>();
    final user = authProviderRead.userData;
    final stores = storeProvider.stores;
    final selectedStore = storeProvider.selectedStore;

    return Drawer( child: ListView( padding: EdgeInsets.zero, children: <Widget>[
          UserAccountsDrawerHeader( accountName: Text(user?['name'] ?? 'Usuário'), accountEmail: Text(user?['email'] ?? ''), currentAccountPicture: CircleAvatar(backgroundColor: Colors.white70, child: Text( user?['name']?.substring(0, 1).toUpperCase() ?? '?', style: const TextStyle(fontSize: 40.0, color: Colors.indigo),)),),
          const ListTile(title: Text('Lojas', style: TextStyle(fontWeight: FontWeight.bold))),
          if (storeProvider.isLoading && stores.isEmpty) const ListTile(leading: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)), title: Text("Carregando..."))
          else if (stores.isEmpty) ListTile( leading: const Icon(Icons.warning_amber_rounded), title: const Text("Nenhuma loja."), subtitle: const Text("Crie uma em 'Gerenciar'."), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.storeManagement); }, ),
          ...stores.map((store) => ListTile( title: Text(store.name), leading: Icon(store.id == selectedStore?.id ? Icons.storefront : Icons.store_outlined), selected: store.id == selectedStore?.id, selectedTileColor: Colors.indigo.withOpacity(0.1), onTap: () { if (store.id != selectedStore?.id) { storeProvider.selectStore(store); } Navigator.pop(context); }, )),
          const Divider(),
          ListTile( leading: const Icon(Icons.add_business_outlined), title: const Text('Gerenciar Lojas'), onTap: () { Navigator.pop(context); Navigator.pushNamed(context, AppRoutes.storeManagement); },),
          const Divider(),
          const ListTile(title: Text('Outros Menus', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile( leading: const Icon(Icons.settings_outlined), title: const Text('Configurações'), onTap: () { Navigator.pop(context); _showSnackbar("Tela de Configurações (TODO)", Colors.orange); },),
          ListTile( leading: const Icon(Icons.receipt_long_outlined), title: const Text('Documentos'), onTap: () { Navigator.pop(context); _showSnackbar("Tela de Documentos (TODO)", Colors.orange);},),
          ListTile( leading: const Icon(Icons.assessment_outlined), title: const Text('Relatórios'), onTap: () { Navigator.pop(context); _showSnackbar("Tela de Relatórios (TODO)", Colors.orange); },),
          const Divider(),
          ListTile( leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Sair', style: TextStyle(color: Colors.red)), onTap: () async { Navigator.pop(context); await authProviderRead.logout(); }, ),
        ],
      ),
    );
  }

  // Constrói o corpo principal
  Widget _buildBody(Store? selectedStore) {
    if (selectedStore == null) { return const Center(child: Padding( padding: EdgeInsets.all(20.0), child: Text( 'Selecione uma loja no menu lateral para visualizar o estoque ou crie uma nova em "Gerenciar Lojas".', textAlign: TextAlign.center, ),)); }
    if (_isLoading && _stockItems.isEmpty) { return const Center(child: CircularProgressIndicator()); }
    if (_errorMessage != null) { return Center( child: Padding( padding: const EdgeInsets.all(16.0), child: Column( mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.error_outline, color: Colors.red, size: 48), const SizedBox(height: 16), Text('Erro ao carregar dados:', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 8), Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])), const SizedBox(height: 20), ElevatedButton.icon( icon: const Icon(Icons.refresh), label: const Text('Tentar Novamente'), onPressed: () => _loadStockItems(storeId: selectedStore.id), ) ]))); }
    if (_stockItems.isEmpty) { return Center( child: Text( 'Nenhum item cadastrado nesta loja (${selectedStore.name}).\nUse o botão "+" para adicionar.', textAlign: TextAlign.center, )); }

    // Lista ou Grid
    return RefreshIndicator(
      onRefresh: () => _loadStockItems(storeId: selectedStore.id, showLoading: false),
      child: _useCardLayout ? _buildGridView(selectedStore.id) : _buildListView(selectedStore.id),
    );
  }

  // Constrói ListView (com correção no CircleAvatar)
  Widget _buildListView(int currentStoreId) {
    return ListView.builder(
      itemCount: _stockItems.length,
      itemBuilder: (context, index) {
        final item = _stockItems[index];
        final imageUrl = item.imageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        // Log para verificar properties
        // debugPrint("[StockScreen List] Renderizando Item ID: ${item.id}, Props: ${item.properties}");
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
            onBackgroundImageError: hasImage ? (e, s) { /* Log opcional */ } : null,
            child: !hasImage ? const Icon(Icons.inventory_2_outlined, color: Colors.grey) : null,
          ),
          title: Text(item.name),
          // Acessa categoria de properties e formata quantidade
          subtitle: Text('Qtd: ${_formatQuantity(item.quantity)} | Cat: ${item.properties[AppPrefs.propCategory] ?? 'N/A'}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToEditItem(currentStoreId, item: item),
        );
      },
    );
  }

  // Constrói GridView (com correção na imagem)
  Widget _buildGridView(int currentStoreId) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = (screenWidth / 180).floor();
    crossAxisCount = crossAxisCount < 2 ? 2 : crossAxisCount;

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount, crossAxisSpacing: 8.0, mainAxisSpacing: 8.0, childAspectRatio: 0.8,
      ),
      itemCount: _stockItems.length,
      itemBuilder: (context, index) {
        final item = _stockItems[index];
        final imageUrl = item.imageUrl;
        final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
        // Log para verificar properties
        // debugPrint("[StockScreen Grid] Renderizando Item ID: ${item.id}, Props: ${item.properties}");
        return Card(
          clipBehavior: Clip.antiAlias, elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: InkWell(
            onTap: () => _navigateToEditItem(currentStoreId, item: item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded( flex: 3, child: hasImage
                    ? Image.network( imageUrl, fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (ctx, error, stack) { return Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))); }
                      )
                    : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40))),
                ),
                Expanded( flex: 2, child: Padding( padding: const EdgeInsets.all(8.0), child: Column( crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(item.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Qtd: ${_formatQuantity(item.quantity)}', style: Theme.of(context).textTheme.bodySmall),
                      Text('Cat: ${item.properties[AppPrefs.propCategory] ?? 'N/A'}', style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                    ],),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} // Fim da classe _StockScreenState