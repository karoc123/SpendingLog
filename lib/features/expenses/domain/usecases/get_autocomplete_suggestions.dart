import '../entities/autocomplete_suggestion.dart';
import '../repositories/expense_repository.dart';

class GetAutocompleteSuggestions {
  final ExpenseRepository _repository;

  GetAutocompleteSuggestions(this._repository);

  Future<List<AutocompleteSuggestion>> call(String query) {
    if (query.trim().isEmpty) return Future.value([]);
    return _repository.getAutocompleteSuggestions(query.trim());
  }
}
