import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thêm import này để dùng context.read
import 'package:flutter_ecommerce/controllers/locale_notifier.dart'; // Import LocaleNotifier
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import để lấy tên ngôn ngữ (tùy chọn)


class LanguagesPage extends StatefulWidget {
  const LanguagesPage({super.key});

  @override
  State<LanguagesPage> createState() => _LanguagesPageState();
}

class _LanguagesPageState extends State<LanguagesPage> {
  // String selectedLanguage = 'en'; // Sẽ được quản lý bởi LocaleNotifier

  // Danh sách ngôn ngữ hỗ trợ (key là mã ngôn ngữ, value là tên hiển thị)
  // Bạn có thể lấy tên hiển thị từ AppLocalizations nếu muốn nó cũng được dịch
  final Map<String, String> languages = {
    'en': 'English', // Sẽ được lấy từ AppLocalizations nếu bạn định nghĩa key cho "englishLanguageName"
    'vi': 'Tiếng Việt',
    // Thêm các ngôn ngữ khác khớp với supportedLocales trong MaterialApp
  };

  @override
  void initState() {
    super.initState();
    // Không cần khởi tạo selectedLanguage ở đây nữa,
    // nó sẽ được lấy từ LocaleNotifier
  }

  @override
  Widget build(BuildContext context) {
    // Lấy LocaleNotifier và AppLocalizations (để dịch tiêu đề nếu muốn)
    final localeNotifier = Provider.of<LocaleNotifier>(context);
    final AppLocalizations? localizations = AppLocalizations.of(context);

    // Xác định ngôn ngữ đang được chọn dựa trên LocaleNotifier
    // Nếu appLocale là null (dùng ngôn ngữ hệ thống), bạn có thể cần logic phức tạp hơn
    // để tô sáng đúng RadioButton, hoặc mặc định là ngôn ngữ đầu tiên/tiếng Anh.
    // Cách đơn giản: nếu appLocale là null, giả sử là 'en' hoặc ngôn ngữ hệ thống.
    String currentSelectedLanguageCode = localeNotifier.appLocale?.languageCode ??
                                       WidgetsBinding.instance.platformDispatcher.locale.languageCode; // Lấy ngôn ngữ hệ thống làm fallback


    // Đảm bảo currentSelectedLanguageCode nằm trong danh sách languages.keys
    // Nếu không, có thể chọn một giá trị mặc định (ví dụ: 'en')
    if (!languages.containsKey(currentSelectedLanguageCode)) {
        currentSelectedLanguageCode = 'en'; // Mặc định là tiếng Anh nếu không khớp
    }


    return Scaffold(
      appBar: AppBar(
        // title: const Text("Select Language"), // Sử dụng AppLocalizations nếu có
        title: Text(localizations?.selectLanguageTitle ?? "Select Language"), // Giả sử có key "selectLanguageTitle"
      ),
      body: ListView(
        children: languages.entries.map((entry) {
          final languageCode = entry.key;
          final languageName = entry.value; // Hoặc lấy từ AppLocalizations

          return RadioListTile<String>(
            title: Text(languageName),
            value: languageCode,
            groupValue: currentSelectedLanguageCode, // Sử dụng ngôn ngữ hiện tại từ Notifier
            onChanged: (value) {
              if (value != null) {
                // Không cần setState ở đây nữa vì LocaleNotifier sẽ trigger rebuild MaterialApp
                // setState(() => selectedLanguage = value); // Bỏ dòng này

                // Thay đổi ngôn ngữ ứng dụng thông qua LocaleNotifier
                localeNotifier.changeLocale(Locale(value));

                // (Tùy chọn) Hiển thị SnackBar
                // Bạn có thể muốn dịch cả thông báo này
                String changedToLanguageName = languages[value] ?? value;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language changed to $changedToLanguageName')),
                );

                // (Tùy chọn) Tự động pop trang sau khi chọn
                // Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

// Để sử dụng "selectLanguageTitle" từ AppLocalizations, bạn cần thêm nó vào các file .arb:
// Ví dụ trong app_en.arb:
// "selectLanguageTitle": "Select Language",
// Ví dụ trong app_vi.arb:
// "selectLanguageTitle": "Chọn ngôn ngữ",