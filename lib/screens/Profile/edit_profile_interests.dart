import 'package:flutter/material.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InterestSelectionScreen extends StatefulWidget {
  final List<String> selectedCategoryIds;

  const InterestSelectionScreen({required this.selectedCategoryIds, Key? key}) : super(key: key);

  @override
  State<InterestSelectionScreen> createState() => _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> categories = [];
  List<String> selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    selectedCategoryIds = List.from(widget.selectedCategoryIds);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await supabase.from('categories').select('category_id, name');
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  void _toggleCategory(String categoryId) {
    setState(() {
      if (selectedCategoryIds.contains(categoryId)) {
        selectedCategoryIds.remove(categoryId);
      } else {
        selectedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryIds.contains(category['category_id']);

          return ListTile(
            title: Text(category['name']),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () => _toggleCategory(category['category_id']),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, selectedCategoryIds),
        child: const Icon(Icons.done),
      ),
    );
  }
}
