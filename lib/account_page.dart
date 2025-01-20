import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountPage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onSuccess;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AccountPage({Key? key, required this.userData, required this.onSuccess}) : super(key: key);

  void _navigateTo(BuildContext context, String routeName) {
    // Пока страницы не готовы, обработчик ничего не делает
    print('Переход на страницу $routeName'); // Для отладки
  }

  Future<void> _logout(BuildContext context) async {
    // Удаление всех сохраненных данных
    await _storage.deleteAll();

    // Переход на страницу входа (или любую другую страницу)
    onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final String firstName = userData['name'] ?? 'Имя';
    final String lastName = userData['surname'] ?? 'Фамилия';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой аккаунт'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхний блок с аватаром, именем и кнопкой настроек
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Аватар
                CircleAvatar(
                  radius: 40,
                  backgroundImage: userData['avatar'] != null && userData['avatar'].isNotEmpty
                      ? NetworkImage(userData['avatar'])
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                  child: userData['avatar'] == null || userData['avatar'].isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),

                const SizedBox(width: 16),

                // Имя и фамилия
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Spacer(),

                // Кнопка выхода
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => _logout(context), // Очистка данных при выходе
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Список опций
            _buildOption(context, 'Заказы', Icons.shopping_bag, '/orders'),
            _buildOption(context, 'Купленные товары', Icons.shopping_cart, '/purchased_items'),
            _buildOption(context, 'Лист ожидания', Icons.bookmark, '/wishlist'),
            _buildOption(context, 'Отзывы', Icons.comment, '/reviews'),
            const Divider(),
            _buildOption(context, 'Промокоды', Icons.card_giftcard, '/promocodes'),
            _buildOption(context, 'Поддержка', Icons.support_agent, '/support'),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, IconData icon, String routeName) {
    return InkWell(
      onTap: () => _navigateTo(context, routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blue),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
