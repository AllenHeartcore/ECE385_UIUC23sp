#include <time.h>
#include <termios.h>
#include <sys/ioctl.h>
#include "tptp.h"


#define MAX_SCORE 10000000
#define THRES_PURE 12	// 24 ms
#define THRES_FAR  25	// 50 ms
#define THRES_MISS 50	// 100 ms
#define STDIN_FILENO 0

#define LOG(time, msg, key) \
	printf("[Time %5d | Score %08d, Accuracy %5.2f%% | Pure %4d, Far %4d, Miss %4d, Combo %4d] %s %c\n", \
	(time), score, acc * 100, nmpure + npure, nfar, nmiss, combo, (msg), (key));


note_t pop_note(note_t *chart, int idx, int *nkey) {
	note_t note = chart[idx];
	for (int i = idx; i < *nkey - 1; i++)
		chart[i] = chart[i + 1];
	chart[*nkey] = (note_t){0, 0};
	(*nkey)--;
	return note;
}


int simtpch(char* path) {

	/* Open chart */
	uint32_t magic, nkey;
	note_t chart[MAX_NKEY] = {0};
	FILE *tpch = fopen(path, "r");
	ASSERT(tpch, "Failed to open TrapoChart");
	ASSERT(fread(&magic, sizeof(uint32_t), 1, tpch) == 1, \
		"Failed to read TrapoChart header");
	ASSERT(magic == MAGIC_TPCH, "Invalid TrapoChart");
	ASSERT(fread(&nkey, sizeof(uint32_t), 1, tpch) == 1, \
		"Failed to read TrapoChart header");
	ASSERT(nkey > 0 && nkey <= MAX_NKEY, \
		"Invalid number of keys");
	ASSERT(fread(chart, sizeof(note_t), nkey, tpch) == nkey, \
		"Failed to read TrapoChart");
	fclose(tpch);

	/* Config terminal */
	int attr = 1;
	struct termios oldt, newt;
	tcgetattr(STDIN_FILENO, &oldt);
	newt = oldt;
	newt.c_lflag &= ~(ICANON | ECHO);
	tcsetattr(STDIN_FILENO, TCSANOW, &newt);
	ioctl(STDIN_FILENO, FIONBIO, &attr);

	/* Config clock */
	int gametime;
	struct timespec start, now;
	printf("------------ TrapoTempo Simulator now starts ------------\n");
	clock_gettime(CLOCK_MONOTONIC, &start);

	/* Scorekeeper */
	note_t touches[MAX_NKEY] = {0};
	int nmpure = 0, npure = 0, nfar = 0, nmiss = 0, ntouch = 0;
	int score = 0, combo = 0, maxcombo = 0, tnkey = nkey;
	float acc = 0, tacc;
	char valid_keys[MAX_LPHRASE] = VALID_KEYS;

	/* Game loop */
	while (nkey) {
		clock_gettime(CLOCK_MONOTONIC, &now);
		gametime = UNIT(now) - UNIT(start);
		char chr = getchar();

		/* Touch */
		if (chr > 0) {
			touches[ntouch++] = (note_t){gametime, chr};
			// LOG(gametime, "Touch", chr);
		}

		/* Miss */
		while (nkey && chart[0].time <= gametime - THRES_MISS) {
			nmiss++;
			combo = 0;
			acc = tacc / (nmpure + npure + nfar + nmiss);
			note_t note = pop_note(chart, 0, &(nkey));
			LOG(note.time + THRES_MISS, "Miss", valid_keys[note.key]);
		}

		while (ntouch && touches[0].time <= gametime - THRES_MISS) {
			pop_note(touches, 0, &ntouch);
		}

		while (ntouch && touches[0].time < gametime) {
			note_t touch = pop_note(touches, 0, &ntouch);
			int min_error = THRES_MISS, best_i = -1;

			for (int i = 0; i < nkey; i++) {
				int error = abs(touch.time - chart[i].time);
				if (error > THRES_MISS)
					break;
				else if (chart[i].key == touch.key) {
					min_error = error;
					best_i = i;
				}
			}

			/* Hit */
			if (best_i != -1) {
				char msg[5] = {0};
				if (min_error < THRES_PURE) {
					nmpure++;
					strcpy(msg, "Pure");
				} else if (min_error < THRES_FAR) {
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
				tacc += 1 - min_error / (float)THRES_MISS;
				acc = tacc / (nmpure + npure + nfar + nmiss);
				pop_note(chart, best_i, &(nkey));
				LOG(touch.time, msg, valid_keys[touch.key]);

			/* Mistouch */
			} else {
				// LOG(touch.time, "Mistouch", valid_keys[touch.key]);
			}
		}
	}

	tcsetattr(STDIN_FILENO, TCSANOW, &oldt);

	return 0;
}


int main(int argc, char *argv[]) {

	ASSERT(argc == 2, USAGE_SIMTPCH);
	char *path = strdup(argv[1]);
	EXIST(path);

	return simtpch(path);
}

