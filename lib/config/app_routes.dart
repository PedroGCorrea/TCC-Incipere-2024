import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/LoginAndRegister/login_screen.dart';
import '../screens/LoginAndRegister/register_screen.dart';
import '../screens/LoginAndRegister/forgot_password_screen.dart';
import '../screens/LoginAndRegister/password_reset_screen.dart';
import '../screens/Home/home_screen.dart';
import '../screens/LoginAndRegister/register_screen_2.dart';
import '../screens/LoginAndRegister/register_screen_3.dart';
import '../screens/LoginAndRegister/register_screen_4.dart';
import '../screens/LoginAndRegister/register_screen_5.dart';
import '../screens/Profile/main_profile.dart';
import '../screens/Events/community_events.dart';
import '../screens/Events/subscribed_events.dart';
import '../screens/extra/developer_screen.dart';
import '../screens/Settings/settings_page.dart';
import '../models/Post/new_post.dart';
import '../models/Event/new_event.dart';
import '../screens/Notifications/notifications_page.dart';
import '../screens/Bookmarks/bookmarks_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String register2 = '/register2';
  static const String register3 = '/register3';
  static const String register4 = '/register4';
  static const String welcome = '/welcome';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String resetPassword = '/reset-password';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String communityEvents = '/community-events';
  static const String subscribedEvents = '/subscribed-events';
  static const String developer = '/developer';
  static const String addPost = '/add-post';
  static const String addEvent = '/add-event';
  static const String notifications = '/notifications';
  static const String bookmarks = '/bookmarks';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final user = Supabase.instance.client.auth.currentUser;
    //var log = Logger();
    //log.d('Gerando rota para: ${settings.name}');
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case AppRoutes.register2:
        return MaterialPageRoute(builder: (_) => RegisterScreen2());
      case AppRoutes.register3:
        return MaterialPageRoute(builder: (_) => RegisterScreen3());
      case AppRoutes.register4:
        return MaterialPageRoute(builder: (_) => RegisterScreen4());
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => WelcomePage());
      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => PasswordRecoveryScreen());
      case AppRoutes.resetPassword:
        return MaterialPageRoute(builder: (_) => PasswordResetScreen(email: '', token: '',));
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen (profileUserId: user?.id));
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => SettingsPage());
      case AppRoutes.communityEvents:
        return MaterialPageRoute(builder: (_) => CommunityEvents());
      case AppRoutes.subscribedEvents:
        return MaterialPageRoute(builder: (_) => SubscribedEvents());
      case AppRoutes.developer:
        return MaterialPageRoute(builder: (_) => DeveloperScreen());
      case AppRoutes.addPost:
        return MaterialPageRoute(builder: (_) => NewPostScreen());
      case AppRoutes.addEvent:
        return MaterialPageRoute(builder: (_) => NewEventScreen());
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => NotificationsScreen());
      case AppRoutes.bookmarks:
        return MaterialPageRoute(builder: (_) => BookmarksScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota não encontrada: ${settings.name}')),
          ),
        );
    }
  }
}