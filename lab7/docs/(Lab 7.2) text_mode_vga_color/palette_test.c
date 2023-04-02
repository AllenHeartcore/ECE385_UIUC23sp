/*
 * palette_test.c
 *
 *  Created on: Apr 6, 2022
 *      Author: zcheng1
 */

#include "text_mode_vga_color.h"


void paletteTest()
{
	textVGAColorClr();
	textVGADrawColorText ("This text should cycle through random colors", 0, 0, 0, 1);

	for (int i = 0; i < 100; i ++)
	{
		usleep (20000);
		setColorPalette(0, 	rand() % 16, rand() % 16,rand() % 16); //set color 0 to random color;
		setColorPalette(1, 	rand() % 16, rand() % 16,rand() % 16); //set color 1 to random color;
	}

}
