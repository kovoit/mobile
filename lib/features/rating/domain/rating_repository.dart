/// Notation après un trajet : 1 à 5 étoiles + commentaire optionnel, des deux côtés.
/// L'auteur (passager ou conducteur) est déduit de la session par le backend.
abstract interface class RatingRepository {
  static const int minNote = 1;
  static const int maxNote = 5;
  static const int maxCommentLength = 300;

  Future<void> rate({required String bookingId, required int note, String? comment});
}
