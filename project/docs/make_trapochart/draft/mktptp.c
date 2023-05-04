#include "tptp.h"


int main(int argc, char *argv[]) {

	SHOWHELP(USAGE_MKTPTP);
	system("rm -rf _tpcache");

	ASSERT(argc == 4, USAGE_MKTPTP);
	char *dest = strdup(argv[1]);
	char *script = strdup(argv[2]);
	char *audio = strdup(argv[3]);
	EXIST(script);
	EXIST(audio);
	char buf[256] = {0};
	tptp_header_t header;

	/* Prepare header */
	system("mkdir _tpcache");
	mktpch("_tpcache/out.tpch", script);
	header.magic = MAGIC_TPTP;
	header.csize = filesize("_tpcache/out.tpch");
	char *dot = strrchr(audio, '.');
	ASSERT(dot, "Missing suffix in audio file");
	strcpy(header.asuffix, dot + 1);
	sprintf(buf, "cat _tpcache/out.tpch %s > _tpcache/out.pack", audio);
	system(buf);

	/* Hash & encrypt */
	char hash[SHA256_LEN + 1] = {0};
	char ahash[SHA256_LEN + 1] = {0};
	sha256(hash, "_tpcache/out.pack");
	sha256(ahash, audio);
	hex2byte(header.bhash, hash);
	hex2byte(header.abhash, ahash);
	sprintf(buf, "openssl enc -aes256 -pbkdf2 -in _tpcache/out.pack \
		-out _tpcache/out.pack.enc -pass pass:%s -nosalt", hash);
	system(buf);

	/* Pack & output */
	FILE *tph = fopen("_tpcache/out.tph", "w");
	fwrite(&header, sizeof(tptp_header_t), 1, tph);
	fclose(tph);
	sprintf(buf, "cat _tpcache/out.tph _tpcache/out.pack.enc > %s.tptp", dest);
	system(buf);
	system("rm -rf _tpcache");

	return 0;
}

