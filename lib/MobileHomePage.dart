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
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Определяем отступы в зависимости от ширины экрана
          final horizontalPadding = constraints.maxWidth > 600 ? 80.0 : 0.0;
          
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                        return AspectRatio(
                          aspectRatio: 16 / 9,
                          child: PageView.builder(
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                snapshot.data![index],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? 0 : 16),
                    child: Row(
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
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? 0 : 16),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: dbHelper.fetchCategories(
                        gender:  [selectedCategory == 'Мужчинам'
                            ? 'Мужской'
                            : 'Женский',],
                            isAdd: true,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('No categories available'));
                        } else {
                          return AspectRatio(
                          aspectRatio: 3 / 2,
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
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? 0 : 16),
                    child: const Text(
                      'Новинки',
                      style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ProductCart(
                          key: ValueKey(selectedCategory),
                          gender: selectedCategory == 'Мужчинам' ? ['Мужской'] :  ['Женский'],
                          maxItems: 10,
                          layoutType: LayoutType.horizontal,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? 0 : 16),
                    child: const Text(
                      'Бестселлеры',
                      style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 10,
                      ),
                    ),
                  ),                
                  ProductCart(
                          key: ValueKey(selectedCategory),
                          gender: selectedCategory == 'Мужчинам' ? ['Мужской'] :  ['Женский'],
                          maxItems: 10,
                          tags: ['Бестселлер'],
                          layoutType: LayoutType.horizontal,
                        ),
                  

                  const SizedBox(height: 20),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding > 0 ? 0 : 16),
                    child: SizedBox(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ProductCart(
                            key: ValueKey(selectedCategory),
                            gender: selectedCategory == 'Мужчинам' ? ['Мужской'] :  ['Женский'],
                            layoutType: LayoutType.grid,
                            shuffle: true,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}