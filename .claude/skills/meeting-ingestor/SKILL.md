---
name: meeting-ingestor
description: High-fidelity workflow for transcribing and ingesting meeting recordings and transcripts into the Memory Wiki.
---

# Meeting Ingestor (v2)

This skill formalizes the lifecycle of professional and academic interactions. It uses local AI (Whisper) for transcription and a multi-agent handoff for memory ingestion.

## Workflow

### Phase 1: High-Fidelity Transcription
If the user provides a raw audio file (`.m4a`, `.mp3`) in `knowledge/sources/meetings/raw/`:
1. **Check for capture metadata**: Look for a sidecar `<audio-basename>.json` next to the audio file (dropped by a mobile capture pipeline, if one exists — see [Capture Metadata](#capture-metadata-sidecar-json) below). If present, **read it before transcribing — do not discard it**:
   - `ingestion_directive` other than `STANDARD_INGEST`: **STOP.** Ask the principal what that directive should do — do not guess at an unrecognized value.
   - `participants`, `domain_tag`/`domain_category`, `title`: carry forward as Phase 2 seed hints (priors to verify against the transcript, not ground truth to skip verification on).
   - `user_context`: the principal's own dictated framing of the recording, captured at record time. Carry it forward verbatim for Phase 2 to surface as a **Capture Context** note — it wasn't said during the meeting, so it's never `source_quote`-eligible.
2. **Transcribe**: Run `python scripts/transcribe_meeting.py <input> <output>`.
   - **Important**: Ensure FFmpeg is on the PATH (or install `imageio-ffmpeg`, which `scripts/transcribe_meeting.py` will auto-detect).
   - **Model Selection**: Use a smaller Whisper model (e.g. `tiny`/`base`) for fast CPU-based testing. For production accuracy, use `small` or larger.
3. **Output**: Save the raw text to `knowledge/sources/meetings/transcripts/<YYYY-MM-DD-Participant-Topic>-Raw.txt`.

### Phase 2: Semantic Diarization & Discovery
**Mandatory dispatch — do not free-hand this phase.** Invoke the Agent tool with `agents/meeting-analyst.md` as the prompt. Reading the transcript yourself and writing memory directly is the exact failure mode this phase exists to prevent — even if your output happens to match the artifact schema below, skipping the actual subagent turn means the redundancy audit and the Phase 3 approval gate never really ran.
- **Agent Name:** `meeting-analyst`
- **Prompt Source:** `agents/meeting-analyst.md`
- **Input:** the transcript path, plus (if Phase 1 found one) the sidecar metadata — pass `participants`/`domain_tag`/`domain_category`/`title` as seed hints and `user_context` verbatim.
- **Goal**:
  - **Diarize**: Label speakers based on context (recognize known names from the Memory Wiki), using sidecar `participants` as a starting hint where provided.
  - **Discover**: Identify emergent domains (no hard-coded limits), using sidecar `domain_tag`/`domain_category` as a starting hint, not a routing decision — still verify against actual content.
  - **Artifact**: Generate a domain-threaded summary in `knowledge/sources/meetings/summaries/`.

### Phase 3: Memory Handoff
Before this phase, confirm to yourself that Phase 2 actually happened as an Agent-tool dispatch — not a manual read-and-write. If it didn't, stop and go back; do not write to `knowledge/_Memory/` from a hand-extracted summary.
1. **Validation**: Present the summary and memory ingestion blueprint to the user. **This gate is mandatory regardless of recording length or perceived triviality — there is no fast path, even for a two-minute voice memo.**
2. **Execution**: Once approved, extract the `MEMORY_PAYLOAD` and hand off to the **Memory Agent** for surgical wiki updates.

## Performance & Troubleshooting
- **CPU Warnings**: Whisper may warn about "FP16 not supported on CPU". This is normal; it will fallback to FP32.
- **Timeouts**: Long recordings (>30 min) may take several minutes on CPU. Use background execution for large files.
- **Diarization Quality**: If the Analyst mislabels a speaker, provide a hint (e.g., "Whoever mentions X is person Y") and re-run Phase 2.

## File Organization (The Vault)
- `knowledge/sources/meetings/raw/`: Original audio evidence, sometimes paired with a `<basename>.json` capture-metadata sidecar (see below).
- `knowledge/sources/meetings/transcripts/`: Speaker-labeled text evidence.
- `knowledge/sources/meetings/summaries/`: Domain-threaded analytical artifacts.

## Capture Metadata (Sidecar JSON)
Recordings dropped by a mobile capture pipeline may arrive with a `<basename>.json` sidecar in `raw/`. Suggested schema (adapt to whatever capture tooling you actually use):
- `title` — human title, used for Phase 1 naming.
- `domain_tag` / `domain_category` — the principal's own routing hint.
- `meeting_type` — free text (e.g. `"LECTURE"`, `"INTERVIEW"`, `"MEMO"`, `"BRAINSTORM"`).
- `participants` — array of names, used as a diarization seed.
- `has_new_person` / `new_participants` — flags a person not yet in the Memory Wiki.
- `ingestion_directive` — only `STANDARD_INGEST` observed to date. **Any other value: STOP, do not guess — ask the principal.**
- `user_context` — the principal's own dictated framing/notes about the recording, captured at record time. Not part of the meeting itself; never `source_quote`-eligible.
- `recorded_at` / `uploaded_at` / `original_filename` — provenance, useful for backlog auditing but not required by the ingestion workflow itself.

Not every raw file has one — plain manually-dropped audio won't. Absence is normal; proceed without it.

## Naming Convention
`YYYY-MM-DD-PrimaryParticipant-Topic`
Example: `2026-05-05-JaneDoe-TutorInterview`
