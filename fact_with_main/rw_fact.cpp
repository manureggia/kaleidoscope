#include <iostream>

extern "C" {
	double n();
}
extern "C" {
	double printval(double);
}

double n(){
	double tmp;
	std::cout<<"inserisce il valore di n: ";
	std::cin>>tmp;
	return tmp;
}

double printval(double n){
	std::cout<<"il fattoriale è: "<<n<<std::endl;
}
