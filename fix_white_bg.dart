import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    bool changed = false;
    final lines = file.readAsLinesSync();
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('color: context.colors.white,') || lines[i].contains('fillColor: context.colors.white,')) {
        // Look around to make sure it's not text or icon
        bool isTextOrIcon = false;
        
        // Check current line
        if (lines[i].contains('Icon') || lines[i].contains('Text') || lines[i].contains('Border') || lines[i].contains('Divider')) {
          isTextOrIcon = true;
        }
        
        // Check previous line
        if (i > 0 && (lines[i-1].contains('Icon') || lines[i-1].contains('Text') || lines[i-1].contains('Border') || lines[i-1].contains('Divider'))) {
            isTextOrIcon = true;
        }
        
        // Check next line
        if (i < lines.length - 1 && (lines[i+1].contains('Icon') || lines[i+1].contains('Text') || lines[i+1].contains('Border') || lines[i+1].contains('Divider'))) {
            // But wait, if it's a container and next line is border, it's fine.
            if (!lines[i+1].contains('Border')) {
                isTextOrIcon = true;
            }
        }

        // Specifically check for BoxShadow, BoxDecoration, Container, Card which implies background
        bool isBackground = false;
        for (int j = i; j >= 0 && j > i - 5; j--) {
           if (lines[j].contains('BoxDecoration') || lines[j].contains('Container') || lines[j].contains('Card') || lines[j].contains('InputDecoration')) {
               isBackground = true;
               break;
           }
        }
        
        if (isBackground && !lines[i].contains('Icon') && !lines[i].contains('Text')) {
            lines[i] = lines[i].replaceAll('context.colors.white', 'context.colors.bgSurface');
            changed = true;
        }
      }
    }
    
    if (changed) {
      file.writeAsStringSync(lines.join('\n') + '\n');
      print('Updated ${file.path}');
    }
  }
}
