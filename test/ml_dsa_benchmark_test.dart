import 'dart:convert';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ml_dsa/ml_dsa.dart';

void benchmarkMLDSAGenerate(MLDSA dsa) {
  dsa.keyGen();
}

void benchmarkMLDSASign(MLDSA dsa, Uint8List sk, Uint8List message, Uint8List ctx) {
  dsa.sign(sk, message, ctx);
}

void benchmarkMLDSAVerify(MLDSA dsa, Uint8List pk, Uint8List message, Uint8List sig, Uint8List ctx) {
  dsa.verify(pk, message, sig, ctx);
}

class GenerateBenchmark extends BenchmarkBase {
  GenerateBenchmark(super.title, {required this.params, required this.trialsPerRun});

  final ParameterSet params;
  final int trialsPerRun;

  late MLDSA _dsa;

  @override
  void run() {
    benchmarkMLDSAGenerate(_dsa);
  }

  @override
  void setup() {
    _dsa = MLDSA(params);
  }

  @override
  void exercise() {
    // do at least 250 trials
    for (int i = 0; i < trialsPerRun; i ++) {
      run();
    }
  }

  @override
  void report() {
    var microsecondsPerRun = measure() / trialsPerRun;
    var operationsPerSecond = 1 / (microsecondsPerRun * 0.000001);
    print('$name: ${microsecondsPerRun.toStringAsFixed(3)} µs/op ${operationsPerSecond.toStringAsFixed(3)} ops/s');
  }
}

class MLDSA44GenerateBenchmark extends GenerateBenchmark {
  MLDSA44GenerateBenchmark() : super('44-Generate', params: MLDSA44Parameters(), trialsPerRun: 250);
}

class MLDSA65GenerateBenchmark extends GenerateBenchmark {
  MLDSA65GenerateBenchmark() : super('65-Generate', params: MLDSA65Parameters(), trialsPerRun: 250);
}

class MLDSA87GenerateBenchmark extends GenerateBenchmark {
  MLDSA87GenerateBenchmark() : super('87-Generate', params: MLDSA87Parameters(), trialsPerRun: 250);
}

class SignBenchmark extends BenchmarkBase {
  SignBenchmark(super.title, {required this.params, required this.trialsPerRun});
  
  final ParameterSet params;
  final int trialsPerRun;

  late MLDSA _dsa;
  late Uint8List _sk;
  late Uint8List _message;
  late Uint8List _ctx;

  @override
  void run() {
    benchmarkMLDSASign(_dsa, _sk, _message, _ctx);
  }

  @override
  void setup() {
    _dsa = MLDSA(params);
    final (_, sk) = _dsa.keyGen();
    _sk = sk;

    _message = utf8.encode("fabulous message");
    _ctx = utf8.encode("context");
  }

  @override
  void exercise() {
    // do at least 250 trials
    for (int i = 0; i < trialsPerRun; i ++) {
      run();
    }
  }

  @override
  void report() {
    var microsecondsPerRun = measure() / trialsPerRun;
    var operationsPerSecond = 1 / (microsecondsPerRun * 0.000001);
    print('$name: ${microsecondsPerRun.toStringAsFixed(3)} µs/op ${operationsPerSecond.toStringAsFixed(3)} ops/s');
  }
}

class MLDSA44SignBenchmark extends SignBenchmark {
  MLDSA44SignBenchmark() : super('44-Sign', params: MLDSA44Parameters(), trialsPerRun: 250);
}

class MLDSA65SignBenchmark extends SignBenchmark {
  MLDSA65SignBenchmark() : super('65-Sign', params: MLDSA65Parameters(), trialsPerRun: 250);
}

class MLDSA87SignBenchmark extends SignBenchmark {
  MLDSA87SignBenchmark() : super('87-Sign', params: MLDSA87Parameters(), trialsPerRun: 250);
}

class VerifyBenchmark extends BenchmarkBase {
  VerifyBenchmark(super.title, {required this.params, required this.trialsPerRun});
  
  final ParameterSet params;
  final int trialsPerRun;

  late MLDSA _dsa;
  late Uint8List _pk;
  late Uint8List _message;
  late Uint8List _sig;
  late Uint8List _ctx;

  @override
  void run() {
    benchmarkMLDSAVerify(_dsa, _pk, _message, _sig, _ctx);
  }

  @override
  void setup() {
    _dsa = MLDSA(params);
    final (pk, sk) = _dsa.keyGen();
    _pk = pk;

    _message = utf8.encode("fabulous message");
    _ctx = utf8.encode("context");
    _sig = _dsa.sign(sk, _message, _ctx);
  }

  @override
  void exercise() {
    // do at least 250 trials
    for (int i = 0; i < trialsPerRun; i ++) {
      run();
    }
  }

  @override
  void report() {
    var microsecondsPerRun = measure() / trialsPerRun;
    var operationsPerSecond = 1 / (microsecondsPerRun * 0.000001);
    print('$name: ${microsecondsPerRun.toStringAsFixed(3)} µs/op ${operationsPerSecond.toStringAsFixed(3)} ops/s');
  }
}

class MLDSA44VerifyBenchmark extends VerifyBenchmark {
  MLDSA44VerifyBenchmark() : super('44-Verify', params: MLDSA44Parameters(), trialsPerRun: 250);
}

class MLDSA65VerifyBenchmark extends VerifyBenchmark {
  MLDSA65VerifyBenchmark() : super('65-Verify', params: MLDSA65Parameters(), trialsPerRun: 250);
}

class MLDSA87VerifyBenchmark extends VerifyBenchmark {
  MLDSA87VerifyBenchmark() : super('87-Verify', params: MLDSA87Parameters(), trialsPerRun: 250);
}

void main() {
  MLDSA44GenerateBenchmark().report();
  MLDSA65GenerateBenchmark().report();
  MLDSA87GenerateBenchmark().report();

  MLDSA44SignBenchmark().report();
  MLDSA65SignBenchmark().report();
  MLDSA87SignBenchmark().report();

  MLDSA44VerifyBenchmark().report();
  MLDSA65VerifyBenchmark().report();
  MLDSA87VerifyBenchmark().report();
}
