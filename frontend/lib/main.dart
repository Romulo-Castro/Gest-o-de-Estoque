// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importar Providers
// Corrigir caminhos se necessário (ex: package:nome_pacote/providers/...)
import '/providers/auth_provider.dart';
import '/providers/store_provider.dart';
// Importar ApiService se usar Opção A

// Importar Telas
import '/screens/login_screen.dart';
import '/screens/register_screen.dart';
import '/screens/stock_screen.dart';
import '/screens/welcome_screen.dart';
import '/screens/store_management_screen.dart';
import '/screens/home_screen.dart'; // Importar HomeScreen

// Importar Utilitários e Preferências
import '/utils/app_prefs.dart';

// --- Constantes de Rotas Nomeadas ---
// Centraliza os nomes das rotas para evitar erros de digitação
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const welcome = '/welcome';
  // 'home' agora aponta para o Dashboard principal
  static const home = '/home_dashboard';
  // Rota específica para a tela que lista os itens de estoque
  static const stockList = '/stock-list';
  static const storeManagement = '/store-management';
  // Adicionar outras rotas conforme necessário:
  // static const documents = '/documents';
  // static const reports = '/reports';
  // static const settings = '/settings';
}

// --- Ponto de Entrada Principal ---
void main() async {
  // Necessário para garantir que plugins (como SharedPreferences) sejam inicializados
  // antes de `runApp` se você usar `await` antes dele (como fizemos em AppPrefs).
  WidgetsFlutterBinding.ensureInitialized();

  // Roda o widget raiz da aplicação
  runApp(const MyApp());
}

// --- Widget Raiz da Aplicação ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Disponibiliza os providers para toda a árvore de widgets abaixo dele
    return MultiProvider(
      providers: [
        // Provider para Autenticação
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Provider para Lojas, que depende do estado de autenticação
        ChangeNotifierProxyProvider<AuthProvider, StoreProvider>(
          // Cria a instância inicial. StoreProvider instancia seu próprio ApiService.
          create: (_) => StoreProvider(),
          // Atualiza o StoreProvider quando o AuthProvider muda (login/logout)
          update: (context, auth, previousStoreProvider) {
            // Chama o método para passar o token atual (ou null) para o StoreProvider
            previousStoreProvider!.updateAuthToken(auth.token);
            // Retorna a instância existente do StoreProvider, agora possivelmente atualizada
            return previousStoreProvider;
          },
        ),
        // Adicione outros providers aqui se eles forem necessários globalmente
        // Ex: Provider<SettingsProvider>(create: (_) => SettingsProvider()),
      ],
      // Widget principal da aplicação
      child: MaterialApp(
        title: 'Gestão de Estoques PRO', // Nome que aparece no gerenciador de apps
        // Definição do Tema Visual
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.indigo, // Cor base para gerar a paleta
              // brightness: Brightness.light, // Opcional: Forçar tema claro
              // primary: Colors.indigo[700], // Opcional: Ajustar cor primária
          ),
          useMaterial3: true, // Habilita o visual mais recente do Material Design
          visualDensity: VisualDensity.adaptivePlatformDensity, // Ajusta espaçamento para a plataforma
          // Tema para AppBar
          appBarTheme: AppBarTheme(
            elevation: 1.5, // Sombra um pouco mais pronunciada
            centerTitle: true,
            backgroundColor: Colors.indigo[600], // Um tom de índigo
            foregroundColor: Colors.white, // Cor para título e ícones
            titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500, // Semi-bold
                color: Colors.white,
                letterSpacing: 0.5), // Leve espaçamento
          ),
          // Tema para Campos de Texto
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[400]!), // Borda cinza claro
            ),
            enabledBorder: OutlineInputBorder( // Borda quando não focado
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder( // Borda quando focado
               borderRadius: BorderRadius.circular(8.0),
               borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5), // Usa cor primária
            ),
            filled: true,
            fillColor: Colors.grey[100], // Fundo levemente acinzentado
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
            hintStyle: TextStyle(color: Colors.grey[500]) // Estilo para hintText
          ),
          // Tema para Botões Elevados
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.indigo, // Cor primária como fundo
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)), // Botões mais arredondados
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              elevation: 3.0, // Sombra do botão
            ),
          ),
          // Tema para Floating Action Button
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.deepOrangeAccent[400], // Cor de destaque
            foregroundColor: Colors.white,
            elevation: 4.0,
          ),
          // Tema para ChoiceChip (usado em WelcomeScreen)
          chipTheme: ChipThemeData(
             selectedColor: Colors.indigo.withAlpha(40), // Cor de seleção com transparência
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             labelStyle: TextStyle(color: Colors.grey[800]), // Cor do texto padrão
             secondaryLabelStyle: TextStyle(color: Theme.of(context).primaryColorDark) // Cor do texto quando selecionado
          ),
           // Tema para ListTile (usado em Drawers e listas)
           listTileTheme: ListTileThemeData(
             selectedTileColor: Colors.indigo.withOpacity(0.1), // Cor de fundo quando selecionado
             iconColor: Colors.grey[600], // Cor padrão dos ícones
           ),
        ),
        debugShowCheckedModeBanner: false, // Remove a faixa "Debug"
        // Widget inicial da aplicação, controlado pelo AuthWrapper
        home: const AuthWrapper(),
        // Definição das rotas nomeadas
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.welcome: (context) => const WelcomeScreen(),
          // 'home' agora é o Dashboard
          AppRoutes.home: (context) => const HomeScreen(),
          // Rota específica para a lista de estoque
          AppRoutes.stockList: (context) => const StockScreen(),
          AppRoutes.storeManagement: (context) => const StoreManagementScreen(),
          // Adicione aqui as rotas para as outras telas quando criá-las:
          // AppRoutes.documents: (context) => const DocumentsScreen(),
          // AppRoutes.reports: (context) => const ReportsScreen(),
          // AppRoutes.settings: (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

// --- Widgets de Controle de Fluxo ---

// Decide entre Login ou (Welcome/Home Dashboard) baseado na autenticação
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Assiste (watch) o AuthProvider para reagir a mudanças no estado de autenticação
    final authProvider = Provider.of<AuthProvider>(context);

    // Mostra loading enquanto o provider verifica o estado inicial (_tryAutoLogin)
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Verificando sessão...")
          ],
        )),
      );
    }

    // Se o usuário está autenticado
    if (authProvider.isAuthenticated) {
      // Verifica se é o primeiro acesso (já passou pela tela de Welcome?)
      return FutureBuilder<bool>(
        future: AppPrefs.isFirstLaunch(),
        builder: (context, snapshot) {
          // Mostra loading enquanto verifica a preferência
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          // Mostra erro se falhar ao ler a preferência
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Erro ao verificar preferências: ${snapshot.error}')));
          }
          // Obtém o resultado (true se for o primeiro acesso)
          final bool isFirstTime = snapshot.data ?? true; // Assume true se houver erro
          // Se for o primeiro acesso, vai para a tela de Welcome/Configuração Inicial
          // Senão, vai para a tela principal (Home Dashboard)
          return isFirstTime ? const WelcomeScreen() : const HomeScreen();
        },
      );
    }
    // Se não está autenticado, mostra a tela de Login
    else {
      return const LoginScreen();
    }
  }
}

// ★★★ HomeScreenSelector foi removido pois AuthWrapper agora direciona para HomeScreen ★★★
// A lógica de verificar se há lojas pode ser feita dentro da HomeScreen ou StockScreen