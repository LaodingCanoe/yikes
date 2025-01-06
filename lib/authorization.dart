import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'db_class.dart'; // Импорт вашего DatabaseHelper

void main() {
  runApp(const Authorization());
}

class Authorization extends StatelessWidget {
  const Authorization({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Авторизация и Регистрация',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatelessWidget {
  const AuthPage({Key? key}) : super(key: key);

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
        body: const TabBarView(
          children: [
            LoginTab(),
            RegistrationTab(),
          ],
        ),
      ),
    );
  }
}

class LoginTab extends StatelessWidget {
  const LoginTab({Key? key}) : super(key: key);

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
              final email = emailController.text;
              final password = passwordController.text;

              final success = await DatabaseHelper().loginUser(email, password);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Успешный вход')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка авторизации')),
                );
              }
            },
            child: const Text('Войти'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text;
              if (email.isNotEmpty) {
                final success = await DatabaseHelper().resetPassword(email);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Проверьте вашу почту')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка сброса пароля')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите почту')),
                );
              }
            },
            child: const Text('Забыли пароль?'),
          ),
        ],
      ),
    );
  }
}

class RegistrationTab extends StatefulWidget {
  const RegistrationTab({Key? key}) : super(key: key);

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
                backgroundImage: _avatar != null
                    ? FileImage(_avatar!)
                    : const AssetImage('assets/default_avatar.png') as ImageProvider,
                child: _avatar == null
                    ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                    : null,
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
            ElevatedButton(
              onPressed: () async {
                final email = _emailController.text;
                final password = _passwordController.text;
                final username = '${_surnameController.text} ${_nameController.text}';

                final success =
                    await DatabaseHelper().registerUser(email, password, username);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Регистрация прошла успешно')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ошибка регистрации')),
                  );
                }
              },
              child: const Text('Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
