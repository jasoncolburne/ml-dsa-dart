This implementation was ported from https://github.com/jasoncolburne/ml-dsa-go in a couple days. It is also in its infancy.

## Performance

Here is the result of my [performance tuning](https://github.com/jasoncolburne/ml-dsa-dart/pull/4).
This was comprised of data structure and algorithmic tuning, such as bitwise logic in places,
`Int32List` and `Uint8List` replacement where using `List<int>` previously. Fixed many variables
to avoid re-computation or indirect access in loops:

```
❯ git checkout main && dart compile exe test/ml_dsa_benchmark_test.dart -o benchmarks && ./benchmarks && git checkout performance && dart compile exe test/ml_dsa_benchmark_test.dart -o benchmarks && ./benchmarks
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
Generated: /Users/jason/github.com/jasoncolburne/ml-dsa-dart/benchmarks
44-Generate: 4826.413 µs/op 207.193 ops/s
65-Generate: 8514.897 µs/op 117.441 ops/s
87-Generate: 14077.228 µs/op 71.037 ops/s
44-Sign: 10896.225 µs/op 91.775 ops/s
65-Sign: 17991.033 µs/op 55.583 ops/s
87-Sign: 24003.785 µs/op 41.660 ops/s
44-Verify: 4473.095 µs/op 223.559 ops/s
65-Verify: 7686.275 µs/op 130.102 ops/s
87-Verify: 13381.968 µs/op 74.727 ops/s
Switched to branch 'performance'
Your branch is up to date with 'origin/performance'.
Generated: /Users/jason/github.com/jasoncolburne/ml-dsa-dart/benchmarks
44-Generate: 4567.965 µs/op 218.916 ops/s
65-Generate: 8043.140 µs/op 124.330 ops/s
87-Generate: 13427.917 µs/op 74.472 ops/s
44-Sign: 10488.028 µs/op 95.347 ops/s
65-Sign: 16753.415 µs/op 59.689 ops/s
87-Sign: 21763.005 µs/op 45.950 ops/s
44-Verify: 4226.392 µs/op 236.608 ops/s
65-Verify: 7315.495 µs/op 136.696 ops/s
87-Verify: 12829.872 µs/op 77.943 ops/s
```

Tests were performed on an Apple M2 Max Macbook Pro (2023).

Interestingly, JIT execution wins over AOT compilation, by a significant margin:

```
❯ dart run test/ml_dsa_benchmark_test.dart
44-Generate: 2556.199 µs/op 391.206 ops/s
65-Generate: 4394.417 µs/op 227.561 ops/s
87-Generate: 7177.262 µs/op 139.329 ops/s
44-Sign: 6342.540 µs/op 157.666 ops/s
65-Sign: 10212.110 µs/op 97.923 ops/s
87-Sign: 13870.870 µs/op 72.094 ops/s
44-Verify: 2376.854 µs/op 420.724 ops/s
65-Verify: 4002.675 µs/op 249.833 ops/s
87-Verify: 6953.257 µs/op 143.817 ops/s
```

## TODO

- [ ] Proper DRBG
