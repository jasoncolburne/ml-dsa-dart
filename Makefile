.PHONY: build test example

build:
	dart --enable-experiment=native-assets run build.dart

test: build
	dart --enable-experiment=native-assets run test/ml_dsa_test.dart

example: build
	dart --enable-experiment=native-assets run example/ml_dsa_example.dart

benchmark: build
	dart --enable-experiment=native-assets compile exe test/ml_dsa_benchmark_test.dart -o benchmarks
	@./benchmarks
	@rm benchmarks

format:
	dart format lib test/ml_dsa* example

lint:
	dart analyze --fatal-infos

fix:
	dart fix --apply
