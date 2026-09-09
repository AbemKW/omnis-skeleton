# Protocols — Index

Protocols are **situational governing text**, not memory. They live outside `knowledge/_Memory/` on purpose: the memory agent's scope is the wiki, and keeping protocols out of that tree stops them from being treated as narrative entities that get appended to indefinitely. A protocol is terse and imperative, and is **replaced in place** when it changes — never appended to, never given a dated changelog. If the reasoning behind a protocol matters, it belongs in the relevant `_Memory/` entity and gets linked from the protocol.

## Loading

Two files auto-load every session (kept in the session-start hook's byte budget):
- `communication.md` — tone/format defaults for how Omnis writes back
- `scheduling.md` — calendar/scheduling conventions, if applicable

Everything else here loads **on demand** — read the specific file only when a task actually touches that domain. Don't assume a protocol is already in context just because it exists in this folder.

| File | Load when... |
|---|---|
| `communication.md` | (always loaded) |
| `scheduling.md` | (always loaded) |
| `tools.md` | Invoking an unfamiliar tool/MCP integration and need the invocation reference |

Add a row here whenever a new protocol file is created — this table is the map.
