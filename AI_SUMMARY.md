# AI Summary: Getting LiteLLM Working End-to-End

Date: 2025-08-10

## What was broken
- LiteLLM stood up but /v1 endpoints returned 401 ("Invalid proxy server token passed")
- Later attempts failed due to YAML mistakes in the LiteLLM config when switching to env interpolation
- GET /v1/models also failed because `enforce_user_param` required a `user` field even for routes with no body

## What I changed
1. Fixed the LiteLLM config file `open-webui-litellm-config/config.yaml`:
   - Corrected YAML indentation under `model_list`
   - Switched env references to `os.environ/…` syntax:
     - Under each model `litellm_params.api_base: os.environ/OLLAMA_BASE_URL`
     - Under `general_settings.master_key: os.environ/LITELLM_MASTER_KEY`
   - Set `general_settings.enforce_user_param: false` (allows `/v1/models` and basic clients without a `user` body field)

2. Ensured Docker Compose wiring is consistent:
   - `open-webui-litellm` mounts `/app/config/config.yaml`
   - Environment variables present for:
     - `LITELLM_MASTER_KEY`
     - `LITELLM_API_KEY` (optional; use a generated virtual key instead)
     - `OLLAMA_BASE_URL` (defaults to host.docker.internal:11434)
     - `DATABASE_URL` pointed to the Postgres service
   - Postgres service added/running for LiteLLM key/state storage

## How I validated
- Confirmed LiteLLM health: `GET /health/liveliness` -> 200 "I'm alive!"
- Generated a virtual key using the master key: `POST /key/generate` with `Authorization: Bearer <master>`
  - Resolved 400 alias conflict by using a unique timestamped `key_alias`
- Verified auth to protected endpoints with the virtual key:
  - `GET /v1/models` -> 200 with list of configured models
  - `POST /v1/chat/completions` with `model: gemma3:12b-it-qat` -> 200, assistant replied "Hello."

## Current working state
- LiteLLM is running with Postgres and Redis cache
- Virtual key auth is working; use the key in `Authorization: Bearer <key>` or `x-api-key: <key>`
- Open WebUI is configured to talk to LiteLLM at `http://open-webui-litellm:4000`

## Usage tips
- Store secrets in a local `.env` and avoid committing sensitive keys
- If you re-enable `enforce_user_param`, ensure clients supply a `user` field in request bodies
- Prefer a generated virtual key for Open WebUI instead of the master key

---

## SearXNG and integrations: fixes and status

What was broken
- SearXNG logs showed engine loader errors (e.g., missing module `searx.py`) and later HTTP 500 due to missing defaults when a custom engines list overrode schema-required keys (e.g., `default_doi_resolver`).
- Deprecation warning for `redis.url` vs `valkey.url` appeared on recent images.

What I changed
- Simplified `searxng/settings.yml` to rely on defaults (`use_default_settings: true`) and removed problematic custom engine overrides.
- Kept `redis.url` (schema-compliant) and noted the `valkey.url` deprecation warning is benign for now.
- Standardized the workflow to rebuild only SearXNG when iterating: `docker compose rm -sf open-webui-searxng && docker compose up -d open-webui-searxng`, then wait 5 seconds before tailing logs.

How I validated
- Clean recreate of SearXNG only; waited 5 seconds; logs now free of engine errors.
- Verified `/search` returns JSON (tested inside container); the service responds to queries.

Other services
- MCP proxy: entrypoint fixed for cross-platform (LF, /bin/sh), healthcheck via curl; container healthy and serves `/docs` and `/openapi.json`.
- OSINT tools API: healthcheck returns 200; container healthy.
- Cross-platform hardening: `.gitattributes` to enforce LF in shell/yaml/docker and CRLF for Windows scripts; curl-based healthchecks.

Open WebUI notes
- Ensure `LITELLM_API_KEY` inside Open WebUI is set to a valid LiteLLM virtual key (not the default `sk-1234`); place it in a local `.env` and restart only the `open-webui` service.

---

## Tika upgrade: large files, multi-language OCR, embedded extraction

What we implemented
- Built a custom image (`tika/Dockerfile`) on Java 21 with Tesseract OCR language packs: `eng, spa, fra, ara, rus, ukr, pol`.
- Switched to Apache Tika Server 3.2.2 (downloaded jar) for latest server APIs.
- Tuned JVM for large files: `-Xmx4g` by default (override via `JAVA_TOOL_OPTIONS`).
- Healthcheck added: `GET /version`.

Configuration (`tika/tika-config.xml`)
- OCR: enables Tesseract with multi-language string `eng+spa+fra+ara+rus+ukr+pol`, preprocessing on, generous timeouts.
- Deep extraction: recursive embedded extraction, inline images, embedded resource paths.
- Metadata: includes all, XMP, and embedded metadata.
- PDF tuning: `AUTO` OCR, inline image extraction, `sortByPosition`.
- Global limits: unlimited embedded depth/resources/parse time; no max string length.

Compose wiring (`docker-compose.yaml`)
- `open-webui-tika` now builds from `./tika`, sets `TESSDATA_PREFIX`, mounts `/tika-config.xml`, exposes 9998, and has a healthcheck.

Validation
- Container logs show Tika 3.2.2 starting with custom config; `/version` responds.

---

## Open WebUI RAG and extraction tuning

What changed (docker-compose `open-webui` env)
- Document extraction: `CONTENT_EXTRACTION_ENGINE: tika`, `DOC_EXTRACTION_ENGINE: tika`, `TIKA_SERVER_URL: http://open-webui-tika:9998`.
- Chunking: `CHUNK_SIZE: 1200`, `CHUNK_OVERLAP: 200`.
- Retrieval: `RAG_TOP_K: 8`, `RAG_RELEVANCE_THRESHOLD: 0.05`.
- Reranking: `RAG_RERANKING_MODEL: bge-reranker-v2-m3` (fast, high-quality reranker already cached by Open WebUI).
- Web search: SearXNG enabled with `RAG_WEB_SEARCH_RESULT_COUNT: 5`, `RAG_WEB_SEARCH_CONCURRENT_REQUESTS: 5` for stability.

Notes
- If latency increases, reduce `RAG_TOP_K` to `5` or temporarily clear the reranker.
- For more recall, increase `RAG_TOP_K` (e.g., `10`) and lower threshold (e.g., `0.02`).

---

## SearXNG hardening (delta)
- Fixed compose YAML indentation; added healthcheck; headers added to healthcheck request (`X-Forwarded-For`, `Host`) to avoid botdetection log noise.
- Using `use_default_settings: true` in `searxng/settings.yml` with limiter enabled and conservative timeouts.

---

## Quality gates (current)
- Compose parse: PASS
- Tika: PASS (3.2.2 up, healthcheck OK)
- LiteLLM: PASS (virtual keys, Postgres)
- SearXNG: Running; healthcheck header noise resolved; deprecation warning about `redis.url` is benign.

