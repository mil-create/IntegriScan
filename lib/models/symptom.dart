class Symptom {
  final String id;
  final String label;

  const Symptom({required this.id, required this.label});

  static const all = [
    Symptom(id: 'itching', label: 'Itching'),
    Symptom(id: 'redness', label: 'Redness'),
    Symptom(id: 'flaking', label: 'Flaking / Scaling'),
    Symptom(id: 'bumps', label: 'Bumps or Lesions'),
    Symptom(id: 'discoloration', label: 'Discoloration'),
    Symptom(id: 'swelling', label: 'Swelling'),
    Symptom(id: 'pain', label: 'Pain or Tenderness'),
    Symptom(id: 'oozing', label: 'Oozing / Crusting'),
    Symptom(id: 'hairloss', label: 'Hair Thinning / Loss'),
  ];
}
