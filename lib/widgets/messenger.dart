import 'package:flutter/material.dart';

class Messenger {
  // Exibe uma mensagem de erro em um SnackBar
  static void showError(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Exibe uma mensagem de sucesso em um SnackBar
  static void showSuccess(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Exibe uma mensagem informativa em um SnackBar
  static void showInfo(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Exibe um diálogo de confirmação
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  // Exibe um diálogo genérico
  static Future<void> showCustomDialog(
    BuildContext context, {
    required Widget title,
    required Widget content,
    List<Widget>? actions,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title,
          content: content,
          actions: actions,
        );
      },
    );
  }

  // Exibe uma mensagem de carregamento com indicador de progresso
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String message = 'Carregando...',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Evita fechar clicando fora
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  // Fecha qualquer diálogo aberto
  static void closeDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
