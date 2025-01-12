import 'dart:io';
import 'package:path/path.dart' as path;

void main(List<String> args) {
  final srcDir = Directory('src/KeccakSum');
  final buildDir = Directory('build');

  if (!buildDir.existsSync()) {
    buildDir.createSync();
  }

  String compiler;
  String objectExtension = '.o';
  List<String> linkerArgs;
  String outputExtension;

  if (Platform.isMacOS) {
    compiler = 'clang';
    outputExtension = '.dylib';
    linkerArgs = [
      '-shared',
      '-undefined',
      'dynamic_lookup',
    ];
  } else if (Platform.isLinux) {
    compiler = 'cc';
    outputExtension = '.so';
    linkerArgs = [
      '-shared',
      '-Wl,-undefined',
      '-Wl,dynamic_lookup',
    ];
  } else {
    print('Unsupported platform: ${Platform.operatingSystem}');
    return;
  }

  List<String> objects = [];

  // Compile C files
  for (var entity in srcDir.listSync()) {
    if (entity is File && path.extension(entity.path) == '.c') {
      final objectPath = path.join(buildDir.path,
        path.basenameWithoutExtension(entity.path) + objectExtension);
      
      final result = Process.runSync(compiler, [
        '-o',
        objectPath,
        '-c',
        entity.path,
      ]);

      if (result.exitCode != 0) {
        print('Error compiling ${entity.path}: ${result.stderr}');
      } else {
        objects.add(objectPath);
        print('Compiled ${entity.path} to $objectPath');
      }
    }
  }

  final result = Process.runSync(compiler, [
    ...linkerArgs,
    '-o',
    'build/libkeccak$outputExtension',
    ...objects,
  ]);

  if (result.exitCode != 0) {
    print('Error linking: ${result.stderr}');
  } else {
    print('Linked to libkeccak$outputExtension');
  }
}
