#ifndef TEXT_MODE_VGA_H_
#define TEXT_MODE_VGA_H_

#include <system.h>
#include <alt_types.h>

#define COLS 80
#define ROWS 30

#define WHITE 		0xFFF
#define BRIGHT_RED 	0xF00
#define DIM_RED    	0x700
#define BRIGHT_GRN	0x0F0
#define DIM_GRN		0x070
#define BRIGHT_BLU  0x00F
#define DIM_BLU		0x007
#define GRAY		0x777
#define BLACK		0x000

struct text_vga_struct {
	alt_u8  VRAM [ROWS * COLS];
	alt_u32 CTRL;
};

static volatile struct text_vga_struct* vga_ctrl = VGA_TEXT_BASE;

void textVGAClr();
void textVGASetColor(int background, int foreground);
void textVGATest();

#endif
