import 'dart:io';
import 'EmailConfirmationPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_class.dart'; // Импорт вашего DatabaseHelper
import 'package:bcrypt/bcrypt.dart';
import 'MobileNavigationBar.dart';


class Authorization extends StatelessWidget {
  final VoidCallback onSuccess;

  const Authorization({Key? key, required this.onSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Авторизация и Регистрация',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthPage(onSuccess: onSuccess), // Передаем onSuccess
      routes: {
        '/home': (context) {
          final arguments = ModalRoute.of(context)!.settings.arguments as Map;
          return HomePage(userData: arguments);
        },
      },
    );
  }
}


class HomePage extends StatelessWidget {
  final Map userData;

  const HomePage({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Center(
        child: Text('Добро пожаловать, ${userData['email']}!'),
      ),
    );
  }
}



class AuthPage extends StatelessWidget {
  final VoidCallback onSuccess;

  const AuthPage({Key? key, required this.onSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Авторизация и Регистрация'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Авторизация'),
              Tab(text: 'Регистрация'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LoginTab(onSuccess: onSuccess),
            RegistrationTab(onSuccess: onSuccess),
          ],
        ),
      ),
    );
  }
}

class LoginTab extends StatelessWidget {
  final VoidCallback onSuccess;

  const LoginTab({Key? key, required this.onSuccess}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Почта',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Пароль',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final password = passwordController.text.trim();

              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пожалуйста, заполните все поля')),
                );
                return;
              }

              // Проверка email
              final emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
              if (!emailRegex.hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректный email')),
                );
                return;
              }

              try {
                final userData = await DatabaseHelper.loginUser(email, password);
                print(userData);
                if (userData != null) {
                  if (userData['emailConfirmation'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Успешный вход')),
                    );
                    onSuccess(); // Переход на главный экран
                  } else if (userData['emailConfirmation'] == false) {
                    final emailDomain = userData['email']?.split('@').last ?? '';
                    if (emailDomain.isNotEmpty) {
                      DatabaseHelper().sendConfirmationEmail(email : userData['email'], firstname : userData['surname'], name : userData['name'] );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailConfirmationPage(emailDomain: emailDomain, email:  userData['email'], password: password, onSuccess: onSuccess),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ошибка: Некорректный email')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ошибка: Статус подтверждения почты неизвестен')),
                    );
                  }

                  
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Неверный email или пароль')),
                  );
                }
              } catch (error) {
                debugPrint('Ошибка при входе: $error');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $error')),
                );
              }
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}

class RegistrationTab extends StatefulWidget {
  final VoidCallback onSuccess;

  const RegistrationTab({Key? key, required this.onSuccess}) : super(key: key);
  @override
  State<RegistrationTab> createState() => _RegistrationTabState();
}

class _RegistrationTabState extends State<RegistrationTab> {
  File? _avatar;
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSubscribed = true;

  Future<void> _pickAvatar() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatar = File(pickedFile.path);
      });
    }
  }

  void _capitalizeFirstLetter(TextEditingController controller) {
    if (controller.text.isNotEmpty) {
      String text = controller.text;
      controller.value = TextEditingValue(
        text: text[0].toUpperCase() + text.substring(1),
        selection: controller.selection,
      );
    }
  }
  bool EmailValidator(String email) {
    // Регулярное выражение для проверки корректного email
    final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
  return RegExp(r'^(?=.*[0-9])(?=.*[a-zA-Z]).{6,}$').hasMatch(password);
}

 @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200], // Цвет фона, если нет изображения
              child: _avatar != null
                  ? ClipOval(
                      child: Image.file(
                        _avatar!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    )
                  : const Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _surnameController,
            decoration: const InputDecoration(labelText: 'Фамилия'),
            onChanged: (_) => _capitalizeFirstLetter(_surnameController),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Имя'),
            onChanged: (_) => _capitalizeFirstLetter(_nameController),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Почта'),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Пароль',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Checkbox(
                value: _isSubscribed,
                onChanged: (value) {
                  setState(() {
                    _isSubscribed = value ?? false;
                  });
                },
              ),
              const Text('Рекламная рассылка'),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              final surname = _surnameController.text.trim();
              final name = _nameController.text.trim();

              if (email.isEmpty || password.isEmpty || surname.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Заполните все обязательные поля')),
                );
                return;
              }

              if (!EmailValidator(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите корректный адрес электронной почты')),
                );
                return;
              }

              if (!_isPasswordValid(password)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пароль должен содержать не менее 6 символов, латинские буквы и хотя бы одну цифру')),
                );
                return;
              }

              final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

              String? avatarPath;
              if (_avatar != null) {
                avatarPath = _avatar!.path;
              }

              final success = await DatabaseHelper().registerUser(
                email: email,
                password: hashedPassword,
                name: name,
                firstname: surname,
                patranomic: '',
                avatarPath: avatarPath,
                isSubscribed: _isSubscribed,
                isCorectEmail: false,
                role: 1,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Регистрация прошла успешно')),
                );

                // Получение домена из адреса электронной почты
                final emailDomain = email.split('@').last;
                DatabaseHelper().sendConfirmationEmail(email: email, firstname: surname, name: name);
                // Переход на страницу EmailConfirmationPage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmailConfirmationPage(emailDomain: emailDomain, email: email, password: password, onSuccess: widget.onSuccess),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка регистрации')),
                );
              }
            },
            child: const Text('Зарегистрироваться'),
          )
        ],
      ),
    ),
  );
}
}

