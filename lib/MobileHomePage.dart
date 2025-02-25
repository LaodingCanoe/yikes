import 'package:flutter/material.dart';
import 'ProductCart.dart';
import 'db_class.dart';

final dbHelper = DatabaseHelper();
void main() {
  runApp(const MobileHomePage());
}

class MobileHomePage extends StatelessWidget {
  const MobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'Мужчинам';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Keynes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BlackOpsOne',
            fontSize: 30.0,             
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<String>>(
              future: dbHelper.fetchImages(
                selectedCategory == 'Мужчинам'
                    ? 'addImages?gendrCode=1'
                    : 'addImages?gendrCode=2',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No images available'));
                } else {
                  return SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          snapshot.data![index],
                          fit: BoxFit.scaleDown ,
                        );
                      },
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'Мужчинам';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == 'Мужчинам'
                          ? const Color(0xFF333333)
                          : const Color(0xFFC7C7C7),
                      foregroundColor: selectedCategory == 'Мужчинам'
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
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'Женщинам';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedCategory == 'Женщинам'
                          ? const Color(0xFF333333)
                          : const Color(0xFFC7C7C7),
                      foregroundColor: selectedCategory == 'Женщинам'
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
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: dbHelper.fetchCategories(
                selectedCategory == 'Мужчинам'
                    ? 'categories?gendrCode=1'
                    : 'categories?gendrCode=2',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No categories available'));
                } else {
                  return SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: PageView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return Stack(
                          children: [
                            Image.network(
                              item['ПутьФото'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Container(
                              alignment: Alignment.center,
                              color: Colors.black.withOpacity(0.5),
                              child: Text(
                                item['Название'].toUpperCase(),
                                textAlign: TextAlign.center,  
                                style: const TextStyle(                                                                
                                  color: Colors.white,
                                  fontFamily: 'BlackOpsOne',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              '  Новинки',
              style: TextStyle(
                fontFamily: 'Standart',
                fontSize: 36,
                fontWeight: FontWeight.w500,
                wordSpacing: 10,
              ),
            ),
            SizedBox(
              height: 426,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ProductCart(
                    key: ValueKey(selectedCategory),
                    gendrCode: selectedCategory == 'Мужчинам' ? 1 : 2,
                    maxItems: 10,
                    layoutType: LayoutType.horizontal,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              '  Бесцелеры',
              style: TextStyle(
                fontFamily: 'Standart',
                fontSize: 36,
                fontWeight: FontWeight.w500,
                wordSpacing: 10,
              ),
            ),
            SizedBox(
              height: 426,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ProductCart(
                    key: ValueKey(selectedCategory),
                    gendrCode: selectedCategory == 'Мужчинам' ? 1 : 2,
                    maxItems: 10,  hashtag: 'Бестселлер',
                    layoutType: LayoutType.horizontal,
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
SizedBox(
  
  child: LayoutBuilder(
    builder: (context, constraints) {
      return ProductCart(
        key: ValueKey(selectedCategory),
        gendrCode: selectedCategory == 'Мужчинам' ? 1 : 2,
        layoutType: LayoutType.grid,
        shuffle: true,
      );
    },
  ),
),


          ],
        ),
      ),
    );
  }
}
