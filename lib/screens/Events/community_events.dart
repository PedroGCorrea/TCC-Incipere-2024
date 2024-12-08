import 'package:flutter/material.dart';
import 'package:incipere/models/Event/full_screen_event.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityEvents extends StatefulWidget {
  @override
  _CommunityEventsState createState() => _CommunityEventsState();
}

class _CommunityEventsState extends State<CommunityEvents> {
  late Future<List<Map<String, dynamic>>> _futureEvents;
  final PageController _pageController = PageController(viewportFraction: 0.6);

  @override
  void initState() {
    super.initState();
    _futureEvents = _fetchEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchEvents() async {
    SupabaseClient supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('events')
          .select()
          .order('event_date', ascending: true);
      final List<Map<String, dynamic>> events =
          List<Map<String, dynamic>>.from(response);
      return events;
    } catch (error) {
      debugPrint('Erro ao carregar eventos: $error');
      return [];
    }
  }

  void _navigateToPreviousEvent() {
    if (_pageController.hasClients) {
      final currentPage = _pageController.page ?? 0;
      _pageController.animateToPage(
        (currentPage - 1).toInt(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _navigateToNextEvent() {
    if (_pageController.hasClients) {
      final currentPage = _pageController.page ?? 0;
      _pageController.animateToPage(
        (currentPage + 1).toInt(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEvents,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum evento disponível no momento.'));
          }

          final events = snapshot.data!;
          return _buildEventsCarousel(context, events);
        },
      ),
    );
  }

  Widget _buildEventsCarousel(BuildContext context, List<Map<String, dynamic>> events) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 32),
                onPressed: _navigateToPreviousEvent,
              ),
              Expanded(
                child: PageView.builder(
                  itemCount: events.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(context, event);
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 32),
                onPressed: _navigateToNextEvent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  event['image_path'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
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
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(event['event_date']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.info_outline),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
  }
}
