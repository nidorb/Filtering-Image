#include <stdlib.h>
#include <stdio.h>

#define ARRSIZE 24

extern int imgAvgFilter(
  int * input_image, 
  int * filtered_image, 
  int image_size_x, 
  int image_size_y, 
  int sampling_window_size
);

int main() {
  int input[ARRSIZE] = {
      11, 23, 45, 67,
      8,  32, 55, 92,
      14, 78, 36, 49,
      72, 3,  19, 87,
      41, 66, 29, 50,
      95, 12, 57, 63
  };

  int x = 6, y = 4;

  int window; // must also be odd to have a center
  printf("\nEnter window size: ");
  scanf("%d", &window);

  int output[ARRSIZE];

  int wow = imgAvgFilter(input, output, x, y, window);

  int i, j, k = 0;
  for (i = 0; i < x; i++) {
    for (j = 0; j < y; j++) {
      printf("%d\t", output[k++]);
    }
    printf("\n");
  }

  printf("\nPress Enter to quit...");
  while (getchar() != '\n') {} // Consume any additional characters
  getchar(); // Wait for Enter key press

  return 0;
}

