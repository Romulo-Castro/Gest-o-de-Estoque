// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/main.dart'; // Para AppRoutes

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false; // Estado de loading local

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Função para exibir SnackBar de erro
  void _showLoginErrorSnackbar(String message) {
    // Verifica se o widget ainda está montado antes de usar o context
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove anteriores
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error, // Usa cor de erro do tema
        duration: const Duration(seconds: 3), // Duração um pouco maior para erro
      ),
    );
  }

  // Submete o formulário de login
  Future<void> _submit() async {
    // Esconde o teclado
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    // Valida o formulário e verifica se já está logando
    if (form == null || !form.validate() || _isLoggingIn) return;

    // Ativa o loading local (para o botão)
    setState(() => _isLoggingIn = true);

    // Chama o método de login no provider (sem escutar mudanças aqui - 'read')
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    ); // await

    // ★★★ VERIFICAÇÃO mounted APÓS await ★★★
    if (!mounted) return; // Sai se desmontado durante o login

    // Desativa o loading local
    setState(() => _isLoggingIn = false);

    // Se o login FALHOU, mostra o SnackBar com a mensagem de erro do provider
    if (!success) {
      _showLoginErrorSnackbar(authProvider.authError ?? 'Falha no login. Verifique seus dados.');
    }
    // Se o login foi bem-sucedido (success == true), o AuthWrapper
    // que está escutando o AuthProvider cuidará da navegação para a próxima tela.
    // Não precisamos fazer navegação explícita aqui.
  }

  @override
  Widget build(BuildContext context) {
    // Não precisamos assistir o provider aqui se usamos _isLoggingIn local
    // final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      // appBar: AppBar(title: const Text('Login')), // Opcional
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Título
                const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.indigo),
                const SizedBox(height: 20),
                Text('Gestão de Estoques', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.indigo)),
                const SizedBox(height: 40),

                // Campo Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', hintText: 'seuemail@exemplo.com', prefixIcon: Icon(Icons.email_outlined)),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                     if (value == null || value.trim().isEmpty) return 'Email obrigatório';
                     final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                     if (!emailRegex.hasMatch(value.trim())) return 'Email inválido';
                     return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Senha
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                      labelText: 'Senha', hintText: 'Sua senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoggingIn ? null : _submit(),
                  validator: (value) => (value == null || value.isEmpty) ? 'Senha obrigatória' : null,
                ),
                const SizedBox(height: 30),

                // Botão Entrar (usa loading local)
                _isLoggingIn
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar'),
                        onPressed: _submit, // Chama _submit
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), textStyle: const TextStyle(fontSize: 16)),
                      ),
                const SizedBox(height: 15),

                // Botão Registrar
                TextButton(
                  onPressed: _isLoggingIn ? null : () {
                    Navigator.pushNamed(context, AppRoutes.register); // Navega para registro
                  },
                  child: const Text('Não tem conta? Registre-se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}