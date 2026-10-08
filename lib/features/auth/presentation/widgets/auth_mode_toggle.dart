import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/segmented_toggle.dart';

enum AuthMode { login, register }

/// Onglets Connexion / Inscription : chaque onglet est une route distincte.
class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({super.key, required this.current, this.loginLabel = 'Connexion', this.registerLabel = 'Inscription'});

  final AuthMode current;
  final String loginLabel;
  final String registerLabel;

  @override
  Widget build(BuildContext context) {
    return SegmentedToggle<AuthMode>(
      selected: current,
      onChanged: (mode) {
        if (mode == current) return;
        context.go(mode == AuthMode.login ? Routes.login : Routes.register);
      },
      options: [
        SegmentedOption(value: AuthMode.login, label: loginLabel),
        SegmentedOption(value: AuthMode.register, label: registerLabel),
      ],
    );
  }
}
