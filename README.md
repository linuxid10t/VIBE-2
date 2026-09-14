# VIBE-2

A coding agent that runs natively on OS/2 — Warp 3 and later — talking to a
local LLM server over plain HTTP.

It is a reimplementation, not a port. The design comes from
[HaiCode](https://github.com/linuxid10t/HaiCode), a Haiku agent written in
C++20 against the BeAPI; none of that code survives the trip. Warp 3 predates
kLIBC, so the best available compilers are VisualAge C++ 3.0, Borland C++ 2.0
for OS/2 and Open Watcom — all early-1990s C++ with no STL, no exceptions worth
relying on, and templates that barely work. The modern codebase expresses
nearly every interface in C++11 types, so carrying it over would have meant
redesigning all of them. Starting again in C89 was less work and produces
something that actually builds.

## Why there is no TLS

The target is a **local** model server — llama.cpp, Ollama or LM Studio on the
LAN — over plain HTTP. That is not a limitation so much as the point: a 486
running Warp 3 was never going to host inference, so there is a modern machine
on that network regardless, and pointing at it removes the single hardest
dependency. TLS 1.2 on a 1993 compiler is possible (BearSSL needs only
`memcpy`, `memmove`, `memcmp` and `strlen` from libc) but it is not needed to
make the thing work, so it is not here.

## Layout

    core/    the portable layer — 14 C89 sources, ~4,900 lines
    core/tests/

`core/` is everything the client does except draw pixels: JSON, SSE, HTTP,
the OpenAI-compatible provider, path containment, the permission gate, the
session store, six tools, config, and the agentic loop. It builds and is tested
on a modern host, then compiles unchanged with `icc`, `bcc` or `wcc386`.

Exactly two pieces know about OS/2: `plat_os2.c`, and a six-case block at the
top of `sock.c`. Everything else is platform-agnostic by construction.

    cd core
    make check      # 454 assertions, no network
    make live       # 58 more, over real sockets against real servers
    make portable   # proves the 12 platform-independent sources are strict C89

Clean under GCC 13, Clang, and ASan + UBSan with leak detection.
See [core/README.md](core/README.md) for the design decisions and the traps
waiting on the target compilers.

## Status

The portable layer is complete and tested. The Presentation Manager frontend is
not written yet, and neither `plat_os2.c` nor the OS/2 half of `sock.c` has ever
been compiled — no OS/2 toolchain was available. Both are small, both are
documented with the specific traps that cost time, and both fail loudly.

Planned:

- **v0.1** plain HTTP to a local server, MLE-based transcript, read/write/ls
- **v0.2** the remaining tools, permission dialog, session list
- **v0.3** persistence, naive compaction
- **v0.4** owner-drawn GPI transcript with colour and collapsible tool blocks

Starting with a plain `WC_MLE` rather than a custom text view is deliberate: it
gets a working app months earlier, and the owner-drawn version slots in behind
the same interface later.

## Naming

The source uses a `haios2` prefix throughout — include guards, the `.haios2.json`
config file, the `HAIOS2_HOME` environment variable. It predates this repo
having a name. Renaming is mechanical if `vibe2` is preferred.

## Requirements

- OS/2 Warp 3 or later with the **32-bit** TCP/IP stack
  (`so32dll.dll` / `tcp32dll.dll`), not Warp 3's original 16-bit IAK
- The TCP/IP Programming Toolkit, for headers and `tcpip32.lib`
- VisualAge C++ 3.0, Borland C++ 2.0 for OS/2, or Open Watcom V2
- A machine on the LAN running llama.cpp, Ollama or LM Studio

## Licence

Apache 2.0, per `LICENSE`. The code here is original; HaiCode is MIT and none of
its source was copied.
