import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/store_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _busy = false;
  String? _info;
  bool _isSuccessInfo = false;

  ApiClient get _api => context.read<ApiClient>();

  @override
  void dispose() {
    _tabs.dispose();
    for (final controller in [
      _loginEmail,
      _loginPassword,
      _name,
      _email,
      _password,
      _phone,
      _address
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      title: 'Tu Cuenta',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo header
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('📱', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Acceso ElectroPhone',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inicia sesión para gestionar tus pedidos y favoritos',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabs,
                      indicator: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      tabs: const [
                        Tab(text: 'Iniciar Sesión'),
                        Tab(text: 'Crear Cuenta'),
                      ],
                    ),
                  ),

                  if (_info != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_isSuccessInfo ? AppColors.success : AppColors.danger)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_isSuccessInfo ? AppColors.success : AppColors.danger)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _info!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isSuccessInfo ? AppColors.success : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _buildLoginTab(),
                        _buildRegisterTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Form(
      key: _loginForm,
      child: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          TextFormField(
            controller: _loginEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPassword,
            obscureText: _obscureLoginPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureLoginPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textDim,
                ),
                onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
              ),
            ),
            validator: _required,
          ),
          const SizedBox(height: 20),
          GradientButton(
            height: 48,
            onPressed: _busy ? null : _login,
            child: Text(_busy ? 'INGRESANDO...' : 'INICIAR SESIÓN'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resendVerification,
            child: const Text('¿No te llegó el correo de verificación? Reenviar', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return Form(
      key: _registerForm,
      child: ListView(
        padding: const EdgeInsets.only(top: 10),
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: _required,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _required,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _password,
            obscureText: _obscureRegisterPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña (mínimo 8 caracteres)',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureRegisterPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.textDim,
                ),
                onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
              ),
            ),
            validator: (v) => (v?.length ?? 0) < 8 ? 'Usa al menos 8 caracteres' : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Teléfono / Celular (opcional)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Dirección de Entrega (opcional)',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 18),
          GradientButton(
            height: 48,
            onPressed: _busy ? null : _register,
            child: Text(_busy ? 'CREANDO CUENTA...' : 'REGISTRARSE'),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Este campo es obligatorio' : null;

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _info = null;
      _isSuccessInfo = false;
    });
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
    setState(() {
      _busy = true;
      _info = null;
      _isSuccessInfo = false;
    });
    try {
      await _api.register({
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone_number': _phone.text.trim(),
        'address': _address.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _isSuccessInfo = true;
        _info = '¡Cuenta creada! Revisa tu correo electrónico para confirmar tu cuenta e iniciar sesión.';
      });
      _tabs.animateTo(0);
    } catch (e) {
      if (mounted) setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_loginEmail.text.trim().isEmpty) {
      setState(() {
        _info = 'Escribe tu correo en el campo de inicio de sesión primero.';
        _isSuccessInfo = false;
      });
      return;
    }
    setState(() {
      _busy = true;
      _info = null;
      _isSuccessInfo = false;
    });
    try {
      await _api.resendVerification(_loginEmail.text.trim());
      if (mounted) {
        setState(() {
          _isSuccessInfo = true;
          _info = 'Si tu cuenta requiere verificación, hemos enviado un nuevo enlace a tu correo.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _info = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
