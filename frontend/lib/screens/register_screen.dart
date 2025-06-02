// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/auth_provider.dart';
import '/main.dart'; // Para AppRoutes

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isRegistering) return;

    setState(() => _isRegistering = true);

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim(); // Guarda para possível uso futuro

    final success = await authProvider.register(
      _nameController.text.trim(),
      email,
      _passwordController.text,
    );

    // Verifica 'mounted' antes de interagir com context ou setState
    if (!mounted) return; // Sai se desmontado durante o await

    setState(() => _isRegistering = false); // Desativa loading

    if (success) {
      // Mostra SnackBar de sucesso e navega para Login
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registro concluído! Agora faça o login."),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.green,
            )
       );
      // Usa pushReplacementNamed para ir para login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      // Mostra SnackBar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.authError ?? 'Falha no registro.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Crie sua Conta', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 30),
                TextFormField( controller: _nameController, decoration: const InputDecoration(labelText: 'Nome Completo', hintText: 'Seu nome', prefixIcon: Icon(Icons.person_outline)), /*...*/ validator: (v)=>(v==null||v.trim().length<3)?'Nome (mín 3 l.)':null),
                const SizedBox(height: 16),
                TextFormField( controller: _emailController, decoration: const InputDecoration(labelText: 'Email', hintText: 'email@exemplo.com', prefixIcon: Icon(Icons.email_outlined)), /*...*/ validator: (v){ if(v==null||v.trim().isEmpty)return'Email obrigatório'; final r=RegExp(r'^[^@]+@[^@]+\.[^@]+'); if(!r.hasMatch(v.trim()))return'Email inválido'; return null;} ),
                const SizedBox(height: 16),
                TextFormField( controller: _passwordController, decoration: InputDecoration(labelText: 'Senha', hintText: 'Mínimo 6 caracteres', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscurePassword?Icons.visibility_off_outlined:Icons.visibility_outlined), onPressed: ()=>setState(()=>_obscurePassword=!_obscurePassword))), obscureText: _obscurePassword, /*...*/ validator: (v)=>(v==null||v.length<6)?'Senha (mín 6 c.)':null ),
                const SizedBox(height: 16),
                TextFormField( controller: _confirmPasswordController, decoration: InputDecoration(labelText: 'Confirmar Senha', hintText: 'Digite a senha novamente', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword?Icons.visibility_off_outlined:Icons.visibility_outlined), onPressed: ()=>setState(()=>_obscureConfirmPassword=!_obscureConfirmPassword))), obscureText: _obscureConfirmPassword, /*...*/ validator: (v){if(v==null||v.isEmpty)return'Confirme'; if(v!=_passwordController.text)return'Senhas não coincidem'; return null;}, onFieldSubmitted:(_)=>_isRegistering?null:_submit() ),
                const SizedBox(height: 30),
                _isRegistering
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon( onPressed: _submit, icon: const Icon(Icons.person_add_alt_1), label: const Text('Registrar'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _isRegistering ? null : () { if (Navigator.canPop(context)) { Navigator.pop(context); } },
                  child: const Text('Já tem conta? Faça login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}