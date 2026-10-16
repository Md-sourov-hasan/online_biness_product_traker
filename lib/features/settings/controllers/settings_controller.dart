import 'package:get/get.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/theme_language_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/utils/constants/colors.dart';

class SettingsController extends GetxController {
  final DatabaseService db = Get.find<DatabaseService>();
  final AuthService auth = Get.find<AuthService>();
  final ThemeLanguageService themeService = Get.find<ThemeLanguageService>();
  final BackupService backupService = Get.find<BackupService>();

  void changeTheme(AppThemeMode mode) {
    themeService.setTheme(mode);
  }

  void changeLanguage(String langCode, String countryCode) {
    themeService.setLanguage(langCode, countryCode);
  }

  void exportBackup() {
    backupService.exportAndShareBackup();
  }

  bool restoreBackup(String jsonStr) {
    return backupService.restoreFromJsonString(jsonStr);
  }

  void approveUser(String userId) {
    db.updateUserApproval(userId, 'approved');
  }

  void rejectUser(String userId) {
    db.updateUserApproval(userId, 'rejected');
  }

  void updateUserRole(String userId, String role) {
    db.updateUserRole(userId, role);
  }
}
