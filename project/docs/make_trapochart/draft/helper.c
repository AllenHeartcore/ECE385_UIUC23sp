#include "tptp.h"


int filesize(char *path) {
	FILE *file = fopen(path, "r");
	ASSERT(file, "Failed to open file");
	fseek(file, 0, SEEK_END);
	int size = ftell(file);
	fclose(file);
	return size;
}

void sha256(char *hash, const char *path) {
	char buf[256] = {0};
	sprintf(buf, "sha256sum %s | cut -d ' ' -f 1 > %s.sha256", path, path);
	system(buf);
	sprintf(buf, "%s.sha256", path);
	FILE *file = fopen(buf, "r");
	ASSERT(file, "Failed to open file");
	ASSERT(fread(hash, sizeof(char), SHA256_LEN, file) == SHA256_LEN, \
		"Failed to read file");
	fclose(file);
	sprintf(buf, "rm %s.sha256", path);
	system(buf);
}

void sha256_obj(char *hash, void *obj, int size, int len) {
	FILE *tmp = fopen("tmp", "w");
	fwrite(obj, size, len, tmp);
	fclose(tmp);
	sha256(hash, "tmp");
	system("rm tmp");
}

void hex2byte(char *dest, const char *src) {
	while (*src) {
		sscanf(src, "%02hhx", dest);
		src += 2;
		dest++;
	}
}

void byte2hex(char *dest, const char *src) {
	for (int i = 0; i < SHA256_LENB; i++) {
		sprintf(dest, "%02hhx", src[i]);
		dest += 2;
	}
}

