def fibonacci(n)
	n<2 ? 1 : {
		var a = fibonacci(n-1);
		var b = fibonacci(n-2);
		a+b
		};

