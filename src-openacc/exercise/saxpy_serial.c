#include <stdlib.h> 

int main(int argc, char **argv) 
{

  int N=1000;
  float a = 3.0f;
  float x[N], y[N];

  for (int i = 0; i < N; ++i) { 
     x[i] = 2.0f; 
     y[i] = 1.0f; 
  } 

  for (int i = 0; i < N; ++i) { 
     y[i] = a * x[i] + y[i];
  } 

  printf("%f \t %f \n", y[0], y[N-1]);

  return 0; 

}
