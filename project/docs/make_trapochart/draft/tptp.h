#ifndef TPTP_H
#define TPTP_H


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


/* Constants */

#define MAX_NKEY 65535
#define MAX_LPHRASE 1024
#define SHA256_LEN 64
#define SHA256_LENB 32

#define VALID_KEYS "bcdefghijklmnoprstuvwxy234567890,.;-=["
#define USAGE_MKTPCH  "Usage: ./mktpch <TrapoScript>"
#define USAGE_MKTPTP  "Usage: ./mktptp <OutputFile> <TrapoScript> <AudioFile>"
#define USAGE_SIMTPCH "Usage: ./simtpch <TrapoChart>"
#define USAGE_SIMTPTP "Usage: ./simtptp <TrapoPack>"

#define MAGIC_TPCH 0x48435054
#define MAGIC_TPTP 0x50545054


/* Pseudo-functions */

#define SHOWHELP(msg) \
do { \
	int opt; \
	while ((opt = getopt(argc, argv, "h")) != -1) { \
		switch (opt) { \
			case 'h': \
				printf("%s\n", (msg)); \
				return 0; \
			default: \
				printf("%s\n", (msg)); \
				return 1; \
		} \
	} \
} while (0)

#define ASSERT(stmt, msg) \
do { \
	if (!(stmt)) { \
		printf("%s\n", (msg)); \
		exit(1); \
	} \
} while (0)

#define EXIST(path) \
do { \
	FILE *file = fopen(path, "r"); \
	ASSERT(file, "File not found"); \
	fclose(file); \
} while (0)

#define ROUND(num) (int)((num) + 0.5)

#define UNIT(ts) ROUND(((ts).tv_sec * 1000 \
	+ (ts).tv_nsec / CLOCKS_PER_SEC) / 2)


/* Structs */

typedef struct __attribute__((packed)) {
	uint16_t time;
	char key;
} note_t;

typedef struct {
	uint32_t magic;
	uint32_t nkey;
	char bhash[SHA256_LENB];
} tpch_header_t;

typedef struct {
	uint32_t magic;
	uint32_t csize;
	char asuffix[4];
	char bhash[SHA256_LENB];
	char abhash[SHA256_LENB];
} tptp_header_t;


/* Functions */

int mktpch(char *dest, char *src);
int simtpch(char* file);

int filesize(char *path);
void sha256(char *hash, const char *path);
void sha256_obj(char *hash, void *obj, int size, int len);
void hex2byte(char *dest, const char *src);
void byte2hex(char *dest, const char *src);


#endif

