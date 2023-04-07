#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <system.h>
#include <alt_types.h>
#include "vga_text_color.h"


void textVGAColorClr() {
	for (int i = 0; i < ROWS * COLS * 2; i++) {
		vga_ctrl->VRAM[i] = 0x00;
	}
	for (int i = 0; i < PALETTE_SIZE; i++) {
		vga_ctrl->palette[i] = 0x00000000;
	}
}

void textVGAColorDrawText(char* str, int x, int y, alt_u8 background, alt_u8 foreground) {
	int i = 0;
	while (str[i] != 0) {
		vga_ctrl->VRAM[(y * COLS + x + i) * 2] = foreground << 4 | background;
		vga_ctrl->VRAM[(y * COLS + x + i) * 2 + 1] = str[i];
		i++;
	}
}

void textVGAColorSetPalette(alt_u8 color, alt_u8 red, alt_u8 green, alt_u8 blue) {
	alt_u32 tmp;
	tmp = vga_ctrl->palette[color / 2];
	if (color % 2) {
		tmp &= 0xFE001FFF;
		tmp |= (red << 21) | (green << 17) | (blue << 13);
	} else {
		tmp &= 0xFFFFE001;
		tmp |= (red <<  9) | (green <<  5) | (blue <<  1);
	}
	vga_ctrl->palette[color / 2] = tmp;
}

void textVGAColorScreenSaver() {
	char color_string[80];
	int fg, bg, x, y;
	textVGAColorClr();
	for (int i = 0; i < 16; i++) {
		textVGAColorSetPalette(i, colors[i].red, colors[i].green, colors[i].blue);
	}
	while (1) {
		fg = rand() % 16;
		bg = rand() % 16;
		while (fg == bg) {
			fg = rand() % 16;
			bg = rand() % 16;
		}
		sprintf(color_string, "Drawing %s text with %s background", colors[fg].name, colors[bg].name);
		x = rand() % (80 - strlen(color_string));
		y = rand() % 30;
		textVGAColorDrawText(color_string, x, y, bg, fg);
		usleep(100000);
	}
}

void textVGAColorPaletteTest() {
	textVGAColorClr();
	textVGAColorDrawText("This text should cycle through random colors", 0, 0, 0, 1);
	for (int i = 0; i < 100; i++) {
		usleep(20000);
		textVGAColorSetPalette(0, rand() % 16, rand() % 16, rand() % 16);
		textVGAColorSetPalette(1, rand() % 16, rand() % 16, rand() % 16);
	}
}
