import 'package:google_mlkit_translation/google_mlkit_translation.dart';

void main() {
  for (var lang in TranslateLanguage.values) {
    print(lang.name);
  }
}
