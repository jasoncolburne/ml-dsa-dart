abstract class ParameterSet {
  int q();
  int zeta();
  int d();
  int tau();
  int lambda();
  int gamma1();
  int gamma2();
  int k();
  int l();
  int eta();
  int beta();
  int omega();
}

class MLDSA44Parameters implements ParameterSet {
  @override
  int q() => 8380417;

  @override
  int zeta() => 1753;

  @override
  int d() => 13;

  @override
  int tau() => 39;

  @override
  int lambda() => 128;

  @override
  int gamma1() => 131072;

  @override
  int gamma2() => 95232;

  @override
  int k() => 4;

  @override
  int l() => 4;

  @override
  int eta() => 2;

  @override
  int beta() => 78; // Added implementation for beta

  @override
  int omega() => 80;
}

class MLDSA65Parameters implements ParameterSet {
  @override
  int q() => 8380417;

  @override
  int zeta() => 1753;

  @override
  int d() => 13;

  @override
  int tau() => 49;

  @override
  int lambda() => 192;

  @override
  int gamma1() => 524288;

  @override
  int gamma2() => 261888;

  @override
  int k() => 6;

  @override
  int l() => 5;

  @override
  int eta() => 4;

   @override
   int beta() =>196; // Added implementation for beta

   @override
   int omega() =>55;
}

class MLDSA87Parameters implements ParameterSet {
   @override
   int q() =>8380417;

   @override
   int zeta() =>1753;

   @override
   int d() =>13;

   @override
   int tau() =>60;

   @override
   int lambda() =>256;

   @override
   int gamma1() =>524288;

   @override
   int gamma2() =>261888;

   @override
   int k() =>8;

   @override
   int l() =>7;

   @override
   int eta() =>2;
   
   @override 
   int beta()=>120;

   @override 
   int omega()=>75;
}