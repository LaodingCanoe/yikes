import 'package:flutter/material.dart';
import 'db_class.dart';
import 'ProductCart.dart';
import 'filter_sheet.dart';

final dbHelper = DatabaseHelper();

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? selectedGender = 'Мужчинам';
  Future<List<Map<String, dynamic>>>? categoriesFuture;
  Future<List<Map<String, dynamic>>>? brandsFuture;
  Future<List<Map<String, dynamic>>>? tagsFuture;

  bool showSearchResults = false;
  String searchQuery = '';
  List<String>? selectedCategories;
  List<String>? selectedBrands;
  List<String>? selectedTags;

  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic> activeFilters = {};
  int filteredProductsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      categoriesFuture = dbHelper.fetchCategories(
        gender: [selectedGender == 'Мужчинам' ? 'Мужской' : 'Женский'],
        isAdd: true,
      );
      brandsFuture = dbHelper.fetchBrand();
      tagsFuture = dbHelper.fetchTags();
    });
  }

  void _updateCategories(String gender) {
    selectedGender = gender;
    _resetSelections();
    _loadData();
  }

  void _resetSelections() {
    selectedCategories = null;
    selectedBrands = null;
    selectedTags = null;
    activeFilters = {};
    searchQuery = '';
    _searchController.clear();
    showSearchResults = false;
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      activeFilters = Map.from(filters); 
      showSearchResults = true;
    });
  }

  void _showFilterSheet() async {
    final categories = await categoriesFuture ?? [];
    final brands = await brandsFuture ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        builder: (_, controller) => FilterSheet(
          categories: categories,
          brands: brands,
          onApplyFilters: _applyFilters,
          initialFilters: activeFilters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (value) {
                      setState(() {
                        searchQuery = value;
                        selectedCategories = null;
                        selectedBrands = null;
                        selectedTags = null;
                        showSearchResults = true;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  height: 48,
                  child: IconButton(
                    icon: Icon(Icons.filter_list, size: 28),
                    onPressed: _showFilterSheet,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (activeFilters.isNotEmpty || 
              selectedCategories != null || 
              selectedBrands != null || 
              selectedTags != null || 
              searchQuery.isNotEmpty)
            _buildSelectedFiltersRow(),
          Expanded(
            child: showSearchResults ? _buildProductSearchPage() : _buildInitialContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Chip(
        label: Text(label),
        deleteIcon: Icon(Icons.close),
        onDeleted: onDeleted,
      ),
    );
  }

  void _checkIfFiltersCleared() {
    if (searchQuery.isEmpty &&
        selectedCategories == null &&
        selectedBrands == null &&
        selectedTags == null &&
        activeFilters.isEmpty) {
      showSearchResults = false;
    }
  }

  Widget _buildSelectedFiltersRow() {
  List<Widget> chips = [];

  // Обрабатываем поисковый запрос
  if (searchQuery.isNotEmpty) {
    chips.add(_buildFilterChip(searchQuery, () {
      setState(() {
        searchQuery = '';
        _searchController.clear();
        _checkIfFiltersCleared();
      });
    }));
  }

  // Обрабатываем активные фильтры
  activeFilters.forEach((key, value) {
    if (value is List) {
      for (var item in value) {
        chips.add(_buildFilterChip(item.toString(), () {
          setState(() {
            // Удаляем элемент из фильтров
            if (key == 'categories') {
              selectedCategories?.remove(item);
              if (selectedCategories?.isEmpty ?? true) {
                selectedCategories = null;
              }
            } else if (key == 'brands') {
              selectedBrands?.remove(item);
              if (selectedBrands?.isEmpty ?? true) {
                selectedBrands = null;
              }
            } else if (key == 'tags') {
              selectedTags?.remove(item);
              if (selectedTags?.isEmpty ?? true) {
                selectedTags = null;
              }
            }
            
            value.remove(item);
            if (value.isEmpty) activeFilters.remove(key);
            _checkIfFiltersCleared();
          });
        }));
      }
    } else if (key == 'minPrice' || key == 'maxPrice') {
      // Обработка цен будет в отдельном условии
    } else if (key != 'gender') { // Исключаем гендер из отображаемых фильтров
      chips.add(_buildFilterChip(value.toString(), () {
        setState(() {
          activeFilters.remove(key);
          _checkIfFiltersCleared();
        });
      }));
    }
  });

  // Добавляем фильтр цены, если он есть
  if (activeFilters.containsKey('minPrice') || activeFilters.containsKey('maxPrice')) {
    final minPrice = activeFilters.containsKey('minPrice')
        ? (activeFilters['minPrice'] is double 
            ? activeFilters['minPrice'].toInt() 
            : activeFilters['minPrice'])
        : null;
    final maxPrice = activeFilters.containsKey('maxPrice')
        ? (activeFilters['maxPrice'] is double 
            ? activeFilters['maxPrice'].toInt() 
            : activeFilters['maxPrice'])
        : null;
    
    String priceText = '';
    if (minPrice != null && maxPrice != null) {
      priceText = '${minPrice}₽-${maxPrice}₽';
    } else if (minPrice != null) {
      priceText = 'от ${minPrice}₽';
    } else if (maxPrice != null) {
      priceText = 'до ${maxPrice}₽';
    }
    
    chips.add(_buildFilterChip(priceText, () {
      setState(() {
        activeFilters.remove('minPrice');
        activeFilters.remove('maxPrice');
        _checkIfFiltersCleared();
      });
    }));
  }

  return Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips,
      ),
    ),
  );
}
  
  Widget _buildInitialContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _updateCategories('Мужчинам')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender == 'Мужчинам' ? Color(0xFF333333) : Color(0xFFC7C7C7),
                  ),
                  child: const Text('Мужчинам', style: TextStyle(color: Colors.white)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _updateCategories('Женщинам')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender == 'Женщинам' ? Color(0xFF333333) : Color(0xFFC7C7C7),
                  ),
                  child: const Text('Женщинам', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Категории", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _buildCategoriesList(),
                SizedBox(height: 20),
                Text("Бренды", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _buildBrandsList(),
                SizedBox(height: 20),
                Text("Теги", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                _buildTagsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final categories = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = categories[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategories = [item['Название']];
                  selectedBrands = null;
                  selectedTags = null;
                  searchQuery = '';
                  _searchController.clear();
                  showSearchResults = true;
                  
                  activeFilters = { 'categories': selectedCategories,
                  'gender': [selectedGender == 'Мужчинам' ? 'Мужской' : 'Женский'],};
                });
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item['ПутьФото'], fit: BoxFit.cover, width: double.infinity),
                  ),
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item['Название'].toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBrandsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: brandsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final brands = snapshot.data!;
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBrands = [brand['Название']];
                      selectedCategories = null;
                      selectedTags = null;
                      searchQuery = '';
                      _searchController.clear();
                      showSearchResults = true;
                      activeFilters.clear();
                      activeFilters = { 'brands': selectedBrands,
                  'gender': [selectedGender == 'Мужчинам' ? 'Мужской' : 'Женский'],};
                    });
                  },
                  child: Column(
                    children: [
                      CircleAvatar(radius: 30, backgroundImage: NetworkImage(brand['ПутьФото'])),
                      SizedBox(height: 5),
                      Text(brand['Название']),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTagsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: tagsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final tags = snapshot.data!;
        return Wrap(
          spacing: 8.0,
          children: tags.map((tag) {
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedTags = [tag['Название']];
                  selectedCategories = null;
                  selectedBrands = null;
                  searchQuery = '';
                  _searchController.clear();
                  showSearchResults = true;
                  activeFilters.clear();
                  activeFilters = { 'tags': selectedTags,
                  'gender': [selectedGender == 'Мужчинам' ? 'Мужской' : 'Женский'],};
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedTags?.contains(tag['Название']) ?? false 
                  ? Color(0xFF333333) 
                  : Color(0xFFC7C7C7),
              ),
              child: Text(
                tag['Название'],
                style: TextStyle(
                  color: selectedTags?.contains(tag['Название']) ?? false 
                    ? Colors.white 
                    : Colors.black
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildProductSearchPage() {
    return ProductCart(
      key: ValueKey('product_${searchQuery}_${selectedCategories}_${selectedBrands}_${selectedTags}_${activeFilters.hashCode}'),
      //gender: activeFilters['gender'],
      layoutType: LayoutType.grid,
      // categories: activeFilters['categories'],
      // brands: activeFilters['brands'],
      // colors: activeFilters['colors'],
      // tags: activeFilters['tags'],
      search: searchQuery.isNotEmpty ? searchQuery : null,
      filters: activeFilters,
      minPrice: activeFilters['minPrice']?.toDouble(),
      maxPrice: activeFilters['maxPrice']?.toDouble(),
      shuffle: true,
      onProductsCountChanged: (count) {
        if (mounted) setState(() => filteredProductsCount = count);
      },
    );
  }
}