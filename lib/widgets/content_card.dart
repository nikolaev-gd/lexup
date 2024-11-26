import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  final String text;
  final String link;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ContentCard({
    Key? key,
    required this.text,
    this.link = '',
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  String get title {
    if (text.isNotEmpty) {
      final words = text.split(RegExp(r'\s+'));
      final firstThreeWords = words.take(3).join(' ');
      return firstThreeWords.length > 70 ? '${firstThreeWords.substring(0, 67)}...' : firstThreeWords;
    }
    return link.isNotEmpty ? 'Ссылка' : 'Нет содержимого';
  }

  String get previewText {
    if (text.isNotEmpty) {
      final lines = text.split('\n');
      if (lines.isEmpty) return '';
      if (lines.length == 1) return lines[0];
      final previewLines = lines.take(5).toList();
      if (lines.length > 5) {
        previewLines.add('...');
      }
      return previewLines.join('\n');
    }
    return link.isNotEmpty ? link : 'Нет содержимого';
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content: const Text('Вы уверены, что хотите удалить эту карточку?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Удалить'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    previewText,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () => _showDeleteConfirmationDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
