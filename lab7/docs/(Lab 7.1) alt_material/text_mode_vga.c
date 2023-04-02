/*
 * text_mode_vga.c
 * Minimal driver for text mode VGA support
 *
 *  Created on: Jul 17, 2021
 *      Author: zuofu
 */

#include <system.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <alt_types.h>
#include "text_mode_vga.h"


void textVGASetColor(int background, int foreground)
{
	vga_ctrl->CTRL = foreground << 13 |
					 background << 1;
}

void textVGAClr()
{
	for (int i = 0; i<(ROWS*COLUMNS); i++)
	{
		vga_ctrl->VRAM[i] = 0x00;
	}
}

void textVGATest()
{
	textVGASetColor(BLACK, WHITE);
	textVGAClr();

	//Register write and readback test
	alt_u32 checksum[ROWS], readsum[ROWS];

	for (int j = 0; j < ROWS; j++)
	{
		checksum[j] = 0;
		for (int i = 0; i < COLUMNS; i++)
		{
			vga_ctrl->VRAM[j*COLUMNS + i] = i + j;
			checksum[j] += i + j;
		}
	}
	for (int j = 0; j < ROWS; j++)
	{
		readsum[j] = 0;
		for (int i = 0; i < COLUMNS; i++)
		{
			readsum[j] += vga_ctrl->VRAM[j*COLUMNS + i];
			//printf ("%x \n\r", vga_ctrl->VRAM[j*COLUMNS + i]);
		}
		printf ("Row: %d, Checksum: %x, Read-back Checksum: %x\n\r", j, checksum[j], readsum[j]);
		if (checksum[j] != readsum[j])
		{
			printf ("Checksum mismatch!, check your Avalon-MM code\n\r");
			while (1){};
		}
	}
	printf ("Checksum code passed!...starting color test \n\r");
	usleep (500000);
	textVGASetColor(DIM_GRN, BRIGHT_GRN);
	textVGAClr();
	char greentest[] = "This text should draw in green";
	{
		for (int j = 0; j < ROWS; j++)
		{
			memcpy((void*)&vga_ctrl->VRAM[j*COLUMNS]+j,greentest, sizeof(greentest));
		}
	}
	usleep (500000);
	textVGASetColor(DIM_RED, BRIGHT_RED);
	textVGAClr();
	char redtest[] = "This text should draw in red";
	{
		for (int j = 0; j < ROWS; j++)
		{
			memcpy((void*)&vga_ctrl->VRAM[j*COLUMNS]+(ROWS-j),redtest, sizeof(redtest));
		}
	}
	usleep (500000);
	textVGASetColor(DIM_BLU, BRIGHT_BLU);
	textVGAClr();
	char blutest[] = "This text should draw in blue";
	{
		for (int j = 0; j < ROWS; j++)
		{
			memcpy((void*)&vga_ctrl->VRAM[j*COLUMNS],blutest, sizeof(blutest));
		}
	}
	usleep (500000);
	textVGAClr();
	char inverted[] = "This text should draw inverted";
	for (int i = 0; i < sizeof(inverted); i++)
		inverted[i] |= 0x80;

	textVGASetColor(DIM_GRN, BRIGHT_GRN);
	{
		for (int j = 0; j < ROWS; j++)
		{
			if (j%2==0)
				memcpy((void*)&vga_ctrl->VRAM[j*COLUMNS]+j,greentest, sizeof(greentest));
			else
				memcpy((void*)&vga_ctrl->VRAM[j*COLUMNS]+j,inverted, sizeof(inverted));
		}
	}
	usleep (500000);

	textVGASetColor(BLACK, WHITE);
	textVGAClr();

	char completed[] = "All visual tests completed, verify on-screen results are correct.";
	memcpy((void*)&vga_ctrl->VRAM[0],completed, sizeof(completed));
	printf( "%s \n\r", completed);

	usleep (1000000);

}
