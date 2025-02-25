import 'package:flutter/material.dart';
import 'db_class.dart';
import 'ProductSearchPage.dart';

final dbHelper = DatabaseHelper();
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String? selectedGender = 'Мужчинам';
  Future<List<Map<String, dynamic>>>? categoriesFuture;

  @override
  void initState() {
    super.initState();
    categoriesFuture = dbHelper.fetchCategories(selectedGender == 'Мужчинам'
        ? 'categories?gendrCode=1'
        : 'categories?gendrCode=2');
  }

  void _updateCategories(String gender) {
    setState(() {
      selectedGender = gender;
      categoriesFuture = dbHelper.fetchCategories(gender == 'Мужчинам'
          ? 'categories?gendrCode=1'
          : 'categories?gendrCode=2');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
  decoration: InputDecoration(
    hintText: "Поиск...",
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    prefixIcon: Icon(Icons.search),
  ),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage( gendrCode: selectedGender  == 'Мужчинам' ? 1 : 2),
      ),
    );
  },
  onChanged: (query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryProductsPage( gendrCode: selectedGender  == 'Мужчинам' ? 1 : 2, searchQuery: query),
      ),
    );
  },
),

            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateCategories('Мужчинам'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGender  == 'Мужчинам'
                          ? const Color(0xFF333333)
                          : const Color(0xFFC7C7C7),
                      foregroundColor: selectedGender  == 'Мужчинам'
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
            SizedBox(height: 10),
            Text("Категории", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProductsPage(
                                  gendrCode: selectedGender  == 'Мужчинам' ? 1 : 2,
                                  categoryId: item['ID'], // Передаем ID категории
                                ),
                              ),
                            );
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
            ),
          ],
        ),
      ),
    );
  }

 
}
