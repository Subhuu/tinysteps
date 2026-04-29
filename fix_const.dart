import 'dart:io';

void main() async {
  int maxIterations = 20;
  for (int i = 0; i < maxIterations; i++) {
    print('Iteration $i');
    var result = await Process.run('flutter.bat', ['analyze'], runInShell: true);
    
    bool fixedSomething = false;
    var lines = result.stdout.toString().split('\n');
    lines.addAll(result.stderr.toString().split('\n'));
    
    var errorRegex = RegExp(r"(?:error|warning) - .+ - (.+\.dart):(\d+):\d+ - (invalid_assignment|const_initialized_with_non_constant_value|non_constant_default_value|const_with_non_constant_argument|non_constant_list_element|non_constant_map_key|non_constant_map_value|non_constant_set_element|invalid_constant)");
    
    for (var line in lines) {
      var match = errorRegex.firstMatch(line);
      if (match != null) {
        var file = match.group(1)!;
        var lineNum = int.parse(match.group(2)!);
        
        var f = File(file);
        if (f.existsSync()) {
          var contentLines = f.readAsLinesSync();
          // Search upwards up to 15 lines for the 'const' keyword
          bool foundConst = false;
          int searchLimit = lineNum > 15 ? lineNum - 15 : 0;
          for (int currLine = lineNum - 1; currLine >= searchLimit; currLine--) {
            if (currLine < contentLines.length) {
              var lineContent = contentLines[currLine];
              if (lineContent.contains('const ')) {
                // Find the LAST const on that line (closest to the error)
                var lastIndex = lineContent.lastIndexOf('const ');
                contentLines[currLine] = lineContent.substring(0, lastIndex) + lineContent.substring(lastIndex + 6);
                f.writeAsStringSync(contentLines.join('\n') + '\n');
                print('Fixed const in $file at line ${currLine + 1} (error reported at $lineNum)');
                fixedSomething = true;
                foundConst = true;
                break;
              } else if (lineContent.contains('const\n') || lineContent.endsWith('const')) {
                 var lastIndex = lineContent.lastIndexOf('const');
                 contentLines[currLine] = lineContent.substring(0, lastIndex) + lineContent.substring(lastIndex + 5);
                 f.writeAsStringSync(contentLines.join('\n') + '\n');
                 print('Fixed const in $file at line ${currLine + 1} (error reported at $lineNum)');
                 fixedSomething = true;
                 foundConst = true;
                 break;
              }
            }
          }
        }
      }
    }
    
    if (!fixedSomething) {
      print('No more const errors found or unable to auto-fix.');
      break;
    }
  }
}
