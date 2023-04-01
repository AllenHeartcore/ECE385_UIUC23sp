#include <stdio.h>
#include <stdlib.h>

#define COLORED

int main() {
	printf("Starting VGA test\n");

#ifdef COLORED
	#include "vga_text_color.h"
	// textVGAColorPaletteTest();
	textVGAColorScreenSaver();
#else
	#include "vga_text.h"
	while (1)
		textVGATest();
#endif

	return 0;
}
