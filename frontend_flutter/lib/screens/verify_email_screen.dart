import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../widgets/store_scaffold.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.token});
  final String token;
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  String _message = 'Verificando tu correo…';
  bool? _success;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    if (widget.token.isEmpty) {
      setState(() { _success = false; _message = 'El enlace no contiene un token de verificación.'; });
      return;
    }
    try {
      await context.read<ApiClient>().verifyEmail(widget.token);
      if (mounted) setState(() { _success = true; _message = 'Tu cuenta quedó verificada. Ya puedes iniciar sesión.'; });
    } catch (e) {
      if (mounted) setState(() { _success = false; _message = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) => StoreScaffold(
        title: 'ElectroPhone',
        body: Center(child: Card(margin: const EdgeInsets.all(20), child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(_success == null ? Icons.mark_email_read_outlined : _success! ? Icons.check_circle_outline : Icons.error_outline, size: 56, color: _success == false ? Colors.redAccent : Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(_message, textAlign: TextAlign.center),
          if (_success != null) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: () => context.go('/login'), child: const Text('Ir a iniciar sesión')),
          ],
        ])))),
      );
}
