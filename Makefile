.PHONY: build test benchmark

build:
	dart --enable-experiment=native-assets run build.dart

test: build
	dart --enable-experiment=native-assets run test/ml_dsa_test.dart

benchmark: build
	dart --enable-experiment=native-assets compile exe test/ml_dsa_benchmark_test.dart -o benchmarks
	@./benchmarks
	@rm benchmarks

