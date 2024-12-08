import 'package:flutter/material.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:incipere/models/Event/full_screen_event.dart';

class SubscribedEvents extends StatefulWidget {
  @override
  _SubscribedEventsState createState() => _SubscribedEventsState();
}

class _SubscribedEventsState extends State<SubscribedEvents> {
  late Future<List<Map<String, dynamic>>> _subscribedEventsFuture;

  @override
  void initState() {
    super.initState();
    _subscribedEventsFuture = _fetchSubscribedEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchSubscribedEvents() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Obter eventos inscritos do usuário atual
      final response = await Supabase.instance.client
          .from('events_subs')
          .select('event_id, events(*)') // Assumindo uma relação com a tabela `events`
          .eq('user_id', userId);

      if (response.isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response.map((entry) => entry['events']));
    } catch (error) {
      debugPrint('Erro ao buscar eventos inscritos: $error');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _subscribedEventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Você não está inscrito em nenhum evento.'),
            );
          } else {
            final events = snapshot.data!;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        event['image_path'],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    title: Text(event['title']),
                    subtitle: Text(
                      'Data do evento: ${_formatDate(event['event_date'])}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(event: event),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }
}
