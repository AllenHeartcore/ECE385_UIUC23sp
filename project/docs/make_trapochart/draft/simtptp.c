#include "tptp.h"


int main(int argc, char *argv[]) {

	SHOWHELP(USAGE_SIMTPTP);
	system("rm -rf _tpcache");

	ASSERT(argc == 2, USAGE_SIMTPTP);
	char *pack = strdup(argv[1]);
	EXIST(pack);
	char buf[256] = {0};
	tptp_header_t header;

	/* Open pack */
	FILE *tptp = fopen(pack, "r");
	ASSERT(tptp, "Failed to open TrapoPack");
	ASSERT(fread(&header, sizeof(tptp_header_t), 1, tptp) == 1, \
		"Failed to read TrapoPack header");
	ASSERT(header.magic == MAGIC_TPTP, "Invalid TrapoPack");
	ASSERT(header.csize > 0, "Invalid TrapoChart size");
	fclose(tptp);

	/* Check hash */
	char hashg[SHA256_LEN + 1] = {0};
	char ahash[SHA256_LEN + 1] = {0};
	char ahashg[SHA256_LEN + 1] = {0};
	byte2hex(hashg, header.bhash);
	byte2hex(ahashg, header.abhash);

	/* Decrypt */
	system("mkdir _tpcache");
	sprintf(buf, "tail -c +%ld %s > _tpcache/out.pack.enc", \
		sizeof(tptp_header_t) + 1, pack);
	system(buf);
	sprintf(buf, "openssl enc -d -aes256 -pbkdf2 -in _tpcache/out.pack.enc \
		-out _tpcache/out.pack -pass pass:%s -nosalt", hashg);
	system(buf);

	/* Extract */
	sprintf(buf, "dd if=_tpcache/out.pack of=_tpcache/out.tpch \
		bs=1 count=%d > /dev/null 2>&1", header.csize);
	system(buf);
	sprintf(buf, "tail -c +%d _tpcache/out.pack > _tpcache/out.%s", \
		header.csize + 1, header.asuffix);
	system(buf);
	sprintf(buf, "_tpcache/out.%s", header.asuffix);
	sha256(ahash, buf);
	ASSERT(!strcmp(ahash, ahashg), "Invalid audio hash");

	simtpch("_tpcache/out.tpch");
	system("rm -rf _tpcache");

	return 0;
}

