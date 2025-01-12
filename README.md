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

**Key Generation:**<br/>
ML-DSA-44: 3.53x faster (201 ops/s to 711 ops/s)<br/>
ML-DSA-65: 3.79x faster (116 ops/s to 440 ops/s)<br/>
ML-DSA-87: 3.98x faster (71 ops/s to 282 ops/s)<br/>

**Signing:**<br/>
ML-DSA-44: 2.83x faster (89 ops/s to 251 ops/s)<br/>
ML-DSA-65: 3.23x faster (53 ops/s to 172 ops/s)<br/>
ML-DSA-87: 3.45x faster (41 ops/s to 142 ops/s)<br/>

**Verification:**<br/>
ML-DSA-44: 4.17x faster (222 ops/s to 925 ops/s)<br/>
ML-DSA-65: 4.36x faster (130 ops/s to 566 ops/s)<br/>
ML-DSA-87: 4.30x faster (74 ops/s to 320 ops/s)<br/>

_From Perplexity_: Overall, the performance improvements range from 2.83x to 4.36x faster across all ML-DSA variants. The most significant gains are observed in the verification process, with improvements becoming more pronounced for larger key sizes, particularly in key generation and signing operations.

Tests were performed on an Apple M2 Max Macbook Pro (2023).

## TODO

- [x] Proper DRBG (? - I didn't really audit what I did)
