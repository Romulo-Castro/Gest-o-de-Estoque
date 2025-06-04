// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '/main.dart'; // Para AppRoutes
import '/utils/app_prefs.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Inicialização com todas as propriedades
  final Map<String, bool> _properties = {
    AppPrefs.propName: true, AppPrefs.propQuantity: true, AppPrefs.propCategory: true,
    AppPrefs.propImage: true, AppPrefs.propBarcode: false, AppPrefs.propDescription: false,
    AppPrefs.propTags: false, AppPrefs.propUom: false, AppPrefs.propMinStock: false,
  };
  bool _useCardLayout = false;
  int _quantityDecimals = 0;
  bool _isLoading = false;

  Future<void> _savePreferencesAndContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final List<String> activeProps = _properties.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();

      await AppPrefs.setItemProperties(activeProps);
      await AppPrefs.setUseCardLayout(_useCardLayout);
      await AppPrefs.setQuantityDecimals(_quantityDecimals);
      await AppPrefs.setFirstLaunchCompleted(true);

      // ★★★ VERIFICAÇÃO mounted ANTES DE NAVEGAR ★★★
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
       // ★★★ VERIFICAÇÃO mounted ANTES DE USAR context ★★★
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erro ao salvar preferências: $e"),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
       // ★★★ VERIFICAÇÃO mounted ANTES DE setState ★★★
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Bem-vindo! Configurações Iniciais'), ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text( 'Propriedades das Mercadorias', style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            const Text('Selecione os campos que deseja usar para seus itens:'),
            const SizedBox(height: 10),
            ..._properties.entries.map((entry) { /* ... CheckboxListTile ... */
              final String key = entry.key;
              final bool value = entry.value;
              final bool isEssential = key == AppPrefs.propName || key == AppPrefs.propQuantity;
              return CheckboxListTile(title: Text(_getPropertyDisplayName(key)), value: value, onChanged: isEssential ? null : (bool? newValue) => setState(() => _properties[key] = newValue ?? false), controlAffinity: ListTileControlAffinity.leading, dense: true, enabled: !isEssential, activeColor: Theme.of(context).primaryColor,);
            }), // .toList() removido
            const SizedBox(height: 24),
            Text( 'Exibição da Lista', style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            const Text('Como prefere visualizar seus itens?'),
            const SizedBox(height: 10),
            Row( mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ /* ... ChoiceChips ... */
              ChoiceChip( label: const Text('Lista'), avatar: const Icon(Icons.view_list_outlined), selected: !_useCardLayout, selectedColor: Colors.indigo.withAlpha(38), onSelected: (s){if(s)setState(()=>_useCardLayout=false);},),
              ChoiceChip( label: const Text('Cartões'), avatar: const Icon(Icons.view_module_outlined), selected: _useCardLayout, selectedColor: Colors.indigo.withAlpha(38), onSelected: (s){if(s)setState(()=>_useCardLayout=true);}, ),
            ],),
            const SizedBox(height: 24),
            Text( 'Precisão da Quantidade', style: Theme.of(context).textTheme.titleLarge,),
            const SizedBox(height: 8),
            const Text('Quantas casas decimais usar para quantidades?'),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>( value: _quantityDecimals, decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers_outlined), contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12)), items: [0, 1, 2, 3].map((int v) => DropdownMenuItem<int>(value: v, child: Text(v==0?'Nenhuma (Ex: 10)':'$v casa${v>1?'s':''} (Ex: 10.${'0'*v})'))).toList(), onChanged: (int? n) => setState(()=> _quantityDecimals = n ?? 0),),
            const SizedBox(height: 40),
            Center( child: ElevatedButton.icon( icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline), label: const Text('Começar a Usar'), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), textStyle: const TextStyle(fontSize: 16)), onPressed: _isLoading ? null : _savePreferencesAndContinue,),),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getPropertyDisplayName(String key) { /* ... */
     switch (key) {
       case AppPrefs.propName: return 'Nome (Obrigatório)'; case AppPrefs.propQuantity: return 'Quantidade (Obrigatório)'; case AppPrefs.propCategory: return 'Categoria';
       case AppPrefs.propImage: return 'Imagem'; case AppPrefs.propBarcode: return 'Código de Barras'; case AppPrefs.propDescription: return 'Descrição';
       case AppPrefs.propTags: return 'Tags'; case AppPrefs.propUom: return 'Unidade de Medida'; case AppPrefs.propMinStock: return 'Estoque Mínimo';
       default: return key;
     }
   }
}