import 'package:flutter/material.dart';
import 'package:incipere/models/Post/full_screen_post.dart';
import 'package:incipere/screens/Profile/main_profile.dart';
import 'package:incipere/screens/Settings/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<Map<String, dynamic>>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Erro ao buscar notificações: $error');
      return [];
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('notification_id', notificationId);
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    } catch (error) {
      debugPrint('Erro ao marcar como lida: $error');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    } catch (error) {
      debugPrint('Erro ao deletar notificação: $error');
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId);
      setState(() {
        _notificationsFuture = _fetchNotifications();
      });
    } catch (error) {
      debugPrint('Erro ao marcar todas como lidas: $error');
    }
  }

  void _handleNotificationAction(Map<String, dynamic> notification) {
    final actionType = notification['action_type'];
    final actionData = notification['action_data'] != null
        ? jsonDecode(notification['action_data'])
        : {};

    switch (actionType) {
      case 'open_profile':
        if (actionData.containsKey('user_id')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(profileUserId: actionData['user_id']),
            ),
          );
        }
        break;

      case 'open_settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;

        /*case 'open_chat':
          if (actionData.containsKey('chat_id')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatId: actionData['chat_id']),
              ),
            );
          }
          break;*/

        case 'open_post':
          if (actionData.containsKey('post_id')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostFullscreen(postId: actionData['post_id']),
              ),
            );
          }
          break;

      default:
        debugPrint('Ação desconhecida ou não definida: $actionType');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sem notificações disponíveis.'));
          } else {
            final notifications = snapshot.data!;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['read'] ?? false;
                final backgroundColor =
                    isRead ? Colors.grey[800] : Colors.white;

                return Card(
                  color: backgroundColor,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      size: 32,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      notification['message'],
                      style: TextStyle(
                        color: isRead ? Colors.grey : Colors.black,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Recebido em: ${_formatDateTime(notification['created_at'])}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.done),
                          onPressed: () {
                            if (!isRead) {
                              _markAsRead(notification['notification_id']);
                            }
                          },
                          tooltip: 'Marcar como lida',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _deleteNotification(notification['notification_id']);
                          },
                          tooltip: 'Excluir notificação',
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notification['notification_id']);
                      }
                      _handleNotificationAction(notification);
                    },
                  )
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _markAllAsRead,
        label: const Text('Ler tudo'),
        icon: const Icon(Icons.done_all),
        tooltip: 'Marcar todas como lidas',
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    final parsedDate = DateTime.parse(dateTime).toLocal();
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} às ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}";
  }
}
