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
    theme: ThemeData(
      fontFamily: 'Standart',      
      primaryColor: const Color(0xFF333333),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w500,
          wordSpacing: 10,
        ),
      ),
    ),
    home: AuthPage(onSuccess: onSuccess),
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
        child: Text(
          'Добро пожаловать, ${userData['email']}!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF333333),
            labelStyle: TextStyle( 
              fontSize: 26,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),
            unselectedLabelColor: Color(0xFFC7C7C7),
            indicatorColor: Color(0xFF333333),
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
    bool isPasswordVisible = false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            cursorColor: Color(0xFF333333),
            controller: emailController,
            style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: 'Почта',
              labelStyle: TextStyle(
                fontSize: 21,
                fontFamily: 'Standart',
                fontWeight: FontWeight.w500,
                wordSpacing: 10,
                color: Color(0xFF333333), // Цвет текста, пока он не поднялся
              ),
              floatingLabelStyle: TextStyle( // Цвет текста, когда он наверху
                color: Color(0xFF333333),
                fontSize: 18, // Можно уменьшить, чтобы текст лучше смотрелся
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите email', 
              hintStyle: TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),
            ),
          ),          
                        


          const SizedBox(height: 16.0),
          StatefulBuilder(
            builder: (context, setState) {
              return TextField(
                cursorColor: Color(0xFF333333),
                controller: passwordController,
                obscureText: !isPasswordVisible,
                style: TextStyle( 
                fontSize: 21,
                fontFamily: 'Standart',
                fontWeight: FontWeight.w500,
              ),
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  labelStyle: TextStyle( 
                  fontSize: 21,
                  fontFamily: 'Standart',
                  fontWeight: FontWeight.w500,
                  wordSpacing: 10,
                ),
                 floatingLabelStyle: TextStyle( // Цвет текста, когда он наверху
                color: Color(0xFF333333),
                fontSize: 21, // Можно уменьшить, чтобы текст лучше смотрелся
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите пароль', 
              hintStyle: TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),
                ),
              );
            },
          ),
          const SizedBox(height: 8.0),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Забыл пароль? Поменять пароль.',
              textAlign: TextAlign.center,
              style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 2,
            ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
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
            child: const Text('Войти', style: TextStyle( 
              fontSize: 21,
              color: Colors.white,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),),
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
  bool _isButtonEnabled = false;
  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
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
  void _updateButtonState() {
  setState(() {
    _isButtonEnabled = _surnameController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty;
  });
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
              backgroundColor: Color.fromARGB(255, 227, 225, 225), // Цвет фона, если нет изображения                          
              child: _avatar != null
                  ? ClipOval(
                      child: Image.file(
                        _avatar!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    )
                  : const Icon(Icons.add_a_photo, size: 30, color: Color(0xFF333333)),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _surnameController,
            cursorColor: Color(0xFF333333), 
            style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
            ),           
            decoration: InputDecoration(labelText: 'Фамилия',
              labelStyle: const TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),
            floatingLabelStyle: const TextStyle( 
                color: Color(0xFF333333),
                fontSize: 21, 
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите фамилию', 
              hintStyle: const TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),
              ),
            onChanged: (_) {
    _capitalizeFirstLetter(_surnameController);
    _updateButtonState();
  },
          ),
          const SizedBox(height: 16.0),
          TextField(
            style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Color(0xFF333333),
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Имя',
            labelStyle: const TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),
            floatingLabelStyle: const TextStyle( // Цвет текста, когда он наверху
                color: Color(0xFF333333),
                fontSize: 21, // Можно уменьшить, чтобы текст лучше смотрелся
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите имя', 
              hintStyle: const TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),
            ),
            onChanged: (_) {
    _capitalizeFirstLetter(_nameController);
    _updateButtonState();
  },
          ),
          const SizedBox(height: 16.0),
          TextField(
            style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Color(0xFF333333),
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Почта',
            labelStyle: const TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),
            floatingLabelStyle: const TextStyle( // Цвет текста, когда он наверху
                color: Color(0xFF333333),
                fontSize: 21, // Можно уменьшить, чтобы текст лучше смотрелся
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите почту', 
              hintStyle: const TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),),
            onChanged: (_) {
    _updateButtonState();
  },
          ),
          const SizedBox(height: 16.0),
          TextField(
            style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
            ),
            cursorColor: Color(0xFF333333),
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Пароль',
              labelStyle: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 10,
            ),
            floatingLabelStyle: TextStyle( // Цвет текста, когда он наверху
                color: Color(0xFF333333),
                fontSize: 21, // Можно уменьшить, чтобы текст лучше смотрелся
                fontWeight: FontWeight.w500,
              ),
              hintText: 'Введите пароль', 
              hintStyle: TextStyle(
                fontSize: 21, 
                color: Colors.grey, 
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(      
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(        
                  color: Color(0xFF333333), // Цвет границы при фокусе
                  width: 2.0, 
                ),
              ),
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
            onChanged: (_) {
    _updateButtonState();
  },
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Checkbox(
                checkColor: Colors.white,
                activeColor: const Color(0xFF333333),
                value: _isSubscribed,
                onChanged: (value) {
                  setState(() {
                    _isSubscribed = value ?? false;
                  });
                },
              ),              
              const Text('Рекламная рассылка', style: TextStyle( 
              fontSize: 21,
              fontFamily: 'Standart',
              fontWeight: FontWeight.w500,
              wordSpacing: 2,
            ),),
            ],
          ),
     ElevatedButton(
      onPressed: _isButtonEnabled
          ? () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              final surname = _surnameController.text.trim();
              final name = _nameController.text.trim();

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

                final emailDomain = email.split('@').last;
                DatabaseHelper().sendConfirmationEmail(email: email, firstname: surname, name: name);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmailConfirmationPage(
                      emailDomain: emailDomain,
                      email: email,
                      password: password,
                      onSuccess: widget.onSuccess,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка регистрации')),
                );
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isButtonEnabled ? const Color(0xFF333333) : const Color(0xFFC7C7C7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        'Зарегистрироваться',
        style: TextStyle(
          fontSize: 21,
          color: _isButtonEnabled ? Colors.white : Colors.black,
          fontFamily: 'Standart',
          fontWeight: FontWeight.w500,
          wordSpacing: 10,
        ),
      ),
    )
  
        ],
      ),
    ),
  );
}
}

