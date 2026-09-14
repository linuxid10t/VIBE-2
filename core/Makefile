# core/ - portable C layer for the OS/2 client.
#
# Nothing outside plat_os2.c knows about OS/2, so everything here is built and
# tested on a modern host, then compiled unchanged with icc / bcc / wcc386 on
# the target. The awkward parts -- SSE chunk boundaries, UTF-8 escaping,
# chunked transfer decoding, path containment -- are far easier to get right
# with a sanitizer and a scriptable server than with a 1995 debugger.
#
# CFLAGS are deliberately strict C89: the target compilers are 1993-1995
# vintage and will not forgive C99-isms.

CC      ?= cc
CFLAGS  ?= -std=c89 -pedantic -Wall -Wextra -Werror -O2
LDFLAGS ?=

# plat_posix.c and the tests that drive real files or sockets need POSIX
# headers, which -std=c89 hides behind __STRICT_ANSI__. The C89 *language*
# discipline still applies; only the header gating is lifted. The portable
# sources are never built this way.
HOSTFLAGS = -std=gnu89 -D_POSIX_C_SOURCE=200112L
PORTABLE_CFLAGS = $(CFLAGS)
HOST_CFLAGS = $(filter-out -std=c89,$(CFLAGS)) $(HOSTFLAGS)

# Compiled with the strict C89 rules. These are the files that ship to OS/2.
PORTABLE_SRC = buf.c json.c sse.c http.c provider.c path.c perm.c \
               store.c tool.c tools.c config.c loop.c
# sock.c compiles for both platforms from one source but needs POSIX headers
# here, so it builds with the host flags; plat_os2.c replaces plat_posix.c on
# the target while sock.c goes across unchanged.
HOST_SRC     = plat_posix.c sock.c

PORTABLE_OBJ = $(PORTABLE_SRC:.c=.o)
HOST_OBJ     = $(HOST_SRC:.c=.o)
LIB_OBJ      = $(PORTABLE_OBJ) $(HOST_OBJ)

TESTS = tests/test_json tests/test_sse tests/test_http tests/test_provider \
        tests/test_path tests/test_store tests/test_tools tests/test_config \
        tests/test_loop

# Old compilers are only required to support 509-character string literals and
# the test fixtures exceed that after concatenation. Shipping source stays
# inside the limit; if a target compiler rejects the fixtures, split them at
# runtime.
TESTFLAGS = -Wno-overlength-strings

all: $(LIB_OBJ)

$(PORTABLE_OBJ): %.o: %.c
	$(CC) $(PORTABLE_CFLAGS) -c $< -o $@

$(HOST_OBJ): %.o: %.c
	$(CC) $(HOST_CFLAGS) -c $< -o $@

$(TESTS): tests/%: tests/%.c $(LIB_OBJ)
	$(CC) $(HOST_CFLAGS) $(TESTFLAGS) $< $(LIB_OBJ) -o $@ $(LDFLAGS)

check: $(TESTS)
	@fail=0; \
	for t in $(TESTS); do ./$$t || fail=1; done; \
	exit $$fail

# Opt-in: drives the stack against a real socket and a real streaming server.
tests/test_live tests/test_sock: tests/%: tests/%.c $(LIB_OBJ)
	$(CC) $(HOST_CFLAGS) $(TESTFLAGS) $< $(LIB_OBJ) -o $@ $(LDFLAGS)

live: tests/test_live tests/test_sock
	@rc=0; \
	python3 tests/sockserv.py > /tmp/haios2_sock.$$$$ & \
	spid=$$!; \
	python3 tests/fake_llama.py > /tmp/haios2_llama.$$$$ & \
	lpid=$$!; \
	for i in 1 2 3 4 5 6 7 8 9 10; do \
	    sp=$$(cat /tmp/haios2_sock.$$$$ 2>/dev/null); \
	    lp=$$(cat /tmp/haios2_llama.$$$$ 2>/dev/null); \
	    [ -n "$$sp" ] && [ -n "$$lp" ] && break; \
	    sleep 0.2; \
	done; \
	./tests/test_sock 127.0.0.1 $$sp || rc=1; \
	./tests/test_live 127.0.0.1 $$lp || rc=1; \
	kill $$spid $$lpid 2>/dev/null; \
	rm -f /tmp/haios2_sock.$$$$ /tmp/haios2_llama.$$$$; \
	exit $$rc

# Proves the platform-independent sources really are strict C89, independent of
# the tests. sock.c also ships to OS/2 but cannot be checked this way: it needs
# socket headers, which -std=c89 hides behind __STRICT_ANSI__. Its C89
# discipline is enforced by -std=gnu89 -pedantic in the normal build instead.
portable:
	@for f in $(PORTABLE_SRC); do \
	    $(CC) -std=c89 -pedantic -Wall -Wextra -Werror -O2 -c $$f -o /dev/null \
	        || exit 1; \
	done; \
	echo "$(words $(PORTABLE_SRC)) platform-independent sources compile as strict C89"; \
	echo "(sock.c also ships, but needs socket headers; see the comment above)"

clean:
	rm -f $(LIB_OBJ) $(TESTS) tests/test_live tests/test_sock

.PHONY: all check clean live portable
