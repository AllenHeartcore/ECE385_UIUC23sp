#include <stdio.h>
#include "system.h"
#include "altera_avalon_spi.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"
#include "sys/alt_irq.h"

#include "usb_kb/GenericMacros.h"
#include "usb_kb/GenericTypeDefs.h"
#include "usb_kb/HID.h"
#include "usb_kb/MAX3421E.h"
#include "usb_kb/transfer.h"
#include "usb_kb/usb_ch9.h"
#include "usb_kb/USB.h"
#include "tptp.h"



extern HID_DEVICE hid_device;
static BYTE addr = 1;
const char* const devclasses[] = {
	"Uninitialized", "HID Keyboard", "HID Mouse", "Mass storage" };



BYTE GetDriverandReport() {

	BYTE i;
	BYTE rcode;
	BYTE device = 0xFF;
	BYTE tmpbyte;
	DEV_RECORD* tpl_ptr;

	printf("Reached USB_STATE_RUNNING (0x40)\n");
	for (i = 1; i < USB_NUMDEVICES; i++) {
		tpl_ptr = GetDevtable(i);
		if (tpl_ptr->epinfo != NULL) {
			printf("Device: %d", i);
			printf("%s \n", devclasses[tpl_ptr->devclass]);
			device = tpl_ptr->devclass;
		}
	}

	rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
	if (rcode) {
		printf("GetIdle Error. Error code: ");
		printf("%x \n", rcode);
	} else {
		printf("Update rate: ");
		printf("%d \n", tmpbyte);
	}
	printf("Protocol: ");

	rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
	if (rcode) {
		printf("GetProto Error. Error code ");
		printf("%x \n", rcode);
	} else {
		printf("%d \n", tmpbyte);
	}

	return device;
}



void setLED(int LED) {
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE,
		(IORD_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE) | (0x001 << LED)));
}



void clearLED(int LED) {
	IOWR_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE,
		(IORD_ALTERA_AVALON_PIO_DATA(PIO_LED_BASE) & ~(0x001 << LED)));

}



void printSignedHex0(signed char value) {
	BYTE tens = 0;
	BYTE ones = 0;
	WORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(PIO_HEX_BASE);
	if (value < 0) {
		setLED(11);
		value = -value;
	} else {
		clearLED(11);
	}
	if (value / 100)
		setLED(13);
	else
		clearLED(13);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0x00FF;
	pio_val |= (tens << 12);
	pio_val |= (ones << 8);

	IOWR_ALTERA_AVALON_PIO_DATA(PIO_HEX_BASE, pio_val);
}



void printSignedHex1(signed char value) {
	BYTE tens = 0;
	BYTE ones = 0;
	DWORD pio_val = IORD_ALTERA_AVALON_PIO_DATA(PIO_HEX_BASE);
	if (value < 0) {
		setLED(10);
		value = -value;
	} else {
		clearLED(10);
	}
	if (value / 100)
		setLED(12);
	else
		clearLED(12);

	value = value % 100;
	tens = value / 10;
	ones = value % 10;
	tens = value / 10;
	ones = value % 10;

	pio_val &= 0xFF00;
	pio_val |= (tens << 4);
	pio_val |= (ones << 0);

	IOWR_ALTERA_AVALON_PIO_DATA(PIO_HEX_BASE, pio_val);
}




/* -------------------- CANVAS REGISTER UTILITIES -------------------- */

void setKeyReg(int idx) {
	vga_ctrl[idx] = (
		(keystats[idx].brght & 0x7) << 5 |
		(keystats[idx].color & 0x3) << 3 |
		(keystats[idx].nsize & 0x7)
	);
}

void setScoreReg() {
	vga_ctrl[0]  = (BYTE) ( score & 0xFF);
	vga_ctrl[1]  = (BYTE) ((score >> 8) & 0xFF);
	vga_ctrl[2]  = (BYTE) ((score >> 16) & 0xFF);
}

void setAccReg() {
	int pacc = (int) (acc * 0xFFFF);
	vga_ctrl[3]  = (BYTE) ( pacc & 0xFF);
	vga_ctrl[4]  = (BYTE) ((pacc >> 8) & 0xFF);
}

void setComboReg() {
	vga_ctrl[62] = (BYTE) ( combo & 0xFF);
	vga_ctrl[63] = (BYTE) ((combo >> 8) & 0xFF);
}

void setPureFarRegs() {
	int npuret = nmpure + npure;
	vga_ctrl[56] = (BYTE) ( npuret & 0xFF);
	vga_ctrl[57] = (BYTE) ((npuret >> 8) & 0xFF);
	vga_ctrl[58] = (BYTE) ( nfar & 0xFF);
	vga_ctrl[59] = (BYTE) ((nfar >> 8) & 0xFF);
	setScoreReg();
	setAccReg();
	setComboReg();
}

void setLostRegs() {
	vga_ctrl[60] = (BYTE) ( nlost & 0xFF);
	vga_ctrl[61] = (BYTE) ((nlost >> 8) & 0xFF);
	setScoreReg();
	setAccReg();
	setComboReg();
}

/* ----------------- CANVAS REGISTER UTILITIES: DONE ----------------- */



/* ----------------- SCOREKEEPER & KEYSTAT UTILITIES ----------------- */

void setPureFarScorekeepers(int error, char *msg) {
	if (error < THRES_PURE) {
		nmpure++;
		strcpy(msg, "Pure");
	} else if (error < THRES_FAR) {
		npure++;
		strcpy(msg, "Pure");
	} else {
		nfar++;
		strcpy(msg, "Far");
	}
	combo++;
	maxcombo = combo > maxcombo ? combo : maxcombo;
	score = MAX_SCORE / (float)(tnkey) \
		* (nmpure + npure + nfar * 0.5) + nmpure;
	tacc += 1 - error / (float)THRES_LOST;
	acc = tacc / (nmpure + npure + nfar + nlost);
}

void setLostScorekeepers() {
	nlost++;
	combo = 0;
	acc = tacc / (nmpure + npure + nfar + nlost);
}

void setEnterKeystat(int idx, int timestamp) {
	keystats[idx].brght = BRIGHTEST;
	keystats[idx].color = COLOR_TOUCH;
	keystats[idx].nsize = 1;
	keystats[idx].phase = PHASE_ENTER;
	keystats[idx].timestamp = timestamp;
}

void setTouchKeystat(int idx) {
	keystats[idx].brght = BRIGHTEST;
	keystats[idx].color = COLOR_TOUCH;
	keystats[idx].nsize = 0;
	keystats[idx].phase = PHASE_EXIT;
}

void setPureKeystat(int idx, int error) {
	keystats[idx].brght = BRIGHTEST;
	keystats[idx].color = COLOR_PURE;
	if (error >= 0)
		keystats[idx].nsize = LARGEST * (1 - error / (float)THRES_LOST);
	else
	 	keystats[idx].nsize = LARGEST;
	keystats[idx].phase = PHASE_EXIT;
}

void setFarKeystat(int idx, int error) {
	keystats[idx].brght = BRIGHTEST;
	keystats[idx].color = COLOR_FAR;
	if (error >= 0)
		keystats[idx].nsize = LARGEST * (1 - error / (float)THRES_LOST);
	else
	 	keystats[idx].nsize = LARGEST;
	keystats[idx].phase = PHASE_EXIT;
}

void setLostKeystat(int idx) {
	keystats[idx].brght = BRIGHTEST;
	keystats[idx].color = COLOR_LOST;
	keystats[idx].nsize = LARGEST;
	keystats[idx].phase = PHASE_EXIT;
}

void updateKeystats() {
	for (int i = KEYCODE_MIN; i < KEYCODE_MAX; i++) {
		setKeyReg(i);
		if (keystats[i].phase == PHASE_ENTER) {
			if (keystats[i].nsize < LARGEST) {
				int timediff = keystats[i].timestamp - gametime;
				keystats[i].nsize =
					LARGEST * (1 - timediff / (float)THRES_LOST);
			} else
			 	keystats[i].phase = PHASE_EXIT;
		} else if (keystats[i].phase == PHASE_EXIT) {
			if (keystats[i].brght > 0)
				keystats[i].brght--;
			else
				keystats[i].phase = PHASE_IDLE;
		}
	}
	int inote = 0;
	while (inote < nkey && chart[inote].time <= gametime + THRES_LOST) {
		int inote_key = chart[inote].key;
		if (keystats[inote_key].phase == PHASE_IDLE) {
			setEnterKeystat(inote_key, chart[inote].time);
		}
		inote++;
	}
}

/* -------------- SCOREKEEPER & KEYSTAT UTILITIES: DONE -------------- */



note_t pop_note(note_t *chart, int idx, int *nkey) {
	note_t note = chart[idx];
	for (int i = idx; i < *nkey - 1; i++)
		chart[i] = chart[i + 1];
	chart[*nkey] = (note_t){0, 0};
	(*nkey)--;
	return note;
}



int main() {

	BYTE rcode, device;
	BOOT_KBD_REPORT kbdbuf;
	BYTE runningdebugflag = 0;
	BYTE errorflag = 0;

	printf("initializing MAX3421E...\n");
	MAX3421E_init();
	printf("initializing USB...\n");
	USB_init();



/* ----------------------- GAME INITIALIZATION ----------------------- */

	gettimeofday(&start, NULL);
	for (int i = 0; i < NREG; i++) {
		keystats[i].nsize = 0;
		keystats[i].color = 0;
		keystats[i].brght = 0;
		keystats[i].phase = PHASE_IDLE;
	}

/* -------------------- GAME INITIALIZATION: DONE -------------------- */



	while (1) {
		MAX3421E_Task();
		USB_Task();

		if (GetUsbTaskState() == USB_STATE_RUNNING) {
			if (!runningdebugflag) {
				runningdebugflag = 1;
				setLED(9);
				device = GetDriverandReport();
			} else if (device == 1) {
				rcode = kbdPoll(&kbdbuf);
				if (rcode == hrNAK) {
					continue;
				} else if (rcode) {
					printf("Rcode: ");
					printf("%x \n", rcode);
					continue;
				}



/* -------------------- KEYCODE-DRIVEN GAME LOGIC -------------------- */

				printf("---------- TrapoTempo now starts ----------\n");
				while (1) {
					kbdPoll(&kbdbuf);

					/* Touch */
					for (int i = 0; i < 6; i++) {
						int8_t key = (int8_t)kbdbuf.keycode[i];
						if (key > 0) {
							touches[ntouch++] = (note_t){gametime, key};
							// LOG(gametime, "Touch", key);
							setTouchKeystat(key);
						}
					}

					if (nkey) {
						gettimeofday(&now, NULL);
						gametime = ROUND((now.tv_sec - start.tv_sec) * 500 + \
										(now.tv_usec - start.tv_usec) / 2000);

						/* Lost */
						while (nkey && chart[0].time <= gametime - THRES_LOST) {
							setLostScorekeepers();
							setLostKeystat(chart[0].key);
							setLostRegs();
							note_t note = pop_note(chart, 0, &(nkey));
							LOG(note.time + THRES_LOST, "Lost", valid_keys[note.key]);
						}

						while (ntouch && touches[0].time <= gametime - THRES_LOST) {
							pop_note(touches, 0, &ntouch);
						}

						while (ntouch && touches[0].time < gametime) {
							note_t touch = pop_note(touches, 0, &ntouch);
							int min_error = THRES_LOST, best_i = -1;

							for (int i = 0; i < nkey; i++) {
								int error = touch.time - chart[i].time;
								if (abs(error) > THRES_LOST)
									break;
								else if (chart[i].key == touch.key) {
									min_error = error;
									best_i = i;
								}
							}

							/* Hit */
							if (best_i != -1) {
								char msg[5] = {0};
								setPureFarScorekeepers(abs(min_error), msg);
								if (min_error < THRES_FAR)
									setPureKeystat(chart[best_i].key, min_error);
								else
									setFarKeystat(chart[best_i].key, min_error);
								setPureFarRegs();
								pop_note(chart, best_i, &(nkey));
								LOG(touch.time, msg, valid_keys[touch.key]);

							/* Mistouch */
							} else {
								// LOG(touch.time, "Mistouch", valid_keys[touch.key]);
							}
						}
					}

					updateKeystats();
					printSignedHex0(kbdbuf.keycode[0]);
					printSignedHex1(kbdbuf.keycode[1]);
				}

/* ----------------- KEYCODE-DRIVEN GAME LOGIC: DONE ----------------- */



			}

		} else if (GetUsbTaskState() == USB_STATE_ERROR) {
			if (!errorflag) {
				errorflag = 1;
				clearLED(9);
				printf("USB Error State\n");
			}

		} else {
			printf("USB task state: ");
			printf("%x\n", GetUsbTaskState());
			if (runningdebugflag) {
				runningdebugflag = 0;
				MAX3421E_init();
				USB_init();
			}
			errorflag = 0;
			clearLED(9);
		}

	}

}
