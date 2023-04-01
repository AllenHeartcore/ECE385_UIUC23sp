#include <stdio.h>
#include <stdlib.h>
#include "vga_text.h"

int main() {
	printf("Starting VGA test\n");
	while (1)
		textVGATest();
	return 0;
}
