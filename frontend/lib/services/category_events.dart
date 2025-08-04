import 'package:get/get.dart';

class CategorySelectionEvent {
  final List<String> selectedIds;
  final List<String> selectedNames;
  final bool isAllSelected;

  CategorySelectionEvent({
    required this.selectedIds,
    required this.selectedNames,
    required this.isAllSelected,
  });
}

class CategoryEventBus {
  static final Rx<CategorySelectionEvent> _categorySelection = 
      CategorySelectionEvent(
        selectedIds: [],
        selectedNames: [], 
        isAllSelected: true,
      ).obs;

  static Rx<CategorySelectionEvent> get currentSelection => _categorySelection;
  static Stream<CategorySelectionEvent> get stream => _categorySelection.stream;
  
  static void publish(CategorySelectionEvent event) {
    _categorySelection.value = event;
  }
}