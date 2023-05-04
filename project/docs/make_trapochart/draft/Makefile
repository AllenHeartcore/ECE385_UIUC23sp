TARGETS=mktpch simtpch mktptp simtptp

CC=gcc
CCOPTS=-Wno-unused-result -O3
HELPER=helper.c


all: $(TARGETS)

%: %.c
	$(CC) $(CCOPTS) -o $@ $< $(HELPER) -DSTANDALONE

mktptp: mktptp.c mktpch.c
	$(CC) $(CCOPTS) -o $@ $^ $(HELPER)

simtptp: simtptp.c simtpch.c
	$(CC) $(CCOPTS) -o $@ $^ $(HELPER)

clean:
	rm -f $(TARGETS)

