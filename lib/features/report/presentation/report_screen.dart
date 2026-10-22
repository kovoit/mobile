import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../data/report_repository_impl.dart';
import '../domain/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  if (Env.useMockApi) return FakeReportRepository(ref.watch(fakeAfterTripProvider));
  return ApiReportRepository(ref.watch(apiServiceProvider));
});

/// « Signaler un problème » pendant ou après le trajet (spéc. §Sécurité), vers l'administrateur.
/// Renvoie `true` via `pop` quand le signalement est envoyé.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.bookingId, required this.otherName});

  final String bookingId;

  /// Prénom de l'autre partie (conducteur ou passager).
  final String otherName;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _description = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null || _description.text.trim().isEmpty) {
      setState(() => _error = 'Choisissez un motif et décrivez le problème.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(reportRepositoryProvider).report(
            bookingId: widget.bookingId,
            reason: _reason!,
            description: _description.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signalement envoyé. Notre équipe vous recontactera.')),
      );
      context.pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KovoitAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          ScreenHeader(
            title: 'Signaler un problème',
            subtitle: 'Trajet avec ${widget.otherName}. Votre signalement est transmis à l’équipe Kovoit.',
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            icon: Icons.health_and_safety_outlined,
            tone: InfoBannerTone.error,
            title: 'En cas de danger immédiat, contactez d’abord les services d’urgence.',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Motif', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          KovoitCard(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() {
                _reason = value;
                _error = null;
              }),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      value: reason,
                      enabled: !_sending,
                      activeColor: AppColors.primary,
                      title: Text(reason.label, style: AppTextStyles.body),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Que s’est-il passé ?', style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _description,
            enabled: !_sending,
            maxLines: 5,
            maxLength: ReportRepository.maxDescriptionLength,
            decoration: const InputDecoration(hintText: 'Décrivez la situation : heure, lieu, ce qui s’est passé…'),
          ),
          if (_error != null) ...[
            Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.sm),
          ],
          const Text(
            'Après un trajet terminé, le paiement est gelé le temps que l’administrateur examine la situation.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(label: 'Envoyer le signalement', isLoading: _sending, onPressed: _submit),
        ],
      ),
    );
  }
}
