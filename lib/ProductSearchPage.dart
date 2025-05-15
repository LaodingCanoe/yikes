import 'package:flutter/material.dart';
import 'db_class.dart';

final dbHelper = DatabaseHelper();

class ProductSearchPage extends StatefulWidget {
  @override
  _ProductSearchPageState createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  String? selectedGender = 'Мужчинам';
  Future<List<Map<String, dynamic>>>? categoriesFuture;
  Future<List<Map<String, dynamic>>>? brandsFuture;
  Widget? frameContent;
  String searchQuery = '';
  int? selectedCategoryId;
  int? selectedBrandId;
  String? selectedCategoryName;
  String? selectedBrandName;
  final TextEditingController _searchController = TextEditingController();
  
  // Фильтры
  Map<String, dynamic> activeFilters = {};
  int filteredProductsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    frameContent = _buildInitialContent();
  }

  void _loadData() {
    setState(() {
      categoriesFuture = dbHelper.fetchCategories(gender: [selectedGender == 'Мужчинам'
          ? 'gendrCode=1'
          : 'gendrCode=2']);
      brandsFuture = dbHelper.fetchBrand();
    });
  }

  void _updateCategories(String gender) {
    setState(() {
      selectedGender = gender;
      categoriesFuture = dbHelper.fetchCategories(gender: [gender == 'Мужчинам'
          ? 'gendrCode=1'
          : 'gendrCode=2']);
      frameContent = _buildInitialContent();
      _resetSelections();
    });
  }

  void _resetSelections() {
    setState(() {
      selectedCategoryId = null;
      selectedBrandId = null;
      selectedCategoryName = null;
      selectedBrandName = null;
      searchQuery = '';
      _searchController.clear();
      activeFilters = {};
    });
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      activeFilters = filters;
    });
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
                  onPressed: () => _updateCategories('Мужчинам'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender == 'Мужчинам'
                        ? const Color(0xFF333333)
                        : const Color(0xFFC7C7C7),
                    foregroundColor: selectedGender == 'Мужчинам'
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('Мужчинам'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateCategories('Женщинам'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender == 'Женщинам'
                        ? const Color(0xFF333333)
                        : const Color(0xFFC7C7C7),
                    foregroundColor: selectedGender == 'Женщинам'
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text('Женщинам'),
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
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Нет доступных категорий'));
                    } else {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final item = snapshot.data![index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryId = item['ID'];
                                selectedCategoryName = item['Название'];
                                selectedBrandId = null;
                                selectedBrandName = null;
                                searchQuery = '';
                                _searchController.clear();
                                frameContent = _buildProductSearchPage();
                              });
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item['ПутьФото'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'BlackOpsOne',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                SizedBox(height: 20),
                Text("Бренды", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: brandsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Ошибка: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('Нет доступных брендов'));
                    } else {
                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final brand = snapshot.data![index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedBrandId = brand['ID'];
                                    selectedBrandName = brand['Название'];
                                    selectedCategoryId = null;
                                    selectedCategoryName = null;
                                    searchQuery = '';
                                    _searchController.clear();
                                    frameContent = _buildProductSearchPage();
                                  });
                                },
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(brand['ПутьФото']),
                                    ),
                                    SizedBox(height: 5),
                                    Text(brand['Название']),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildProductSearchPage() {
  return Column(
    children: [
      SizedBox(
        height: 60,
        child: _buildFiltersRow(),
      ),
      // Expanded(
      //   child: ProductCart(
      //     key: ValueKey('product_cart_${selectedGender}_${selectedCategoryId}_${selectedBrandId}_$searchQuery${activeFilters.hashCode}'),
      //     gendrCode: selectedGender == 'Мужчинам' ? 1 : 2,
      //     layoutType: LayoutType.grid,
      //     categories: selectedCategoryId,
      //     subcategory: null,
      //     shuffle: true,
      //     searchQuery: searchQuery,
      //     brandId: selectedBrandId,
      //     filters: activeFilters,
      //     color: activeFilters['color'],
      //     onProductsCountChanged: (count) {
      //       if (mounted) {
      //         setState(() => filteredProductsCount = count);
      //       }
      //     },
      //   ),
      // ),
    ],
  );
}

  Widget _buildFiltersRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      height: 60,
      child: Row(
        children: [
          if (selectedCategoryId != null || 
              selectedBrandId != null || 
              searchQuery.isNotEmpty || 
              activeFilters.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _resetSelections();
                  frameContent = _buildInitialContent();
                });
              },
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (selectedCategoryName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(selectedCategoryName!),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            selectedCategoryId = null;
                            selectedCategoryName = null;
                            if (selectedBrandId == null && 
                                searchQuery.isEmpty && 
                                activeFilters.isEmpty) {
                              frameContent = _buildInitialContent();
                            }
                          });
                        },
                      ),
                    ),
                  if (selectedBrandName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(selectedBrandName!),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            selectedBrandId = null;
                            selectedBrandName = null;
                            if (selectedCategoryId == null && 
                                searchQuery.isEmpty && 
                                activeFilters.isEmpty) {
                              frameContent = _buildInitialContent();
                            }
                          });
                        },
                      ),
                    ),
                  if (searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Поиск: $searchQuery'),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            searchQuery = '';
                            _searchController.clear();
                            if (selectedCategoryId == null && 
                                selectedBrandId == null && 
                                activeFilters.isEmpty) {
                              frameContent = _buildInitialContent();
                            }
                          });
                        },
                      ),
                    ),
                  if (activeFilters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text('Фильтры ($filteredProductsCount)'),
                        deleteIcon: Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            activeFilters = {};
                            if (selectedCategoryId == null && 
                                selectedBrandId == null && 
                                searchQuery.isEmpty) {
                              frameContent = _buildInitialContent();
                            }
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Поиск...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  if (query.isNotEmpty) {
                    setState(() {
                      searchQuery = query;
                      frameContent = _buildProductSearchPage();
                    });
                  } else {
                    setState(() {
                      searchQuery = '';
                      if (selectedCategoryId == null && selectedBrandId == null) {
                        frameContent = _buildInitialContent();
                      } else {
                        frameContent = _buildProductSearchPage();
                      }
                    });
                  }
                },
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
              ),
              SizedBox(height: 10),
              Expanded(
                child: frameContent!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}