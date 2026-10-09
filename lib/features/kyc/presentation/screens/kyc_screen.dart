import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/access_policy.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/session_controller.dart';
import '../../data/services/document_capture_service.dart';
import '../../domain/entities/kyc_dossier.dart';
import '../providers/kyc_providers.dart';
import '../widgets/access_required_card.dart';
import '../widgets/kyc_labels.dart';
import '../widgets/kyc_piece_card.dart';

/// Maquette « Vérification d'identité », accessible depuis le Profil (retour UX : le KYC ne bloque plus l'inscription).
/// Même écran pour le dossier passager et le dossier conducteur.
class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key, required this.type});

  final KycType type;

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  KycPieceType? _uploading;
  bool _submitting = false;

  void _showError(Object error) {
    final message = error is ApiException ? error.message : 'Une erreur inattendue est survenue.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<CaptureSource?> _chooseSource(KycPieceType piece) async {
    if (piece.requiresLiveCapture) return CaptureSource.frontCamera;
    return showModalBottomSheet<CaptureSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, CaptureSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(context, CaptureSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPiece(KycPieceType piece) async {
    final source = await _chooseSource(piece);
    if (source == null || !mounted) return;
    final path = await ref.read(documentCaptureServiceProvider).capture(source);
    if (path == null || !mounted) return;

    setState(() => _uploading = piece);
    try {
      await ref.read(kycControllerProvider.notifier).uploadPiece(widget.type, piece, path);
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(kycControllerProvider.notifier).submit(widget.type);
      if (mounted) context.pushReplacement(Routes.kycSubmitted(widget.type.apiValue));
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dossiers = ref.watch(kycControllerProvider);
    final user = ref.watch(sessionControllerProvider).value;
    final dossier = dossiers.value?[widget.type];

    final blockedByPassager =
        widget.type == KycType.conducteur && user != null && !AccessPolicy.canStartDriverKyc(user);

    return Scaffold(
      body: SafeArea(
        child: switch (dossiers) {
          AsyncValue(:final error?) when dossier == null => _ErrorState(
              message: error is ApiException ? error.message : 'Impossible de charger votre dossier.',
              onRetry: () => ref.invalidate(kycControllerProvider),
            ),
          _ when dossier == null => const Center(child: CircularProgressIndicator()),
          _ => _content(dossier, blockedByPassager),
        },
      ),
      bottomNavigationBar: dossier == null || blockedByPassager ? null : _bottomBar(dossier),
    );
  }

  Widget _content(KycDossier dossier, bool blockedByPassager) {
    final step = (dossier.providedCount + 1).clamp(1, dossier.pieces.length);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _Header(stepLabel: dossier.isEditable ? 'Étape $step sur ${dossier.pieces.length}' : null),
        const SizedBox(height: AppSpacing.lg),
        const Center(child: _ShieldIcon()),
        const SizedBox(height: AppSpacing.md),
        ScreenHeader(title: widget.type.title, subtitle: widget.type.subtitle, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.lg),
        if (blockedByPassager)
          const AccessRequiredCard(denial: AccessDenial.kycPassagerMissing)
        else ...[
          _StatusBanner(dossier: dossier),
          StepProgress(
            completed: dossier.providedCount,
            total: dossier.pieces.length,
            stepLabels: widget.type == KycType.passager
                ? const ['Photo de profil', 'Pièce d’identité', 'Selfie']
                : const ['Permis', 'Document', 'Véhicule'],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final piece in dossier.pieces) ...[
            KycPieceCard(
              piece: piece,
              isUploading: _uploading == piece.type,
              onTap: dossier.isEditable && _uploading == null && !_submitting ? () => _addPiece(piece.type) : null,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }

  Widget _bottomBar(KycDossier dossier) {
    final Widget button;
    if (!dossier.isEditable) {
      button = PrimaryButton.outlined(label: 'Retour au profil', onPressed: () => context.pop());
    } else if (dossier.isComplete) {
      button = PrimaryButton(
        label: 'Envoyer mon dossier',
        icon: Icons.send_rounded,
        isLoading: _submitting,
        onPressed: _uploading == null ? _submit : null,
      );
    } else {
      final next = dossier.nextMissing!.type;
      button = PrimaryButton(
        label: next.requiresLiveCapture ? 'Capturer le selfie' : 'Ajouter : ${next.title}',
        icon: next.requiresLiveCapture ? Icons.photo_camera_outlined : Icons.add_a_photo_outlined,
        onPressed: _uploading == null ? () => _addPiece(next) : null,
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.xs, AppSpacing.screenPadding, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            button,
            if (dossier.isEditable) ...[
              const SizedBox(height: AppSpacing.xs),
              const Text('Vous pourrez reprendre la photo si nécessaire.', style: AppTextStyles.caption),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.stepLabel});

  final String? stepLabel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton.outlined(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Retour',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          ),
        ),
        if (stepLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(stepLabel!, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
          ),
      ],
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2.5),
      ),
      child: const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 30),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.dossier});

  final KycDossier dossier;

  @override
  Widget build(BuildContext context) {
    final banner = switch (dossier.status) {
      KycStatus.enAttente => const InfoBanner(
          icon: Icons.hourglass_top_rounded,
          tone: InfoBannerTone.accent,
          title: 'Dossier en cours de vérification',
          subtitle: 'Un administrateur examine vos pièces. Vous serez notifié de sa décision.',
        ),
      KycStatus.verifie => const InfoBanner(icon: Icons.verified_outlined, title: 'Dossier vérifié'),
      KycStatus.rejete => InfoBanner(
          icon: Icons.error_outline_rounded,
          tone: InfoBannerTone.error,
          title: 'Dossier refusé',
          subtitle: dossier.motifRejet ?? 'Merci de renvoyer vos pièces.',
        ),
      KycStatus.nonVerifie => null,
    };
    if (banner == null) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: banner);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton.outlined(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
