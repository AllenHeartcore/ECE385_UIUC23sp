#ifndef TPTP_H
#define TPTP_H

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <system.h>



/* Statistics & Timing */

#define MAX_NKEY	65535
#define MAX_SCORE	10000000
#define THRES_PURE	50	// 100 ms
#define THRES_FAR	100	// 200 ms
#define THRES_LOST	200	// 400 ms
#define VALID_KEYS	"     bcdefghijklmnop rstuvwxy  234567890     -=[   ;  ,."

typedef struct {
	uint16_t time;
	int8_t key;
} note_t;

typedef struct {
	long tv_sec;
	long tv_usec;
} timeval_t;

int gametime;
timeval_t start, now;



/* Chart */

#define NKEY 72

note_t chart[NKEY];

note_t chart_storage[NKEY] = {
	{  750, 22}, {  938,  7}, { 1125,  9}, { 1219, 10},
	{ 1406, 11}, { 1594, 13}, { 1781, 14}, { 1875, 15},
	{ 2063, 51}, { 2250, 19}, { 2438, 18}, { 2625, 12},
	{ 2719, 24}, { 2906, 28}, { 3094, 23}, { 3281, 21},
	{ 3375,  8}, { 3563, 26}, { 3750, 22}, { 3938,  7},
	{ 4125,  9}, { 4219, 10}, { 4406, 11}, { 4594, 13},
	{ 4781, 14}, { 4875, 15}, { 5063, 51}, { 5250, 19},
	{ 5438, 18}, { 5625, 12}, { 5719, 24}, { 5906, 28},
	{ 6094, 23}, { 6281, 21}, { 6375,  8}, { 6563, 26},
	{ 6750, 22}, { 6938,  7}, { 7125,  9}, { 7219, 10},
	{ 7406, 11}, { 7594, 13}, { 7781, 14}, { 7875, 15},
	{ 8063, 51}, { 8250, 19}, { 8438, 18}, { 8625, 12},
	{ 8719, 24}, { 8906, 28}, { 9094, 23}, { 9281, 21},
	{ 9375,  8}, { 9563, 26}, { 9750, 22}, { 9938,  7},
	{10125,  9}, {10219, 10}, {10406, 11}, {10594, 13},
	{10781, 14}, {10875, 15}, {11063, 51}, {11250, 19},
	{11438, 18}, {11625, 12}, {11719, 24}, {11906, 28},
	{12094, 23}, {12281, 21}, {12375,  8}, {12563, 26},
};



/* Scorekeeper */

#define GST_IDLE    0x00
#define GST_CONFIG  0x04
#define GST_PLAY    0x08
#define GST_REPORT  0x0C

#define DLIFE_TICK  1
#define DLIFE_PURE  12
#define DLIFE_FAR   6
#define DLIFE_LOST  -16
#define DLIFE_BOOST 75
#define LIFE_MAX    255
#define LIFE_MIN    0

#define DSKILL_PURE 24
#define DSKILL_FAR  12
#define DSKILL_TICK -8
#define SKILL_MAX   255
#define SKILL_MIN   1
#define SCORE_BOOST_FIG0 0.2
#define SCORE_BOOST_FIG2 0.3

char valid_keys[64] = VALID_KEYS;
note_t touches[MAX_NKEY] = {0};

int nmpure, npure, nfar, nlost, ntouch;
int score, score_base, score_boost;
int combo, maxcombo, nkey, tnkey;
float acc, tacc;

uint8_t gst_state = GST_IDLE, gst_fig = 0;
int16_t life, skill; // odd = OFF, even = ON



/* VGA Register Programming */

#define COLOR_TOUCH 0
#define COLOR_LOST  1
#define COLOR_FAR   2
#define COLOR_PURE  3
#define LARGEST     7
#define BRIGHTEST   7
#define PHASE_IDLE  0
#define PHASE_ENTER 1
#define PHASE_EXIT  2

#define NREG            64
#define KEYCODE_MIN     5
#define KEYCODE_MAX     55
#define KEYCODE_FLG     48
#define KEYCODE_LFE     49
#define KEYCODE_SKL     50
#define KEYCODE_SDRAM_ADDR  40
#define KEYCODE_SDRAM_DATA  43

#define FLGMASK_PLY     0x10

#define KEYCODE_ENTER   40
#define KEYCODE_ESC     41
#define KEYCODE_LEFT    80
#define KEYCODE_RIGHT   79
#define KEYCODE_SPACE   44

typedef struct {
	uint8_t nsize;
	uint8_t color;
	uint8_t brght;
	uint8_t phase;
	int timestamp;
} keystat_t;

int sdram_addr, sdram_addr_prev;
keystat_t keystats[NREG];
static volatile alt_u8* game_ctrl  = (alt_u8*)GAME_BASE;
static volatile alt_u8* sdram_base = (alt_u8*)SDRAM_BASE;



/* Misc Utils */

#define ASSERT(stmt, msg)		\
do {							\
	if (!(stmt)) {				\
		printf("%s\n", (msg));	\
		exit(1);				\
	}							\
} while (0)

#define ROUND(num) (int)((num) + 0.5)

#define LOG(time, msg, key) \
	printf("[Time %5d | Score %08d, Accuracy %5.2f%% | Pure %4d, Far %4d, Lost %4d, Combo %4d, Life %3d, Skill %3d] %s %c\n", \
	(time), score, acc * 100, nmpure + npure, nfar, nlost, combo, life, skill, (msg), (key));


#endif
