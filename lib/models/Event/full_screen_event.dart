import 'package:flutter/material.dart';
import 'package:incipere/models/Event/edit_event.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  EventDetailScreen({required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<String?> _usernameFuture;
  late Future<bool> _isUserSubscribedFuture;
  bool showFabOptions = false;

  @override
  void initState() {
    super.initState();
    _usernameFuture = _fetchUsername(widget.event['user_id']);
    _isUserSubscribedFuture = _checkIfUserIsSubscribed();
  }

  Future<void> _confirmDeleteEvent() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Confirmar Exclusão'),
              content: Text('Tem certeza de que deseja excluir este evento?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Excluir'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldDelete) {
      try {
        await Supabase.instance.client
            .from('events')
            .delete()
            .eq('event_id', widget.event['event_id']);
        Navigator.pop(context); // Voltar à tela anterior após exclusão
      } catch (error) {
        debugPrint('Erro ao excluir evento: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir evento. Tente novamente.')),
        );
      }
    }
  }

  Future<String?> _fetchUsername(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('username')
          .eq('user_id', userId)
          .single();
      return response['username'] as String?;
    } catch (error) {
      debugPrint('Erro ao buscar username: $error');
      return null;
    }
  }

  Future<bool> _checkIfUserIsSubscribed() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await Supabase.instance.client
          .from('events_subs')
          .select()
          .eq('event_id', widget.event['event_id'])
          .eq('user_id', userId)
          .single();
      return response != null;
    } catch (error) {
      return false; // Não está inscrito
    }
  }

  Future<void> _subscribeToEvent() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await Supabase.instance.client.from('events_subs').insert({
        'event_id': widget.event['event_id'],
        'user_id': userId,
      });
      Logger().i(response);
      setState(() {
        _isUserSubscribedFuture = Future.value(true);
      });
    } catch (error) {
      debugPrint('Erro ao se inscrever no evento: $error');
    }
  }

  Future<void> _unsubscribeFromEvent() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('events_subs')
          .delete()
          .eq('event_id', widget.event['event_id'])
          .eq('user_id', userId);
      setState(() {
        _isUserSubscribedFuture = Future.value(false);
      });
    } catch (error) {
      debugPrint('Erro ao cancelar inscrição: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.event['image_path'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.event['title'],
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              FutureBuilder<String?>(
                future: _usernameFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Carregando autor...');
                  } else if (snapshot.hasError || snapshot.data == null) {
                    return const Text('Autor desconhecido');
                  } else {
                    return Text(
                      'Postado por: ${snapshot.data!}',
                      style: Theme.of(context).textTheme.titleMedium,
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Adicionado em: ${_formatDate(widget.event['created_at'])}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Data do Evento: ${_formatDate(widget.event['event_date'])}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Localização: ${widget.event['location'] ?? "Não especificada"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                widget.event['description'] ?? 'Sem descrição disponível.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: _isUserSubscribedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return const Text('Erro ao verificar inscrição.');
                  } else {
                    final isSubscribed = snapshot.data ?? false;
                    return ElevatedButton(
                      onPressed: () {
                        if (isSubscribed) {
                          _unsubscribeFromEvent();
                        } else {
                          _subscribeToEvent();
                        }
                      },
                      child: Text(isSubscribed
                          ? 'Cancelar Inscrição'
                          : 'Inscrever-se'),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.event['user_id'] == Supabase.instance.client.auth.currentUser?.id
    ? Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showFabOptions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                heroTag: 'deleteEvent',
                onPressed: _confirmDeleteEvent,
                backgroundColor: Colors.red,
                child: const Icon(Icons.delete),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                heroTag: 'editEvent',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditEventScreen(event: widget.event),
                    ),
                  ).then((value) {
                    if (value == true) {
                      // Recarregar os dados caso o evento tenha sido editado
                      setState(() {});
                    }
                  });
                },
                backgroundColor: Colors.blue,
                child: const Icon(Icons.edit),
              ),
            ),
          ],
          FloatingActionButton(
            heroTag: 'mainFab',
            onPressed: () {
              setState(() {
                showFabOptions = !showFabOptions;
              });
            },
            child: Icon(showFabOptions ? Icons.close : Icons.more_vert),
          ),
        ],
      )
    : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date).toLocal();
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year} às ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
  }
}
