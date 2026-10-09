import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_providers.dart';

/// Déclaration du véhicule (absente des maquettes, style « Espace Conducteur »).
/// La photo du véhicule fait partie du dossier KYC conducteur.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key});

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _couleur = TextEditingController();
  final _immatriculation = TextEditingController();
  VehicleType _type = VehicleType.voiture;
  int _places = 5;
  bool _saving = false;
  bool _prefilled = false;
  Map<String, String> _fieldErrors = const {};

  /// Places totales, conducteur compris : une moto en a 2.
  static int _maxPlaces(VehicleType type) => type == VehicleType.moto ? 2 : 9;

  @override
  void dispose() {
    _marque.dispose();
    _modele.dispose();
    _couleur.dispose();
    _immatriculation.dispose();
    super.dispose();
  }

  void _prefill(Vehicle? vehicle) {
    if (_prefilled || vehicle == null) return;
    _prefilled = true;
    _type = vehicle.type;
    _places = vehicle.nbPlaces;
    _marque.text = vehicle.marque;
    _modele.text = vehicle.modele;
    _couleur.text = vehicle.couleur;
    _immatriculation.text = vehicle.immatriculation;
  }

  void _changeType(VehicleType type) => setState(() {
        _type = type;
        _places = type == VehicleType.moto ? 2 : (_places < 2 ? 5 : _places.clamp(2, _maxPlaces(type)));
      });

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(myVehicleProvider.notifier).save(
            Vehicle(
              type: _type,
              marque: _marque.text.trim(),
              modele: _modele.text.trim(),
              couleur: _couleur.text.trim(),
              immatriculation: _immatriculation.text.trim().toUpperCase(),
              nbPlaces: _places,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Véhicule enregistré.')));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e is BadRequestApiException ? e.fieldErrors : const {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref.watch(myVehicleProvider);
    _prefill(vehicle.value);

    return Scaffold(
      appBar: const KovoitAppBar(),
      body: vehicle.isLoading && !vehicle.hasValue
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  const ScreenHeader(
                    title: 'Mon véhicule',
                    subtitle: 'Ces informations sont visibles par vos passagers avant la prise en charge.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedToggle<VehicleType>(
                    selected: _type,
                    onChanged: _changeType,
                    options: const [
                      SegmentedOption(value: VehicleType.moto, label: 'Moto', icon: Icons.two_wheeler_rounded),
                      SegmentedOption(
                        value: VehicleType.voiture,
                        label: 'Voiture',
                        icon: Icons.directions_car_filled_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  KovoitCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KovoitTextField(
                          label: 'Marque',
                          hint: _type == VehicleType.moto ? 'Haojue' : 'Toyota',
                          controller: _marque,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(v, message: 'La marque est obligatoire.'),
                          errorText: _fieldErrors['marque'],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KovoitTextField(
                          label: 'Modèle',
                          hint: _type == VehicleType.moto ? 'HJ125' : 'Yaris',
                          controller: _modele,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(v, message: 'Le modèle est obligatoire.'),
                          errorText: _fieldErrors['modele'],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KovoitTextField(
                          label: 'Couleur',
                          hint: 'Gris',
                          controller: _couleur,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.required(v, message: 'La couleur est obligatoire.'),
                          errorText: _fieldErrors['couleur'],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        KovoitTextField(
                          label: 'Immatriculation',
                          hint: 'TG 4827 AU',
                          controller: _immatriculation,
                          prefixIcon: Icons.pin_outlined,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          validator: (v) => Validators.required(v, message: 'L’immatriculation est obligatoire.'),
                          errorText: _fieldErrors['immatriculation'],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Nombre de places', style: AppTextStyles.label),
                                  Text('Conducteur compris', style: AppTextStyles.caption),
                                ],
                              ),
                            ),
                            PlaceStepper(
                              value: _places,
                              min: 2,
                              max: _maxPlaces(_type),
                              onChanged: (v) => setState(() => _places = v),
                            ),
                          ],
                        ),
                        if (_fieldErrors['nb_places'] != null)
                          Text(_fieldErrors['nb_places']!, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const InfoBanner(
                    icon: Icons.photo_camera_outlined,
                    tone: InfoBannerTone.accent,
                    title: 'La photo du véhicule se joint au dossier conducteur.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(label: 'Enregistrer mon véhicule', isLoading: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}
