// #define BLINKING_TEST

int main() {

	volatile unsigned int *LED_PIO  = (unsigned int*)0x130;

#ifdef BLINKING_TEST

	*LED_PIO = 0;
	while (1) {
		for (int i = 0; i < 100000; i++);
		*LED_PIO |= 0x1;
		for (int i = 0; i < 100000; i++);
		*LED_PIO &= ~0x1;
	}

#else

#define IDLE 0
#define EXEC 1
#define DONE 2

	volatile unsigned int *SW_PIO   = (unsigned int*)0x120;
	volatile unsigned int *KEY1_PIO = (unsigned int*)0x110;
	// volatile unsigned int *HEX0_PIO = (unsigned int*)0x100;
	// volatile unsigned int *HEX1_PIO = (unsigned int*)0x0B0;
	// volatile unsigned int *HEX2_PIO = (unsigned int*)0x0C0;
	// volatile unsigned int *HEX3_PIO = (unsigned int*)0x0D0;
	// volatile unsigned int *HEX4_PIO = (unsigned int*)0x0E0;
	// volatile unsigned int *HEX5_PIO = (unsigned int*)0x0F0;

	*LED_PIO = 0;
	int state = IDLE;
	while (1) {
		switch (state) {
		case IDLE:
			if (!*KEY1_PIO) state = EXEC;
			break;
		case EXEC:
			*LED_PIO += *SW_PIO;
			state = DONE;
			break;
		case DONE:
			if (*KEY1_PIO) state = IDLE;
			break;
		}
	}
	
#endif

	return 1;
}
