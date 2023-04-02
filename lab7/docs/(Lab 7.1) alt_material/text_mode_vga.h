/*
 *  text_mode_vga.h
 *	Minimal driver for text mode VGA support, ECE 385 Summer 2021 Lab 6
 *  Modified 10/19/2021 for week 1 of Lab 7
 * 
 *  Created on: Jul 17, 2021
 *      Author: zuofu
 */

#ifndef TEXT_MODE_VGA_H_
#define TEXT_MODE_VGA_H_

#include <system.h>
#include <alt_types.h>

#define COLUMNS 80
#define ROWS 30

//define some colors
#define WHITE 		0xFFF
#define BRIGHT_RED 	0xF00
#define DIM_RED    	0x700
#define BRIGHT_GRN	0x0F0
#define DIM_GRN		0x070
#define BRIGHT_BLU  0x00F
#define DIM_BLU		0x007
#define GRAY		0x777
#define BLACK		0x000

struct TEXT_VGA_STRUCT {
	alt_u8 VRAM [ROWS*COLUMNS];
	alt_u32 CTRL;
};

//you may have to change this line depending on your platform designer
static volatile struct TEXT_VGA_STRUCT* vga_ctrl = VGA_TEXT_MODE_CONTROLLER_0_BASE;

void textVGASetColor(int background, int foreground);
void textVGAClr();
void textVGATest();

#endif /* TEXT_MODE_VGA_H_ */
