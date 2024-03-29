#include "tptp.h"


#define CKPT(stmt, msg) \
do { \
	if (!(stmt)) { \
		printf("[Phrase %d, Char %d, Tick %.3f", \
			iphrase + 1, ichar + 1, tick + 1); \
		if (multihand >= 0) { \
			printf(", Subtick %.3f, Hand %d", \
				subtick + 1, multihand + 1); \
		} \
		printf("] %s\n", (msg)); \
		exit(1); \
	} \
} while (0)

#define TICK(nticks) \
do { \
	if (multihand == -1) { \
		tick += (nticks) * accel; \
	} else { \
		CKPT(multihand <= 0 || subtick < subtick_base, \
			"Too many subticks in this hand"); \
		subtick += (nticks) * accel; \
	} \
	clock += spt * (nticks) * accel; \
} while (0)


int cmptime(const void *a, const void *b) {
	return ((note_t *)a)->time - ((note_t *)b)->time;
}

int cmpchar(const void *a, const void *b) {
	return ((note_t *)a)->key - ((note_t *)b)->key;
}


int mktpch(char *dest, char *src) {

	/* Open script */
	FILE *script = fopen(src, "r");
	ASSERT(script, "Failed to open TrapoScript");

	/* Parse header */
	int bpp, tpb;
	float bpm, bofst;
	char buffer[MAX_LPHRASE] = {0};
	ASSERT(fscanf(script, "TrapoScript %f %d %d %f%[^\n]", \
		&bpm, &bpp, &tpb, &bofst, buffer) == 4 && strlen(buffer) == 0, \
		"Header format: TrapoScript <BPM> <BPP> <TPB> <BOfst>");
	ASSERT((bpm > 0 && bpp > 0 && tpb > 0 && bofst >= 0), \
		"Invalid TrapoScript header: negative args");
	ASSERT((bpp & (bpp - 1)) == 0, \
		"Invalid TrapoScript header: BPP is not a power of 2");

	/* Properties */
	int kpp = tpb * bpp;
	float spt = 60.0 / bpm / tpb;
	float clock = 60.0 / bpm * bofst;
	float clock_base;

	/* Chart recorders */
	tpch_header_t header = {0};
	note_t chart[MAX_NKEY] = {0};

	/* Parse body */
	while (1) {
		char phrase[MAX_LPHRASE] = {0};
		fgets(phrase, MAX_LPHRASE, script);
		fscanf(script, "%[^\n]", phrase);
		if (strlen(phrase) == 1) break;

		/* Timers & markers */
		int iphrase = 0, ichar;
		float tick = 0, subtick, subtick_base;
		int multikey = 0, multihand = -1;
		float accel = 1;

		/* Parse a phrase */
		for (ichar = 0; ichar < strlen(phrase); ichar++) {
			char chr = phrase[ichar];
			if (strchr(VALID_KEYS, chr)) {
				CKPT(header.nkey < MAX_NKEY, "Too many keys in chart");
				chart[header.nkey] = (note_t){ROUND(clock * 500), chr};
				header.nkey++;
				if (!multikey) {
					TICK(1);
				}
			} else switch (chr) {

				case '`':
					CKPT(!multikey, "Empty key in multikey section");
					TICK(1);
					break;

				case '(':
					CKPT(!multikey, "Last multikey section not closed");
					multikey = 1;
					break;

				case ')':
					CKPT(multikey, "Multikey section not opened");
					multikey = 0;
					TICK(1);
					break;

				case '{':
					CKPT(!multikey, "Cannot switch hand in multikey section");
					CKPT(multihand == -1, "Last multihand section not closed");
					multihand = 0;
					subtick = 0;
					clock_base = clock;
					break;

				case '|':
					CKPT(!multikey, "Cannot switch hand in multikey section");
					CKPT(multihand >= 0, "Multihand section not opened");
					if (multihand > 0) {
						CKPT(subtick == subtick_base, "Too few subticks in this hand");
					} else {
						subtick_base = subtick;
					}
					multihand++;
					subtick = 0;
					clock = clock_base;
					break;

				case '}':
					CKPT(!multikey, "Cannot switch hand in multikey section");
					CKPT(multihand >= 0, "Multihand section not opened");
					CKPT(multihand >= 1, "Only one hand in multihand section");
					CKPT(subtick == subtick_base, "Too few subticks in this hand");
					multihand = -1;
					clock = clock_base;
					TICK(subtick_base);
					break;

				case '<':
					CKPT(!multikey, "Cannot accelerate in multikey section");
					accel /= 2;
					break;

				case '>':
					CKPT(!multikey, "Cannot accelerate in multikey section");
					CKPT(accel < 1, "Cannot decelerate");
					accel *= 2;
					break;

				default:
					CKPT(0, "Invalid character");
			}
		}

		/* Parse a phrase: done */
		CKPT(!multikey, "Last multikey section not closed at end of phrase");
		CKPT(multihand == -1, "Last multihand section not closed at end of phrase");
		CKPT(accel == 1, "Acceleration not turned off at end of phrase");
		CKPT(tick == kpp, "Incorrect number of ticks in phrase");
		iphrase++;
	}
	fclose(script);

	/* Sort & hash */
	char hash[SHA256_LEN + 1] = {0};
	qsort(chart, header.nkey, sizeof(note_t), cmpchar);
	qsort(chart, header.nkey, sizeof(note_t), cmptime);
	sha256_obj(hash, chart, sizeof(note_t), header.nkey);
	hex2byte(header.bhash, hash);

	/* Write chart */
	header.magic = MAGIC_TPCH;
	FILE *tpch = fopen(dest, "w");
	fwrite(&header, sizeof(tpch_header_t), 1, tpch);
	fwrite(&chart, sizeof(note_t), header.nkey, tpch);
	fclose(tpch);

	return 0;
}


#if STANDALONE

int main(int argc, char *argv[]) {

	SHOWHELP(USAGE_MKTPCH);

	ASSERT(argc == 2, USAGE_MKTPCH);
	char *src = strdup(argv[1]);
	EXIST(src);

	char *dest = strdup(src);
	char *dot = strrchr(dest, '.');
	ASSERT(dot, "Missing suffix in source file");
	strcpy(dot, ".tpch");

	return mktpch(dest, src);
}

#endif

