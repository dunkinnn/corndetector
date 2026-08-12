// Reference symptom and fertilizer guidance for a deficiency label, one row
// in the `deficiency_reference` table.
class DeficiencyReference {
  const DeficiencyReference({
    required this.label,
    required this.symptom,
    required this.fertilizer,
    required this.rate,
    required this.timing,
    required this.note,
  });

  final String label;
  final String symptom;
  final String fertilizer;
  final String rate;
  final String timing;
  final String note;

  factory DeficiencyReference.fromMap(Map<String, dynamic> map) {
    return DeficiencyReference(
      label: map['label'] as String,
      symptom: map['symptom'] as String,
      fertilizer: map['fertilizer'] as String,
      rate: map['rate'] as String,
      timing: map['timing'] as String,
      note: map['note'] as String,
    );
  }
}
