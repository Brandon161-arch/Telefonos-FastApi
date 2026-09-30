import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../widgets/store_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final _loginForm = GlobalKey<FormState>();
  final _registerForm = GlobalKey<FormState>();
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;
  String? _info;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void dispose() {
    _tabs.dispose();
    for (final controller in [_loginEmail, _loginPassword, _name, _email, _password, _phone, _address]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'ElectroPhone',
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Tu cuenta ElectroPhone', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                TabBar(controller: _tabs, tabs: const [Tab(text: 'Iniciar sesión'), Tab(text: 'Crear cuenta')]),
                if (_info != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_info!, style: TextStyle(color: Theme.of(context).colorScheme.secondary))),
                SizedBox(height: 520, child: TabBarView(controller: _tabs, children: [_loginTab(), _registerTab()])),
              ]))),
            ),
          ),
        ),
      );

  Widget _loginTab() => Form(
        key: _loginForm,
        child: ListView(padding: const EdgeInsets.only(top: 18), children: [
          TextFormField(controller: _loginEmail, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)), validator: _required),
          const SizedBox(height: 12),
          TextFormField(controller: _loginPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña', prefixIcon: Icon(Icons.lock_outline)), validator: _required),
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : _login, child: Text(_busy ? 'Ingresando…' : 'Iniciar sesión')),
          TextButton(onPressed: _resendVerification, child: const Text('Reenviar verificación de correo')),
        ]),
      );

  Widget _registerTab() => Form(
        key: _registerForm,
        child: ListView(padding: const EdgeInsets.only(top: 18), children: [
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo'), validator: _required),
          const SizedBox(height: 10),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Correo electrónico'), validator: _required),
          const SizedBox(height: 10),
          TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña (mínimo 8 caracteres)'), validator: (v) => (v?.length ?? 0) < 8 ? 'Usa al menos 8 caracteres' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Teléfono (opcional)')),
          const SizedBox(height: 10),
          TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Dirección (opcional)')),
          const SizedBox(height: 18),
          FilledButton(onPressed: _busy ? null : _register, child: Text(_busy ? 'Creando cuenta…' : 'Crear cuenta')),
        ]),
      );

  String? _required(String? value) => value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null;

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() { _busy = true; _info = null; });
    try {
      await _api.login(_loginEmail.text.trim(), _loginPassword.text);
      if (mounted) context.go('/account');
    } catch (e) {
      if (mounted) setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    if (!_registerForm.currentState!.validate()) return;
    setState(() { _busy = true; _info = null; });
    try {
      await _api.register({
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone_number': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (!mounted) return;
      setState(() => _info = 'Cuenta creada. Revisa tu correo y confirma el enlace antes de iniciar sesión.');
      _tabs.animateTo(0);
    } catch (e) {
      if (mounted) setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_loginEmail.text.trim().isEmpty) {
      setState(() => _info = 'Escribe tu correo en el campo de inicio de sesión primero.');
      return;
    }
    setState(() { _busy = true; _info = null; });
    try {
      await _api.resendVerification(_loginEmail.text.trim());
      if (mounted) setState(() => _info = 'Si tu cuenta requiere verificación, enviamos un nuevo enlace.');
    } catch (e) {
      if (mounted) setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
