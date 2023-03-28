#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <system.h>
#include <alt_types.h>
#include "vga_text.h"


void textVGAClr() {
	for (int i = 0; i < ROWS * COLS; i++) {
		vga_ctrl->VRAM[i] = 0x00;
	}
}

void textVGASetColor(int background, int foreground) {
	vga_ctrl->CTRL = foreground << 13 | background << 1;
}

void textVGATest() {

	textVGASetColor(BLACK, WHITE);
	textVGAClr();
	alt_u32 checksum[ROWS], readsum[ROWS];

	for (int i = 0; i < ROWS; i++) {
		checksum[i] = 0;
		for (int j = 0; j < COLS; j++) {
			vga_ctrl->VRAM[i * COLS + j] = i + j;
			checksum[i] += i + j;
		}
	}

	for (int i = 0; i < ROWS; i++) {
		readsum[i] = 0;
		for (int j = 0; j < COLS; j++) {
			readsum[i] += vga_ctrl->VRAM[i * COLS + j];
		}
		printf("Row: %d, Checksum: %x, Read-back Checksum: %x\n\r", i, checksum[i], readsum[i]);
		if (checksum[i] != readsum[i]) {
			printf ("Checksum mismatch! Check your Avalon-MM code\n\r");
			while (1);
		}
	}
	printf ("Checksum code passed! Starting color test\n\r");
	usleep(500000);

	textVGASetColor(DIM_GRN, BRIGHT_GRN);
	textVGAClr();
	char greentest[] = "This text should draw in green";
	for (int i = 0; i < ROWS; i++) {
		memcpy((void *)&vga_ctrl->VRAM[i * COLS] + i, greentest, sizeof(greentest));
	}
	usleep(500000);

	textVGASetColor(DIM_RED, BRIGHT_RED);
	textVGAClr();
	char redtest[] = "This text should draw in red";
	for (int i = 0; i < ROWS; i++) {
		memcpy((void *)&vga_ctrl->VRAM[i * COLS] + (ROWS - i), redtest, sizeof(redtest));
	}
	usleep(500000);

	textVGASetColor(DIM_BLU, BRIGHT_BLU);
	textVGAClr();
	char blutest[] = "This text should draw in blue";
	for (int i = 0; i < ROWS; i++) {
		memcpy((void *)&vga_ctrl->VRAM[i * COLS], blutest, sizeof(blutest));
	}
	usleep(500000);

	textVGAClr();
	char inverted[] = "This text should draw inverted";
	for (int i = 0; i < sizeof(inverted); i++)
		inverted[i] |= 0x80;
	textVGASetColor(DIM_GRN, BRIGHT_GRN);
	for (int i = 0; i < ROWS; i++) {
		if (i % 2 == 0)
			memcpy((void *)&vga_ctrl->VRAM[i * COLS] + i, greentest, sizeof(greentest));
		else
			memcpy((void *)&vga_ctrl->VRAM[i * COLS] + i, inverted, sizeof(inverted));
	}
	usleep(500000);

	textVGASetColor(BLACK, WHITE);
	textVGAClr();
	char completed[] = "All visual tests completed, verify on-screen results are correct.";
	memcpy((void *)&vga_ctrl->VRAM[0], completed, sizeof(completed));
	printf("%s\n\r", completed);
	usleep(1000000);

}
