// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/targets/shader_compiler.dart';

import '../../../src/common.dart';
import '../../../src/fake_process_manager.dart';

const String fragDir = '/shaders';
const String fragPath = '/shaders/my_shader.frag';
const String notFragPath = '/shaders/not_a_frag.file';
const String outputSpirvPath = '/output/shaders/my_shader.frag.spirv';
const String outputPath = '/output/shaders/my_shader.frag';

void main() {
  late BufferLogger logger;
  late MemoryFileSystem fileSystem;
  late Artifacts artifacts;
  late String impellerc;

  setUp(() {
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    impellerc = artifacts.getHostArtifact(HostArtifact.impellerc).path;

    fileSystem.file(impellerc).createSync(recursive: true);
    fileSystem.file(fragPath).createSync(recursive: true);
    fileSystem.file(notFragPath).createSync(recursive: true);
  });

  testWithoutContext('compileShader invokes impellerc for .frag files', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$fragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(fragPath),
        outputPath: outputPath,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext('compileShader invokes impellerc for non-.frag files', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        onRun: () {
          fileSystem.file(outputPath).createSync(recursive: true);
          fileSystem.file(outputSpirvPath).createSync(recursive: true);
        },
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    expect(
      await shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
      ),
      true,
    );
    expect(fileSystem.file(outputPath).existsSync(), true);
    expect(fileSystem.file(outputSpirvPath).existsSync(), false);
  });

  testWithoutContext('compileShader throws an exception when impellerc fails', () async {
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: <String>[
          impellerc,
          '--sksl',
          '--iplr',
          '--sl=$outputPath',
          '--spirv=$outputSpirvPath',
          '--input=$notFragPath',
          '--input-type=frag',
          '--include=$fragDir',
        ],
        exitCode: 1,
      ),
    ]);
    final ShaderCompiler shaderCompiler = ShaderCompiler(
      processManager: processManager,
      logger: logger,
      fileSystem: fileSystem,
      artifacts: artifacts,
    );

    await expectLater(
      () => shaderCompiler.compileShader(
        input: fileSystem.file(notFragPath),
        outputPath: outputPath,
      ),
      throwsA(isA<ShaderCompilerException>()),
    );
    expect(fileSystem.file(outputPath).existsSync(), false);
  });
}
