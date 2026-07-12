# Realtime Platform

Relay is a Phoenix/PostgreSQL realtime messaging backend with a Vite/React frontend and Phoenix-channel WebRTC signaling. The implemented API and channel schemas are documented in [`docs/contracts.md`](docs/contracts.md).

## Architecture

Phoenix contexts keep account, chat, notification, and call rules separate from HTTP controllers and authenticated channels. PostgreSQL is the source of truth, Guardian signs bearer tokens, Phoenix PubSub distributes realtime events, and Presence tracks connected users. Browsers exchange WebRTC SDP and ICE through call channels, but audio, video, and screen media travels peer-to-peer or through TURN rather than through Phoenix.

```text
realtime-platform/
├── backend/
│   ├── config/                 # environment and endpoint configuration
│   ├── lib/relay/              # Accounts, Chat, Calls, Notifications contexts
│   ├── lib/relay_web/          # JSON controllers, channels, Presence, auth
│   ├── priv/repo/              # migrations and seed data
│   └── test/                   # context and controller tests
├── frontend/
│   ├── src/context/            # authenticated session state
│   ├── src/hooks/              # Phoenix realtime and WebRTC lifecycle
│   └── src/lib/                # typed HTTP and socket clients
├── deploy/k8s/                 # templates only; never applied by setup
├── docs/contracts.md           # exact HTTP and channel contracts
└── docker-compose.yml          # PostgreSQL, Phoenix, React/nginx, optional TURN
```

## Data Model

- `users`: credentials, profile identity, and availability status
- `friend_requests`: sender/recipient pair and pending, accepted, or declined state
- `conversations`: direct/group metadata, creator, direct-chat uniqueness key, and last activity
- `memberships`: conversation role (`owner`, `admin`, `member`) and ban state
- `messages`: sender, text, soft deletion, and one optional attachment's metadata
- `notifications`: user activity records, JSON data, and read timestamp
- `calls`: conversation, initiator, voice/video kind, lifecycle status, and timestamps
- `call_participants`: unique call/user joins and leave timestamps

All primary keys are UUIDs. Foreign keys, unique constraints, and query indexes are defined in `backend/priv/repo/migrations`. Authorization is checked in contexts and channel joins, not trusted to the React client.

## Docker Compose

1. Run `make setup` and replace every `CHANGE_ME` in `.env`.
2. Keep `POSTGRES_DB`, `POSTGRES_PASSWORD`, and `DATABASE_URL` consistent. URL-encode special password characters.
3. Run `docker compose config --quiet`.
4. Run `docker compose up --build -d`.
5. Open `http://localhost:3000`; health is `http://localhost:4000/health`.

The backend release entrypoint runs idempotent Ecto migrations before starting. `make migrate` can run them explicitly. Vite API, socket, and ICE values are compile-time Docker build arguments. Authentication is stateless bearer-token authentication, so logout clears the browser token rather than revoking it server-side.

For native development, configure PostgreSQL, run `mix deps.get && mix ecto.setup && mix phx.server` in `backend`, and `npm install && npm run dev` in `frontend`. Defaults are API `http://localhost:4000/api`, socket `ws://localhost:4000/socket`, and frontend `http://localhost:5173`.

## Feature Walkthrough

1. Register two accounts in separate browser profiles and send a friend request by username.
2. Accept the request, create a direct chat or select multiple friends for a group, and send text or an attachment.
3. Observe persisted notifications, realtime delivery, and online presence.
4. Start a voice or video call. The recipient receives a user-channel invitation even when another conversation is selected.
5. Join the call, then test mute, camera, and screen sharing. Browser media permissions and HTTPS are required outside localhost.
6. As a group owner/admin, use moderation controls to kick or ban a member or delete a message.

The current WebRTC implementation is optimized for one-to-one calls. A production group-call system should introduce explicit peer targeting for small meshes or an SFU such as LiveKit, Janus, or mediasoup.

## Deployment

Kubernetes manifests under `deploy/k8s` are templates: replace image tags/domains/secrets, install an ingress controller and cert-manager if referenced, and use managed PostgreSQL for production. Build the frontend image with public `VITE_*` values; ConfigMap values cannot change an already-built bundle.

`libcluster` DNS polling uses `DNS_CLUSTER_QUERY`. Releases derive long node names from the pod hostname and query, and all replicas require the same `RELEASE_COOKIE`. The headless service provides pod DNS records. Verify distribution networking and cluster membership in the target environment.

Phoenix Channels do not require sticky sessions once nodes form a cluster and share distributed PubSub, though ingress websocket timeout settings must support long-lived connections. Scale backend pods against connection count, scheduler utilization, mailbox latency, and message throughput rather than HTTP request rate alone. Presence metadata should remain small because joins/leaves replicate across the cluster. Use PgBouncer or carefully size Ecto pools so replica growth does not exhaust PostgreSQL connections.

Ingress routes `/api`, `/socket`, `/uploads`, and `/health` to Phoenix. Uploads currently use the backend container filesystem and therefore are not durable or shared between replicas. For production, replace this with object storage before enabling multiple replicas, or mount a shared writable volume with appropriate security and consistency semantics.

WebRTC media is peer-to-peer or TURN-relayed; Phoenix only relays signaling. Set `VITE_ICE_SERVERS` to valid JSON at frontend build time. HTTPS/WSS is required outside localhost. The optional Compose coturn profile is for local integration; permanent TURN credentials in a browser bundle are unsuitable for production.

For production TURN, expose TCP/UDP 3478 (and preferably TLS 5349), configure the advertised public IP, and open the configured UDP relay range. Generate short-lived TURN REST credentials server-side instead of embedding a permanent password. Monitor allocation count, relay bandwidth, packet loss, and regional latency; deploy TURN close to users and capacity-plan it independently from Phoenix.

## Security

Use long independent values for `SECRET_KEY_BASE`, `GUARDIAN_SECRET`, and `RELEASE_COOKIE`; store them in a secret manager rather than committed YAML. Add rate limits for auth, messaging, uploads, and signaling before internet exposure. Production file sharing also needs object storage, private signed URLs, content-type verification, malware scanning, quotas, and retention policies. The included manifests are starting templates, not a hardened production baseline.

## Commands

- `make test`: backend tests, frontend lint, and frontend TypeScript/Vite build
- `make migrate`: run release migrations in the backend container
- `make up-turn`: start Compose including coturn
- `make clean`: remove containers and database volume

## Residual Production Work

- Object storage, malware scanning, attachment authorization, and retention
- Refresh/revocation tokens, rate limiting, and signaling/message size controls
- Explicit target/mesh negotiation for group WebRTC calls
- CI, backups, monitoring, network policies, and a dedicated one-shot Kubernetes migration Job if migrations must not run during pod startup
- Lockfiles and pinned frontend dependency versions for reproducible builds
