import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import 'db_class.dart';

class EmailConfirmationPage extends StatefulWidget {
  final String emailDomain;
  final String email; // Добавлено для автоматической авторизации
  final String password; // Добавлено для автоматической авторизации
  final VoidCallback onSuccess;

  const EmailConfirmationPage({
    Key? key,
    required this.emailDomain,
    required this.email,
    required this.password,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _EmailConfirmationPageState createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  String? mailServiceName;
  String? mailServiceUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMailServiceData();
  }

  Future<void> _loadMailServiceData() async {
    try {
      final csvData = await rootBundle.loadString('assets/mail_services.csv');
      final List<List<dynamic>> rows =
          const CsvToListConverter().convert(csvData);

      // Ищем запись по домену
      for (var row in rows) {
        final domain = row[0].toString();
        if (domain == widget.emailDomain) {
          setState(() {
            mailServiceName = row[1].toString();
            mailServiceUrl = row[2].toString();
          });
          break;
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных: $e');
    }
  }

  Future<void> _attemptLogin() async {
  setState(() {
    _isLoading = true;
  });

  final result = await DatabaseHelper.loginUser(widget.email, widget.password);

  setState(() {
    _isLoading = false;
  });

  if (result != null && result['emailConfirmation'] == true) {
    // Успешный вход
    widget.onSuccess(); // Вызов метода onSuccess
  } else {
    // Ошибка авторизации
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ошибка подтверждения почты. Попробуйте снова.')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подтверждение почты'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : mailServiceName != null && mailServiceUrl != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 32),
                      const Icon(Icons.mail, size: 100, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Проверьте почту на $mailServiceName для подтверждения.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final Uri mailUrl = Uri.parse(mailServiceUrl!);
                          if (await canLaunchUrl(mailUrl)) {
                            await launchUrl(mailUrl,
                                mode: LaunchMode.externalApplication);
                          } else {
                            print('Не удалось открыть ссылку: $mailServiceUrl');
                          }
                        },
                        icon: const Icon(Icons.open_in_browser),
                        label: Text('Перейти на $mailServiceName'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _attemptLogin,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Подтвердить и войти'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),

                    ],
                  )
                : const Text(
                    'Информация о почтовом сервисе не найдена.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
      ),
    );
  }
}
