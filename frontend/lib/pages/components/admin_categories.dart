import 'package:flutter/material.dart';
import '../../services/api_service.dart';

const Color kBrandRed = Color(0xFFE4252A);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextMuted = Color(0xFF6B6B6B);
const Color kBackground = Colors.white;
const Color kSurface = Color(0xFFF7F7F7);
const Color kBorder = Color(0xFFEAEAEA);

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  List<Map<String, dynamic>> categories = [];
  bool isLoading = true;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getCategories();
      if (result['success']) {
        setState(() {
          categories = List<Map<String, dynamic>>.from(result['data']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showSnackBar(
          result['error'] ?? 'Failed to load categories',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar('Error loading categories: $e', Colors.red);
    }
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await ApiService.createCategory(
      name: _nameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result['success']) {
      Navigator.of(context).pop();
      _showSnackBar('Category created successfully', Colors.green);
      _clearForm();
      fetchCategories();
    } else {
      _showSnackBar(result['error'] ?? 'Failed to create category', Colors.red);
    }
  }

  Future<void> _deleteCategory(int categoryId) async {
    final result = await ApiService.deleteCategory(categoryId);

    if (result['success']) {
      _showSnackBar('Category deleted successfully', Colors.green);
      fetchCategories();
    } else {
      _showSnackBar(result['error'] ?? 'Failed to delete category', Colors.red);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _displayNameController.clear();
    _descriptionController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  void _showCreateCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name (slug)',
                  hintText: 'e.g., electronics',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Category name is required';
                  }
                  if (value.contains(' ')) {
                    return 'Use underscores instead of spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g., Electronics',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief description of the category',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _createCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandRed,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "$categoryName"? This will deactivate the category.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCategory(categoryId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: const Text('Manage Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header with create button
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${categories.length} Categories',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateCategoryDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightGreenAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Categories list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kBrandRed),
                  )
                : categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No categories found',
                          style: TextStyle(color: kTextMuted),
                        ),
                      )
                    : ListView.builder(
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                category['display_name'] ?? category['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kTextDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Slug: ${category['name']}',
                                    style: const TextStyle(
                                      color: kTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (category['description'] != null &&
                                      category['description'].isNotEmpty)
                                    Text(
                                      category['description'],
                                      style: const TextStyle(
                                        color: kTextMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmation(
                                  category['id'],
                                  category['display_name'] ?? category['name'],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
