int modMultiply(int a,int  b, int q) {
	return (a * b) % q;
}

int modQSymmetric(int n, int q) {
	int result = modQ(n, q);

	if (result > (q/2).floor()) {
		result -= q;
	}

	return result;
}

int modQ(int n, int q) {
	return (n%q + q) % q;
}
