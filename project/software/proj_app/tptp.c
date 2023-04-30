#include <stdio.h>
#include "system.h"
#include "altera_avalon_spi.h"
#include "altera_avalon_spi_regs.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_i2c.h"
#include "altera_avalon_i2c_regs.h"
#include "sys/alt_irq.h"

#include "usb_kb/GenericMacros.h"
#include "usb_kb/GenericTypeDefs.h"
#include "usb_kb/HID.h"
#include "usb_kb/MAX3421E.h"
#include "usb_kb/transfer.h"
#include "usb_kb/usb_ch9.h"
#include "usb_kb/USB.h"
#include "audio/GenericTypeDefs.h"
#include "audio/sgtl5000.h"
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


void setScoreHex() {
	BYTE digit;
	int value = score;
	DWORD pio_val = 0x000000;

	for (int i = 0; i < 8; i++) {
		digit = value % 10;
		value /= 10;
		pio_val >>= 4;
		pio_val |= (digit << 20);
	}

	IOWR_ALTERA_AVALON_PIO_DATA(PIO_HEX_BASE, pio_val);
}


void setGamestateReg() {
	vga_ctrl[KEYCODE_GST] = (BYTE) (gst_state | (gst_fig & 0x03));
}

void setLifeReg() {
	vga_ctrl[KEYCODE_LFE] = (BYTE) life;
}

void setSkillReg() {
	vga_ctrl[KEYCODE_SKL] = (BYTE) skill;
}

void deltaLife(int8_t delta) {
	if (delta > 0)
		life = (life + delta > LIFE_MAX) ? LIFE_MAX : life + delta;
	else
		life = (life + delta < LIFE_MIN) ? LIFE_MIN : life + delta;
	setLifeReg();
}

void deltaSkill(int8_t delta) {
	if (delta > 0)
		skill = (skill + delta > SKILL_MAX) ? SKILL_MAX : skill + delta;
	else
		skill = (skill + delta < SKILL_MIN) ? SKILL_MIN : skill + delta;
	setSkillReg();
}


void setKeyReg(int idx) {
	vga_ctrl[idx] = (BYTE) (
		(keystats[idx].brght & 0x7) << 5 |
		(keystats[idx].color & 0x3) << 3 |
		(keystats[idx].nsize & 0x7)
	);
}

void setScoreReg() {
	vga_ctrl[0]  = (BYTE) ( score & 0xFF);
	vga_ctrl[1]  = (BYTE) ((score >> 8) & 0xFF);
	vga_ctrl[2]  = (BYTE) ((score >> 16) & 0xFF);
	setScoreHex();
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

void setMaxComboReg() {
	vga_ctrl[62] = (BYTE) ( maxcombo & 0xFF);
	vga_ctrl[63] = (BYTE) ((maxcombo >> 8) & 0xFF);
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


void setPureFarScorekeepers(int error, char *msg) {

	float dscore_boost = 0.0;

	if (error < THRES_FAR ||
	(!(skill & 0x01) && gst_fig == 3)) {			// turns FAR into PURE
		if (error < THRES_PURE) nmpure++;
		else npure++;
		strcpy(msg, "Pure");
		deltaLife(DLIFE_PURE);
		if (!(skill & 0x01)) {
			if (gst_fig == 0)
				dscore_boost = SCORE_BOOST_FIG0;	// score +20% for PURE
			else if (gst_fig == 2)
				dscore_boost = SCORE_BOOST_FIG2;	// score +30% for PURE
		} else {
			deltaSkill(DSKILL_PURE);
		}

	} else {
		nfar++;
		strcpy(msg, "Far");
		deltaLife(DLIFE_FAR);
		if (!(skill & 0x01) && gst_fig == 0) {
			dscore_boost = SCORE_BOOST_FIG0 * 0.5;	// score +20% for FAR
		} else {
			deltaSkill(DSKILL_FAR);
		}
	}

	combo++;
	maxcombo = combo > maxcombo ? combo : maxcombo;
	score_base = MAX_SCORE / (float)(tnkey)
		* (nmpure + npure + nfar * 0.5) + nmpure;
	score_boost += MAX_SCORE / (float)(tnkey) * dscore_boost;
	score = (score_base + score_boost);
	tacc += 1 - error / (float)THRES_LOST;
	acc = tacc / (nmpure + npure + nfar + nlost);
	setPureFarRegs();
}

void setLostScorekeepers() {
	nlost++;
	combo = 0;
	acc = tacc / (nmpure + npure + nfar + nlost);
	deltaLife(DLIFE_LOST);
	setLostRegs();
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
		if (i == KEYCODE_GST || i == KEYCODE_LFE || i == KEYCODE_SKL)
			continue;
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


note_t pop_note(note_t *chart, int idx, int *nkey) {
	note_t note = chart[idx];
	for (int i = idx; i < *nkey - 1; i++)
		chart[i] = chart[i + 1];
	chart[*nkey] = (note_t){0, 0};
	(*nkey)--;
	return note;
}


void game_init() {

	nkey = NKEY;
	tnkey = NKEY;

	score = 0;
	score_base = 0;
	score_boost = 0;
	acc = 0;
	tacc = 0;

	nmpure = 0;
	npure = 0;
	nfar = 0;
	nlost = 0;
	ntouch = 0;
	combo = 0;
	maxcombo = 0;

	life = LIFE_MAX;
	skill = SKILL_MIN;

	setPureFarRegs();
	setLostRegs();
	setLifeReg();
	setSkillReg();

	gettimeofday(&start, NULL);
	for (int i = 0; i < NREG; i++) {
		keystats[i].nsize = 0;
		keystats[i].color = 0;
		keystats[i].brght = 0;
		keystats[i].phase = PHASE_IDLE;
	}
	for (int i = 0; i < NKEY; i++) {
		chart[i] = chart_storage[i];
	}

	printf("------ TrapoTempo now starts ------\n");
}


void game() {

	BOOT_KBD_REPORT kbdbuf;

	while (1) {
		kbdPoll(&kbdbuf);

		/* Touch */
		for (int i = 0; i < 6; i++) {
			int8_t key = (int8_t)kbdbuf.keycode[i];
			int gst_update = 0;

			if (key == KEYCODE_ESC) {	// global escape
				gst_state = GST_IDLE;
				gst_fig = 0;
				gst_update = 1;

			} else if (
				(gst_state == GST_IDLE || gst_state == GST_REPORT) &&
				key == KEYCODE_ENTER) {
				gst_state = GST_CONFIG;
				gst_update = 1;

			} else if (gst_state == GST_CONFIG) {
				if (key == KEYCODE_ENTER) {
					game_init();
					gst_state = GST_PLAY;
					gst_update = 1;
				} else if (key == KEYCODE_LEFT) {
					gst_fig = (gst_fig - 1) & 0x03;
					gst_update = 1;
				} else if (key == KEYCODE_RIGHT) {
					gst_fig = (gst_fig + 1) & 0x03;
					gst_update = 1;
				}

			} else if (gst_state == GST_PLAY) {
				if (key == KEYCODE_SPACE && skill == SKILL_MAX) {
					if (gst_fig == 1) {	// instantly recovers 30% of life
						deltaLife(DLIFE_BOOST);
						skill = SKILL_MIN;
						setSkillReg();
					} else {
						skill -= 1;		// even skill value = ON
					}
				} else {
					touches[ntouch++] = (note_t){gametime, key};
					setTouchKeystat(key);
				}
			}

			if (gst_update) setGamestateReg();
		}

		if (gst_state != GST_PLAY) continue;

		if (nkey && life > 0) {
			gettimeofday(&now, NULL);
			gametime = ROUND((now.tv_sec - start.tv_sec) * 500 +
							(now.tv_usec - start.tv_usec) / 2000);

			/* Lost */
			while (nkey && chart[0].time <= gametime - THRES_LOST) {
				setLostScorekeepers();
				setLostKeystat(chart[0].key);
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
					pop_note(chart, best_i, &(nkey));
					LOG(touch.time, msg, valid_keys[touch.key]);
				}

			}
		} else {
			gst_state = GST_REPORT;
			setMaxComboReg();
			setGamestateReg();
		}
		updateKeystats();
		deltaLife(DLIFE_TICK);
		if (!(skill & 0x1)) deltaSkill(DSKILL_TICK);
	}
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
	printf("initializing SGTL5000...\n");
	SGTL5000_init();

	while (1) {
		MAX3421E_Task();
		USB_Task();

		if (GetUsbTaskState() == USB_STATE_RUNNING) {
			if (!runningdebugflag) {
				runningdebugflag = 1;
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
				game();
			}

		} else if (GetUsbTaskState() == USB_STATE_ERROR) {
			if (!errorflag) {
				errorflag = 1;
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
		}

	}

}
