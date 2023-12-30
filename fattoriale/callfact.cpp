#include <iostream>

extern "C" {
	double fact(double);
}
int main(){
	int n;
	std::cout << "Inserisci il valore di n: ";
	std::cin >> n;
	std::cout << "il valore del fattoriale: "<< fact(n) <<std::endl;
}
