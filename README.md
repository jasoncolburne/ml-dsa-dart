This implementation was ported from https://github.com/jasoncolburne/ml-dsa-go in a couple days. It is also in its infancy.

## Performance

Here is the result of my [performance tuning](https://github.com/jasoncolburne/ml-dsa-dart/pull/4).
This was comprised of data structure and algorithmic tuning, such as bitwise logic in places,
`Int32List` and `Uint8List` replacement where using `List<int>` previously. Fixed many variables
to avoid re-computation or indirect access in loops. The biggest gain, however, was seen when I
replaced the dart implementation of Shake128 and Shake256 with the official C implementation. This
is primarily because of the lack of Uint64s in Dart, that one bit really complicates things.

About that official implementation - to work with ML-DSA, squeezing needed a small adjustment:

```C
int SpongeAbsorbLastFewBits(SpongeInstance *instance, unsigned char delimitedData)
{
    unsigned int rateInBytes = instance->rate/8;

    if (delimitedData == 0)
        return 1;
    if (instance->squeezing)
        return 0; /* Too late for additional input */

    /* ... */
}
```

The `return 0` there if squeezing is in progress, it used to be `return 1`. This is necessary to
allow for repeated absorption and squeezing.

### Results

```
❯ git checkout main && dart pub get && dart compile exe test/ml_dsa_benchmark_test.dart -o benchmarks && ./benchmarks && git checkout performance && dart pub get && dart --enable-experiment=native-assets compile exe test/ml_dsa_benchmark_test.dart -o benchmarks && ./benchmarks
Switched to branch 'main'
Your branch is up to date with 'origin/main'.
Resolving dependencies... 
...
Generated: /Users/jason/github.com/jasoncolburne/ml-dsa-dart/benchmarks
44-Generate: 4970.750 µs/op 201.177 ops/s
65-Generate: 8615.237 µs/op 116.073 ops/s
87-Generate: 14143.603 µs/op 70.703 ops/s
44-Sign: 11255.830 µs/op 88.843 ops/s
65-Sign: 18764.463 µs/op 53.292 ops/s
87-Sign: 24207.215 µs/op 41.310 ops/s
44-Verify: 4513.760 µs/op 221.545 ops/s
65-Verify: 7710.863 µs/op 129.687 ops/s
87-Verify: 13434.475 µs/op 74.435 ops/s
Switched to branch 'performance'
Your branch is up to date with 'origin/performance'.
Resolving dependencies... (1.0s)
...
Generated: /Users/jason/github.com/jasoncolburne/ml-dsa-dart/benchmarks
44-Generate: 1407.086 µs/op 710.689 ops/s
65-Generate: 2272.324 µs/op 440.078 ops/s
87-Generate: 3552.133 µs/op 281.521 ops/s
44-Sign: 3980.023 µs/op 251.255 ops/s
65-Sign: 5805.945 µs/op 172.237 ops/s
87-Sign: 7019.512 µs/op 142.460 ops/s
44-Verify: 1081.094 µs/op 924.989 ops/s
65-Verify: 1767.533 µs/op 565.760 ops/s
87-Verify: 3126.011 µs/op 319.896 ops/s
```

Tests were performed on an Apple M2 Max Macbook Pro (2023).

## TODO

- [x] Proper DRBG (? - I didn't really audit what I did)
