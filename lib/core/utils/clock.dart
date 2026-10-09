import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Horloge injectable (surchargée dans les tests).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
