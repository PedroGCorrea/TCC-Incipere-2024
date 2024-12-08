import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data'; // Para manipular arquivos
import 'dart:io' as io; // Apenas para dispositivos móveis
import 'package:flutter/foundation.dart' show kIsWeb;

class EditEventScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  EditEventScreen({required this.event});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _eventDate;
  DateTime? _updatedDate;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImage;
  io.File? _selectedImage;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.event['title'] ?? '';
    _descriptionController.text = widget.event['description'] ?? '';
    _locationController.text = widget.event['location'] ?? '';
    _eventDate = DateTime.parse(widget.event['event_date']);
    _updatedDate = _eventDate;
  }

  Future<void> _saveChanges() async {
    try {
      // Atualizar informações no banco
      final updates = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'event_date': _updatedDate?.toIso8601String(),
      };

      if (_selectedImage != null || _webImage != null) {
        updates['image_path'] = await _uploadImage();
      }

      await Supabase.instance.client
          .from('events')
          .update(updates)
          .eq('event_id', widget.event['event_id']);

      Navigator.pop(context, true); // Retorna true para recarregar os dados
    } catch (error) {
      debugPrint('Erro ao editar evento: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar alterações. Tente novamente.')),
      );
    }
  }

  Future<String> _uploadImage() async {
    String? coverImagePath;
    final currentUser = supabase.auth.currentUser;
    try {
      if (_webImage != null || _selectedImage != null) {
        final imageName = '${currentUser?.id}_${DateTime.now().millisecondsSinceEpoch}.png';
        final fileBytes = _webImage ?? await _selectedImage!.readAsBytes();

        try {
          await supabase.storage.from('eventimages').uploadBinary(
            imageName,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

          coverImagePath = supabase.storage.from('eventimages').getPublicUrl(imageName);
        } catch (e) {
          throw Exception('Erro no upload da imagem de capa: $e');
        }
      }
    } catch (e) {
      print('Erro ao postar comentário: $e');
    }
    return coverImagePath!;
  }

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

  Future<void> _pickDateTime(BuildContext context) async {
    // Selecionar data
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _updatedDate ?? DateTime.now(), // Data inicial como a atual ou a selecionada anteriormente
      firstDate: DateTime(2000), // Limite mínimo
      lastDate: DateTime(2100), // Limite máximo
    );

    if (selectedDate == null) return; // Caso o usuário cancele

    // Selecionar horário
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _updatedDate != null
          ? TimeOfDay.fromDateTime(_updatedDate!) // Horário inicial caso já exista uma data
          : TimeOfDay.now(), // Horário atual como padrão
    );

    if (selectedTime == null) return; // Caso o usuário cancele

    // Combinar data e hora
    setState(() {
      _updatedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Evento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Campo para o título
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 16),

              // Campo para a descrição
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Descrição'),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              // Campo para a localização
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Localização'),
              ),
              const SizedBox(height: 16),

              // Seleção de data
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data e Hora',
                  labelStyle: TextStyle(
                    color: Colors.blue, // Cor do rótulo
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                child: GestureDetector(
                  onTap: () => _pickDateTime(context),
                  child: Text(
                    _updatedDate != null
                        ? '${_updatedDate!.day}/${_updatedDate!.month}/${_updatedDate!.year} às ${_updatedDate!.hour.toString().padLeft(2, '0')}:${_updatedDate!.minute.toString().padLeft(2, '0')}'
                        : 'Selecione a data e horário do evento',
                    style: TextStyle(
                      fontSize: 16,
                      color: _updatedDate != null ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Visualizar ou selecionar imagem
              GestureDetector(
                onTap: _pickImage, // Função para escolher a imagem
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _webImage != null
                      ? Image.memory(
                          _webImage!,
                          fit: BoxFit.cover,
                        )
                      : _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : (widget.event['image_path'] != null && widget.event['image_path'].isNotEmpty)
                              ? Image.network(
                                  widget.event['image_path'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(child: Icon(Icons.broken_image));
                                  },
                                )
                              : const Center(child: Icon(Icons.image)), // Placeholder se nenhuma imagem estiver disponível
                ),
              ),
              const SizedBox(height: 16),

              // Botão para salvar alterações
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text('Salvar Alterações'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
