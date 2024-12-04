import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' as io; // Apenas para dispositivos móveis
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditCreativeProcessModal extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> images;
  final Map<String, TextEditingController> controllers;

  const EditCreativeProcessModal({super.key, 
    required this.data,
    required this.images,
    required this.controllers
  });

  @override
  _EditCreativeProcessModalState createState() => _EditCreativeProcessModalState();
}

class _EditCreativeProcessModalState extends State<EditCreativeProcessModal> {
  final List<String> options = ["Texto", "Imagem", "Citação", "Legenda", "Link"];
  String? selectedOption;
  final supabaseClient = Supabase.instance.client;
  late final User? currentUser;
  String userId = '';
  var log = Logger();

  final Uuid uuid = Uuid();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    currentUser = supabaseClient.auth.currentUser;
    userId = currentUser!.id;
  }

  void _removeElement(int index) {
    setState(() {
      widget.data["elements"].removeAt(index);
    });
  }

  void _moveElement(int oldIndex, int newIndex) {
    setState(() {
      final element = widget.data["elements"].removeAt(oldIndex);
      widget.data["elements"].insert(newIndex, element);
    });
  }
  TextEditingController _getController(String id, String field) {
    final key = "$id-$field"; // Use o id para criar a chave única

    if (!widget.controllers.containsKey(key)) {
      // Busca o elemento correspondente pelo ID
      final element = widget.data["elements"]
          .firstWhere((element) => element["id"] == id, orElse: () => null);

      // Verifica se o campo content existe e não está vazio
      final initialValue = (element != null && element["content"] != null && element["content"].toString().isNotEmpty)
          ? element["content"].toString() // Usa o conteúdo como texto inicial
          : ""; // Caso contrário, inicializa com string vazia

      // Cria o TextEditingController com o valor inicial apropriado
      widget.controllers[key] = TextEditingController(text: initialValue);
    }

    return widget.controllers[key]!;
  }

  void _addElement(String type, {Map<String, dynamic>? initialData}) {
    final element = {
      "id": uuid.v4(),
      "type": type,
      ...?initialData, // Mescla propriedades adicionais, se fornecidas
    };

    // Propriedades padrão para tipos conhecidos
    if (type == "text") {
      element.addAll({
        "content": initialData?["content"] ?? "",
        "align": initialData?["align"] ?? "left",
        "format": initialData?["format"] ?? "normal",
        "color": initialData?["color"] ?? "#000000",
      });
    } else if (type == "image") {
      element.addAll({"content": initialData?["content"] ?? ""});
    } else if (type == "quote") {
      element.addAll({"content": initialData?["content"] ?? ""});
    } else if (type == "caption") {
      element.addAll({"content": initialData?["content"] ?? ""});
    } else if (type == "link") {
      element.addAll({
        "title": initialData?["title"] ?? "",
        "content": initialData?["content"] ?? "",
      });
    }

    setState(() {
      widget.data["elements"].add(element);
    });
  }


  void _showRawJSON() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              JsonEncoder.withIndent("  ").convert(widget.data),
              style: TextStyle(fontSize: 14, fontFamily: 'Courier'),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleAlignment(int index) {
    final currentAlign = widget.data["elements"][index]["align"];
    final newAlign = currentAlign == "left"
        ? "center"
        : currentAlign == "center"
            ? "right"
            : "left";
    setState(() {
      widget.data["elements"][index]["align"] = newAlign;
    });
  }

  void _toggleFormat(int index) {
    final currentFormat = widget.data["elements"][index]["format"];
    final newFormat = currentFormat == "normal"
        ? "italic"
        : currentFormat == "italic"
            ? "bold"
            : "normal";

    setState(() {
      widget.data["elements"][index]["format"] = newFormat;
    });
  }

  void _changeColor(int index) {
    showDialog(
      context: context,
      builder: (context) {
        Color currentColor = Color(int.parse(widget.data["elements"][index]["color"].substring(1, 7), radix: 16) + 0xFF000000);
        return AlertDialog(
          title: Text("Escolha uma cor"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: currentColor,
              onColorChanged: (color) {
                setState(() {
                  widget.data["elements"][index]["color"] = '#${color.value.toRadixString(16).substring(2)}';
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text("Fechar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(int index) async {
    Uint8List? _webImage;
    io.File? _selectedImage;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        String uniqueName = "post-$userId-$index-${uuid.v4()}";
        setState(() {
          widget.data["elements"][index]["content"] = uniqueName;
        });

        if (kIsWeb) {
          
          // Para web, usamos bytes diretamente
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null; // Certifique-se de limpar a imagem nativa
            widget.images.add({"name": uniqueName, "content": _webImage});
          });
        } else {
          // Para dispositivos móveis, usamos o caminho do arquivo
          setState(() {
            _selectedImage = io.File(pickedFile.path);
            _webImage = null; // Certifique-se de limpar a imagem da web
            widget.images.add({"name": uniqueName, "content": _selectedImage});
          });
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }

  Widget _buildImageElement(Map<String, dynamic> element, int index) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: () => _pickImage(index),
            child: Text("Selecionar Imagem"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: element["content"] != null
              ? _buildImageContent(element)
              : Icon(
                  Icons.image_not_supported_outlined,
                  size: 80,
                  color: Colors.grey,
                ),
        ),
      ],
    );
  }

  Widget _buildImageContent(Map<String, dynamic> element) {
    final content = element["content"];

    // Verifica se o content é uma URL
    if (content is String && Uri.tryParse(content)?.hasAbsolutePath == true) {
      return Image.network(
        content,
        height: 80,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image_outlined,
            size: 80,
            color: Colors.grey,
          );
        },
      );
    }

    // Caso o content seja uma referência válida no widget.images
    if (widget.images.any((img) => img["name"] == content)) {
      return Image.memory(
        widget.images.firstWhere(
          (img) => img["name"] == content,
          orElse: () => {"content": Uint8List(0)},
        )["content"],
        height: 80,
        fit: BoxFit.cover,
      );
    }

    // Caso o content não seja uma URL nem uma imagem válida, exibe o ícone padrão
    return Icon(
      Icons.image_not_supported_outlined,
      size: 80,
      color: Colors.grey,
    );
  }

  Widget _buildElementWidget(Map<String, dynamic> element, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Coluna com os botões (Excluir, Mover para Cima, Mover para Baixo)
        Column(
          children: [
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () {
                _removeElement(index);
              },
              tooltip: "Excluir",
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward, color: Colors.blue),
              onPressed: index > 0
                  ? () {
                      _moveElement(index, index - 1);
                    }
                  : null, // Desabilitado se já for o primeiro elemento
              tooltip: "Mover para Cima",
            ),
            IconButton(
              icon: Icon(Icons.arrow_downward, color: Colors.blue),
              onPressed: index < widget.data["elements"].length - 1
                  ? () {
                      _moveElement(index, index + 1);
                    }
                  : null, // Desabilitado se já for o último elemento
              tooltip: "Mover para Baixo",
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Widget correspondente ao elemento
        Expanded(
          child: _buildElementWidgetContent(element, index),
        ),
      ],
    );
  }

  // Separando o conteúdo original para manter a lógica modular
  Widget _buildElementWidgetContent(Map<String, dynamic> element, int index) {
    switch (element["type"]) {
      case "text":
        return _buildTextElement(element, index);
      case "quote":
        return _buildQuoteElement(element, index);
      case "caption":
        return _buildCaptionElement(element, index);
      case "image":
        return _buildImageElement(element, index);
      case "link":
        return _buildLinkElement(element, index);
      default:
        return Text("Tipo desconhecido");
    }
  }

  // Widget para citação
  Widget _buildQuoteElement(Map<String, dynamic> element, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _getController(element["id"], "quote"),
            onChanged: (value) {
              setState(() {
                widget.data["elements"][index]["content"] = value;
              });
            },
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Citação",
              hintText: "Insira sua citação aqui",
            ),
          ),
        ),
      ],
    );
  }

  // Widget para legenda
  Widget _buildCaptionElement(Map<String, dynamic> element, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _getController(element["id"], "caption"),
            onChanged: (value) {
              setState(() {
                widget.data["elements"][index]["content"] = value;
              });
            },
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Legenda",
              hintText: "Insira sua legenda aqui",
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkElement(Map<String, dynamic> element, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo para o título do link
        TextField(
          controller: _getController(element["id"], "link-title"), // Controlador para o título
          onChanged: (value) {
            setState(() {
              widget.data["elements"][index]["title"] = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Título do Link",
            hintText: "Insira o título aqui",
          ),
        ),
        const SizedBox(height: 8),
        // Campo para o URL do link
        TextField(
          controller: _getController(element["id"], "link-url"), // Controlador para o link
          onChanged: (value) {
            setState(() {
              widget.data["elements"][index]["content"] = value;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "URL",
            hintText: "Insira o link aqui",
          ),
        ),
      ],
    );
  }


  Widget _buildTextElement(Map<String, dynamic> element, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Campo de input de texto
        Expanded(
          flex: 4,
          child: TextField(
            controller: _getController(element["id"], "text"), // Reutilize o controlador
            onChanged: (value) {
              setState(() {
                widget.data["elements"][index]["content"] = value;
              });
            },
            maxLines: 4,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Texto",
            )
          ),
        ),
        const SizedBox(width: 8),
        // Botões de controle
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botão de alinhamento
              IconButton(
                icon: Icon(
                  widget.data["elements"][index]["align"] == "left"
                      ? Icons.format_align_left
                      : widget.data["elements"][index]["align"] == "center"
                          ? Icons.format_align_center
                          : Icons.format_align_right,
                ),
                onPressed: () {
                  _toggleAlignment(index);
                },
                tooltip: "Alterar Alinhamento",
              ),
              // Botão de estilo
              IconButton(
                icon: Icon(
                  widget.data["elements"][index]["format"] == "normal"
                      ? Icons.text_fields
                      : widget.data["elements"][index]["format"] == "bold"
                          ? Icons.format_bold
                          : Icons.format_italic,
                ),
                onPressed: () {
                  _toggleFormat(index);
                },
                tooltip: "Alterar Estilo",
              ),
              IconButton(
                icon: Icon(Icons.color_lens),
                onPressed: () {
                  _changeColor(index);
                },
                tooltip: "Alterar Cor",
              ),
              // Bolinha de preview da cor
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse(
                    (widget.data["elements"][index]["color"] ?? "#000000").substring(1, 7),
                    radix: 16,
                  ) + 0xFF000000),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Text("RAW", style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _showRawJSON,
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(100, 100, 100, 100),
                  items: options
                      .map((opt) => PopupMenuItem(
                            value: opt,
                            child: Text(opt),
                          ))
                      .toList(),
                ).then((value) {
                  if (value != null) {
                    switch(value.toString().toLowerCase()) {
                      case "texto":
                        _addElement("text");
                        break;
                      case "imagem":
                        _addElement("image");
                        break;
                      case "citação":
                        _addElement("quote");
                        break;
                      case "legenda":
                        _addElement("caption");
                        break;
                      case "link":
                        _addElement("link");
                        break;
                    }
                  }
                });
              },
              child: Text("+ Adicionar Informação"),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.data["elements"].length,
                itemBuilder: (context, index) {
                  final element = widget.data["elements"][index];
                  
                  // Renderiza dinamicamente baseado no tipo do elemento
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildElementWidget(element, index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
