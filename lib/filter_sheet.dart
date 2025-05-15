import 'package:flutter/material.dart';
import 'db_class.dart';

final dbHelper = DatabaseHelper();

class FilterSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> brands;
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> initialFilters; // Новый параметр

  const FilterSheet({
    required this.categories,
    required this.brands,
    required this.onApplyFilters,
    required this.initialFilters, 
  });

  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late RangeValues _priceRange;
  Set<String> _selectedCategories = {};
  Set<String> _selectedBrands = {}; 
  Set<String> _selectedTags = {};
  Set<String> _selectedColors = {};
  Set<String> _selectedGender = {};
  List<Map<String, dynamic>> _availableGender = [];
  bool _loadingGender = false;
  List<Map<String, dynamic>> _availableColors = [];
  bool _loadingColors = false;
  double _currentMinPrice = 0;
  double _currentMaxPrice = 100000; // любой стартовый максимум
  List<Map<String, dynamic>> _availableTags = [];
  bool _loadingTags = false;
  List<Map<String, dynamic>> _availableCategories = [];
  bool _loadingCategories = false;
  bool _showAllCategories = false;
  bool _showAllBrands = false;
  




  @override
  void initState() {
    super.initState();
    
    
    // Инициализируем фильтры из initialFilters
    _initializeFromFilters();
    _initializeFromFilters();
    _loadAvailableColors();
    _loadAvailableTags();
    _loadPriceRange();
    _loadAvailableCategories();
    _loadAvailableGender();
  }

void _initializeFromFilters() {
    // Инициализируем выбранные фильтры из initialFilters
    if (widget.initialFilters['minPrice'] != null && 
        widget.initialFilters['maxPrice'] != null) {
      _currentMinPrice = (widget.initialFilters['minPrice'] as num).toDouble();
      _currentMaxPrice = (widget.initialFilters['maxPrice'] as num).toDouble();
    } 
    _priceRange = RangeValues(_currentMinPrice, _currentMaxPrice);

    if (widget.initialFilters['categories'] != null) {
      _selectedCategories = Set<String>.from(widget.initialFilters['categories']);
    }

    if (widget.initialFilters['brands'] != null) {
      _selectedBrands = Set<String>.from(widget.initialFilters['brands']);
    }

    if (widget.initialFilters['tags'] != null) {
      _selectedTags = Set<String>.from(widget.initialFilters['tags']);
    }

    if (widget.initialFilters['colors'] != null) {
      _selectedColors = Set<String>.from(widget.initialFilters['colors']);
    }

    if (widget.initialFilters['gender'] != null) {
      _selectedGender = Set<String>.from(widget.initialFilters['gender']);
    }
  }

  Future<void> _loadAvailableGender() async {
  if (!mounted) return;

  setState(() => _loadingGender = true);

  try {
    print(_selectedColors);
    final genders = await dbHelper.fetchGender(
      // minPrice: _priceRange.start,
      // maxPrice: _priceRange.end,
      category: _selectedCategories.isNotEmpty ? _selectedCategories.toList() : null,
      brand: _selectedBrands.isNotEmpty ? _selectedBrands.toList() : null,
      colors: _selectedColors.isNotEmpty ? _selectedColors.toList() : null,
      tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
    );

    if (!mounted) return;

    setState(() {
      _availableGender = genders;
      _selectedGender.removeWhere(
        (g) => !genders.any((gen) => gen['Название'] == g),
      );
    });
  } catch (e) {
    print('Ошибка загрузки гендера: $e');
    if (mounted) setState(() => _availableGender = []);
  } finally {
    if (mounted) setState(() => _loadingGender = false);
  }
}

  Future<void> _loadAvailableColors() async {
    if (!mounted) return;

    setState(() => _loadingColors = true);

    try {
      final colors = await dbHelper.fetchColors(
        // minPrice: _priceRange.start,
        // maxPrice: _priceRange.end,
        category: _selectedCategories.isNotEmpty ? _selectedCategories.toList() : null,
        brand: _selectedBrands.isNotEmpty ? _selectedBrands.toList() : null, // заменили на brandNames
        tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
        gender: _selectedGender.isNotEmpty ? _selectedGender.toList() : null,
      );


      if (!mounted) return;

      setState(() {
        _availableColors = colors;
        _selectedColors.removeWhere(
          (color) => !colors.any((c) => c['Название'] == color),
        );
      });
    } catch (e) {
      print('Ошибка загрузки цветов: $e');
      if (mounted) setState(() => _availableColors = []);
    } finally {
      if (mounted) setState(() => _loadingColors = false);
    }
  }

  void _handleFilterChange() async{
    await _loadAvailableColors();
    await _loadAvailableGender(); // добавили
    await _loadPriceRange(); 
    await _loadAvailableTags();
    await _loadAvailableCategories();    
  }
  
  Future<void> _loadAvailableTags() async {
  if (!mounted) return;

  setState(() => _loadingTags = true);

  try {
    final tags = await dbHelper.fetchTags(
      // minPrice: _priceRange.start,
      // maxPrice: _priceRange.end,
      category: _selectedCategories.isNotEmpty ? _selectedCategories.toList() : null,
      brand: _selectedBrands.isNotEmpty ? _selectedBrands.toList() : null,
      gender: _selectedGender.isNotEmpty ? _selectedGender.toList() : null,
      colors: _selectedColors.isNotEmpty ? _selectedColors.toList() : null,
    );

    if (!mounted) return;
    setState(() {
      _availableTags = tags;
      _selectedTags.removeWhere(
        (tag) => !tags.any((t) => t['Название'] == tag),
      );
    });
  } catch (e) {
    print('Ошибка загрузки тегов: $e');
    if (mounted) setState(() => _availableTags = []);
  } finally {
    if (mounted) setState(() => _loadingTags = false);
  }
}
Future<void> _loadAvailableCategories() async {
  if (!mounted) return;

  setState(() => _loadingCategories = true);

  try {
    final categories = await dbHelper.fetchCategories(
      // minPrice: _priceRange.start,
      // maxPrice: _priceRange.end,
      isAdd: false,
      tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      brand: _selectedBrands.isNotEmpty ? _selectedBrands.toList() : null,
      gender: _selectedGender.isNotEmpty ? _selectedGender.toList() : null,
      colorNames: _selectedColors.isNotEmpty ? _selectedColors.toList() : null,
    );

    if (!mounted) return;
    setState(() {
      _availableCategories = categories;
      _selectedCategories.removeWhere(
        (catName) => !categories.any((c) => c['Название'] == catName),
      );
    });
  } catch (e) {
    print('Ошибка загрузки категорий: $e');
    if (mounted) setState(() => _availableCategories = []);
  } finally {
    if (mounted) setState(() => _loadingCategories = false);
  }
}


      Future<void> _loadPriceRange() async {
  try {
    final range = await dbHelper.fetchPriceRange(
      categories: _selectedCategories.isNotEmpty ? _selectedCategories.toList() : null,
      brands: _selectedBrands.isNotEmpty ? _selectedBrands.toList() : null,
      tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
      genders: _selectedGender.isNotEmpty ? _selectedGender.toList() : null,
      colors: _selectedColors.isNotEmpty ? _selectedColors.toList() : null,
    );

    if (range != null && mounted) {
      final newMin = (range['minPrice'] as num?)?.toDouble() ?? 0;
      final newMax = (range['maxPrice'] as num?)?.toDouble() ?? 1000000;

      bool wasAtFullRange = (_priceRange.start == _currentMinPrice) && (_priceRange.end == _currentMaxPrice);

      setState(() {
        _currentMinPrice = newMin;
        _currentMaxPrice = newMax;

        if (wasAtFullRange) {
          // Если пользователь не менял ползунок — ставим на новые границы
          _priceRange = RangeValues(newMin, newMax);
        } else {
          // Иначе ограничиваем текущий диапазон в рамках новых значений
          double start = _priceRange.start.clamp(newMin, newMax);
          double end = _priceRange.end.clamp(newMin, newMax);
          _priceRange = RangeValues(start, end);
        }
      });
    }
  } catch (e) {
    print('Ошибка загрузки диапазона цен: $e');
  }
}



  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceFilter(),
                  _buildCategoryFilter(),
                  _buildBrandFilter(),
                  _buildTagFilter(),
                  _buildColorFilter(),
                  _buildGenderFilter(),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final Map<String, dynamic> filters = {
                  'minPrice': _priceRange.start,
                  'maxPrice': _priceRange.end,
                  if (_selectedCategories.isNotEmpty) 
                    'categories': _selectedCategories.toList(),
                  if (_selectedBrands.isNotEmpty) 
                    'brands': _selectedBrands.toList(),
                  if (_selectedTags.isNotEmpty) 
                    'tags': _selectedTags.toList(),
                  if (_selectedColors.isNotEmpty) 
                    'colors': _selectedColors.toList(),
                  if (_selectedGender.isNotEmpty) 
                    'gender': _selectedGender.toList(),
                };
                widget.onApplyFilters(filters);
                Navigator.pop(context);
              },
              child: const Text('Применить'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Фильтры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _priceRange = RangeValues(_currentMinPrice, _currentMaxPrice);
                  _selectedCategories.clear();
                  _selectedBrands.clear();
                  _selectedTags.clear();
                  _selectedColors.clear();
                  _selectedGender.clear();
                });
                _handleFilterChange();
              },
              child: const Text('Сбросить'),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цена', style: TextStyle(fontWeight: FontWeight.bold)),
        RangeSlider(
          values: _priceRange,
          min: _currentMinPrice,
          max: _currentMaxPrice,
          divisions: 10,
          labels: RangeLabels(
            '${_priceRange.start.round()}',
            '${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() => _priceRange = values);
          },
        ),         
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_priceRange.start.round()} руб.'),
            Text('${_priceRange.end.round()} руб.'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Категории', style: TextStyle(fontWeight: FontWeight.bold)),
      ..._availableCategories.map((category) => CheckboxListTile(
        title: Text(category['Название']),
        value: _selectedCategories.contains(category['Название']),
        onChanged: (selected) {
          setState(() {
            if (selected!) {
              _selectedCategories.add(category['Название']);
            } else {
              _selectedCategories.remove(category['Название']);
            }
            _handleFilterChange();
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
      )),
    ],
  );
}

  Widget _buildBrandFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Бренды', style: TextStyle(fontWeight: FontWeight.bold)),
        ...widget.brands.map((brand) => CheckboxListTile(
              title: Text(brand['Название']),
              value: _selectedBrands.contains(brand['Название']),
              onChanged: (selected) {
                setState(() {
                  if (selected!) {
                    _selectedBrands.add(brand['Название']);
                  } else {
                    _selectedBrands.remove(brand['Название']);
                  }
                  _handleFilterChange();
                });
              },
            )),
      ],
    );
  }

Widget _buildTagFilter() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Теги', style: TextStyle(fontWeight: FontWeight.bold)),
      if (_loadingTags)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_availableTags.isEmpty)
        const Text('Нет доступных тегов', style: TextStyle(color: Colors.grey))
      else
        Wrap(
          spacing: 8,
          children: _availableTags.map((tag) => FilterChip(
            label: Text(tag['Название']),
            selected: _selectedTags.contains(tag['Название']),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedTags.add(tag['Название']);
                } else {
                  _selectedTags.remove(tag['Название']);
                }
                _handleFilterChange();
              });
            },
          )).toList(),
        ),
    ],
  );
}

  Widget _buildColorFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Цвет', style: TextStyle(fontWeight: FontWeight.bold)),
        if (_loadingColors)
          const CircularProgressIndicator()
        else if (_availableColors.isEmpty)
          const Text('Нет доступных цветов', style: TextStyle(color: Colors.grey))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableColors.map((color) {
              final isSelected = _selectedColors.contains(color['Название']);
              final colorValue = _parseColor(color['КодЦвета']);
              return ChoiceChip(
                label: Text(color['Название']),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedColors.add(color['Название']);
                    } else {
                      _selectedColors.remove(color['Название']);
                    }
                  });
                },
                backgroundColor: colorValue.withOpacity(0.2),
                selectedColor: colorValue,
                labelStyle: TextStyle(
                  color: isSelected 
                    ? _getTextColor(colorValue)
                    : Colors.black,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: colorValue,
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildGenderFilter() {
  if (_loadingGender) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: CircularProgressIndicator(),
    );
  }

  if (_availableGender.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Пол', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      Wrap(
        spacing: 8,
        children: _availableGender.map((gender) {
          final name = gender['Название'] as String;
          final selected = _selectedGender.contains(name);
          return FilterChip(
            label: Text(name),
            selected: selected,
            onSelected: (bool value) {
              setState(() {
                if (value) {
                  _selectedGender.add(name);
                } else {
                  _selectedGender.remove(name);
                }
              });
              _handleFilterChange();
            },
          );
        }).toList(),
      ),
    ],
  );
}


  Color _parseColor(String colorCode) {
    try {
      return Color(int.parse(colorCode.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}