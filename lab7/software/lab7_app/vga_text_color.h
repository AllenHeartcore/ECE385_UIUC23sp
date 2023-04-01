#ifndef TEXT_MODE_VGA_COLOR_H_
#define TEXT_MODE_VGA_COLOR_H_

#include <system.h>
#include <alt_types.h>

#define COLS 80
#define ROWS 30
#define PALETTE_SIZE 8

struct text_vga_struct {
	alt_u8  VRAM [ROWS * COLS * 2];
	alt_u8  reserved[0x2000 - (ROWS * COLS * 2)];
	alt_u32 palette[PALETTE_SIZE];
};

struct color_struct {
	char name[20];
	alt_u8 red;
	alt_u8 green;
	alt_u8 blue;
};

static volatile struct text_vga_struct* vga_ctrl = VGA_TEXT_BASE;

static struct color_struct colors[] = {
    {"black",          0x0, 0x0, 0x0},
	{"blue",           0x0, 0x0, 0xA},
    {"green",          0x0, 0xA, 0x0},
	{"cyan",           0x0, 0xA, 0xA},
    {"red",            0xA, 0x0, 0x0},
	{"magenta",        0xA, 0x0, 0xA},
    {"brown",          0xA, 0x5, 0x0},
	{"light gray",     0xA, 0xA, 0xA},
    {"dark gray",      0x5, 0x5, 0x5},
	{"light blue",     0x5, 0x5, 0xF},
    {"light green",    0x5, 0xF, 0x5},
	{"light cyan",     0x5, 0xF, 0xF},
    {"light red",      0xF, 0x5, 0x5},
	{"light magenta",  0xF, 0x5, 0xF},
    {"yellow",         0xF, 0xF, 0x5},
	{"white",          0xF, 0xF, 0xF}
};

void textVGAColorClr();
void textVGAColorDrawText(char* str, int x, int y, alt_u8 background, alt_u8 foreground);
void textVGAColorSetPalette(alt_u8 color, alt_u8 red, alt_u8 green, alt_u8 blue);
void textVGAColorScreenSaver();
void textVGAColorPaletteTest();

#endif
