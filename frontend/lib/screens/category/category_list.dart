import 'package:flutter/material.dart';
import 'package:frontend/helpers/icon_utils.dart';
import 'package:frontend/widgets/loading_widget.dart';
import '../../services/api_service.dart';
import 'category_form_screen.dart';
import 'package:frontend/models/category.dart';
import 'package:frontend/widgets/custom_scaffold.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  final ApiService api = ApiService();
  bool isLoading = true;
  List<Category> allCategories = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => isLoading = true);
    try {
      final data = await api.getCategories();
      setState(() {
        allCategories = data.map((json) => Category.fromJson(json)).toList();
      });
    } catch (e) {
      debugPrint('Error al cargar categorías: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Category> _filterByType(String type) {
    return allCategories.where((c) => c.type == type).toList();
  }

  void _navigateToAddCategory() {
    final currentTab = _tabController.index == 0 ? 'income' : 'expense';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormScreen(type: currentTab),
      ),
    ).then((value) {
       _fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeCategories = _filterByType('income');
    final expenseCategories = _filterByType('expense');

    return CustomScaffold(
      title: 'Categorías',
      currentRoute: 'categories_list',
      actions: [
        /*
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchCategories,
        ),
        */
         Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
            tooltip: 'Agregar nueva categoría',
          onPressed: _navigateToAddCategory,
        ),
        ),
      ],
      body: Column(
        children: [
          //Barra de pestañas
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
             labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'Ingresos'),
              Tab(text: 'Gastos'),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(child: LoadingWidget(message: 'Cargando categorías...'))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryList(incomeCategories),
                      _buildCategoryList(expenseCategories),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories) {
    if (categories.isEmpty) {
      return const Center(child: Text('No hay categorías cargadas'));
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        final color = Color(int.parse(c.color.substring(1), radix: 16) + 0xFF000000) ;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),  
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.fromName(c.icon),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Nombre 
                Expanded(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!c.isDefault) ...[
                IconButton(
                  icon:  Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryFormScreen(
                          type: c.type,
                          category: c,
                        ),
                      ),
                    ).then((value) => _fetchCategories());
                  },
                ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}
