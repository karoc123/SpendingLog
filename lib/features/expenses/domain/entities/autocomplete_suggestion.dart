/// Autocomplete suggestion returned when typing a description.
class AutocompleteSuggestion {
  final String description;
  final int categoryId;
  final int amountCents;
  final int frequency;

  const AutocompleteSuggestion({
    required this.description,
    required this.categoryId,
    required this.amountCents,
    required this.frequency,
  });
}
