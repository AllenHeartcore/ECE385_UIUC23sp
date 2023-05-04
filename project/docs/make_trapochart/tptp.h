#ifndef TPTP_H
#define TPTP_H


#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>


#define MAX_NKEY		65535
#define MAX_LPHRASE		1024
#define MAGIC_TPCH		0x48435054
#define VALID_KEYS		"     bcdefghijklmnop rstuvwxy  234567890     -=[   ;  ,."
#define USAGE_MKTPCH	"Usage: ./mktpch <TrapoScript>"
#define USAGE_SIMTPCH	"Usage: ./simtpch <TrapoChart>"


#define ASSERT(stmt, msg)			\
do {								\
	if (!(stmt)) {					\
		printf("%s\n", (msg));		\
		exit(1);					\
	}								\
} while (0)

#define EXIST(path)					\
do {								\
	FILE *file = fopen(path, "r");	\
	ASSERT(file, "File not found");	\
	fclose(file);					\
} while (0)

#define ROUND(num) (int)((num) + 0.5)

#define UNIT(ts) ROUND(((ts).tv_sec * 1000 \
	+ (ts).tv_nsec / CLOCKS_PER_SEC) / 2)


typedef struct __attribute__((packed)) {
	uint16_t time;
	int8_t key;
} note_t;


int mktpch(char *dest, char *src);
int simtpch(char* file);


#endif
