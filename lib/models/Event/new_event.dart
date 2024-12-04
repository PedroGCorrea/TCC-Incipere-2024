import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:incipere/widgets/main_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({Key? key}) : super(key: key);

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Uint8List? _webImage;
  io.File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          // Para web, usamos bytes diretamente
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null; // Certifique-se de limpar a imagem nativa
          });
        } else {
          // Para dispositivos móveis, usamos o caminho do arquivo
          setState(() {
            _selectedImage = io.File(pickedFile.path);
            _webImage = null; // Certifique-se de limpar a imagem da web
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_titleController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _webImage == null && _selectedImage == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabaseClient = Supabase.instance.client;
    final currentUser = supabaseClient.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    try {
      // Upload da imagem
      final imageName = '${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final fileBytes = _webImage ?? await _selectedImage!.readAsBytes();

      await supabaseClient.storage.from('eventimages').uploadBinary(
        imageName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final imagePath = supabaseClient.storage.from('eventimages').getPublicUrl(imageName);

      // Combinar data e hora do evento
      final eventDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Inserção do evento
      await supabaseClient.from('events').insert({
        'user_id': currentUser.id,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'image_path': imagePath,
        'location': _locationController.text,
        'event_date': eventDate.toUtc().toIso8601String(),
      });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evento criado com sucesso!')),
    );
    Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar o evento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _webImage != null
                            ? MemoryImage(_webImage!)
                            : _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : null,
                        child: _webImage == null && _selectedImage == null
                            ? Icon(Icons.add_a_photo, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: 'Localização'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Descrição'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _selectDate,
                      child: Text(
                        _selectedDate == null
                            ? 'Selecione a Data'
                            : 'Data: ${_selectedDate!.toLocal()}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _selectTime,
                      child: Text(
                        _selectedTime == null
                            ? 'Selecione o Horário'
                            : 'Horário: ${_selectedTime!.format(context)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      child: Text('Salvar Evento'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
