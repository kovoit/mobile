import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/mock/fake_after_trip.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/widgets.dart';
import '../data/rating_repository_impl.dart';
import '../domain/rating_repository.dart';

/// Réservations déjà notées pendant la session : le bouton « Noter » disparaît sans attendre.
/// Le backend reste juge (`DEJA_NOTE`) : il ne renvoie pas cette information avec la réservation.
class RatedBookings extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String bookingId) => state = {...state, bookingId};
}

final ratedBookingsProvider = NotifierProvider<RatedBookings, Set<String>>(RatedBookings.new);

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  if (Env.useMockApi) return FakeRatingRepository(ref.watch(fakeAfterTripProvider));
  return ApiRatingRepository(ref.watch(apiServiceProvider));
});

/// Feuille « Noter » (CA8) : 1 à 5 étoiles + commentaire optionnel. Même composant pour
/// le passager (note le conducteur) et le conducteur (note le passager).
/// Renvoie `true` si la note est enregistrée.
class RatingSheet extends ConsumerStatefulWidget {
  const RatingSheet({super.key, required this.bookingId, required this.personName});

  final String bookingId;

  /// Prénom de la personne notée.
  final String personName;

  static Future<bool?> show(BuildContext context, {required String bookingId, required String personName}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => RatingSheet(bookingId: bookingId, personName: personName),
      );

  @override
  ConsumerState<RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<RatingSheet> {
  final _comment = TextEditingController();
  int _note = 0;
  bool _sending = false;
  String? _error;

  static const _labels = ['Très décevant', 'Décevant', 'Correct', 'Bien', 'Excellent'];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_note == 0) {
      setState(() => _error = 'Choisissez une note.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(ratingRepositoryProvider).rate(bookingId: widget.bookingId, note: _note, comment: _comment.text);
      ref.read(ratedBookingsProvider.notifier).add(widget.bookingId);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (e.code == 'DEJA_NOTE') ref.read(ratedBookingsProvider.notifier).add(widget.bookingId);
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Notez ${widget.personName}', style: AppTextStyles.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xxs),
          const Text(
            'Votre note reste anonyme et aide la communauté Kovoit.',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = RatingRepository.minNote; i <= RatingRepository.maxNote; i++)
                IconButton(
                  onPressed: _sending ? null : () => setState(() => _note = i),
                  iconSize: 40,
                  tooltip: '$i étoile${i > 1 ? 's' : ''}',
                  icon: Icon(
                    i <= _note ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i <= _note ? AppColors.accent : AppColors.textDisabled,
                  ),
                ),
            ],
          ),
          Text(
            _note == 0 ? ' ' : _labels[_note - 1],
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(color: AppColors.warning),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: RatingRepository.maxCommentLength,
            enabled: !_sending,
            decoration: const InputDecoration(hintText: 'Un commentaire ? (facultatif)'),
          ),
          if (_error != null) ...[
            Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSpacing.xs),
          ],
          PrimaryButton(label: 'Envoyer ma note', isLoading: _sending, onPressed: _submit),
        ],
      ),
    );
  }
}
