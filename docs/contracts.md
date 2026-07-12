# Relay Implemented Contracts

All JSON success responses use `{ "data": ... }`. Errors use `{ "error": { "code", "message" } }`; validation errors also include `details`. Protected HTTP requests and socket connections use the Guardian bearer token returned by registration/login.

## HTTP

Base path: `/api`.

| Method | Path | Request / response |
| --- | --- | --- |
| POST | `/auth/register` | `{username,email,password}` -> `{token,user}` |
| POST | `/auth/login` | `{email,password}` -> `{token,user}` |
| GET | `/auth/me` | current user |
| GET | `/friends` | accepted users |
| GET/POST | `/friend-requests` | incoming requests / `{username}` or `{recipient_id}` |
| PATCH | `/friend-requests/:id` | `{status:"accepted"|"declined"}` |
| GET | `/conversations` | conversations with `{members:[{user,role,banned_at}]}` |
| POST | `/conversations/direct` | `{user_id}` |
| POST | `/conversations/group` | `{name,member_ids}` |
| GET | `/conversations/:conversation_id/messages` | newest 50; optional `before` message UUID |
| POST | `/conversations/:conversation_id/messages` | multipart fields `body` and optional `file`; 25 MB request limit |
| DELETE | `/conversations/:conversation_id/messages/:id` | soft-delete sender/admin message |
| POST | `/conversations/:conversation_id/members/:user_id/kick` | owner/admin moderation |
| POST | `/conversations/:conversation_id/members/:user_id/ban` | owner/admin moderation |
| GET/POST | `/conversations/:conversation_id/calls` | history / `{kind:"voice"|"video"}` |
| PATCH | `/calls/:id/end` | initiator ends call |
| GET | `/notifications` | current user's notifications |
| PATCH | `/notifications/:id/read` | mark notification read |
| GET | `/health` | unauthenticated process health |

Messages expose one nullable `attachment` with `{url,filename,content_type,size}`. Upload URLs are `/uploads/:key`. Calls expose `initiator`, `kind`, status/timestamps, and participants.

## Channels

Connect to `/socket` with `{token}`. Topics are authorized from the token.

| Topic | Client events | Server events |
| --- | --- | --- |
| `user:{current_user_id}` | none | `notification`, `call_invite`, Phoenix `presence_state` / `presence_diff` |
| `conversation:{id}` | `message:new`, `typing`, `call:start` | `message:new`, `message:deleted`, `typing`, `call:started` |
| `call:{id}` | `signal`, `call:end` | `signal`, `participant:joined`, `call:ended` |

`signal` accepts `{type:"offer",sdp}`, `{type:"answer",sdp}`, `{type:"ice",candidate}`, or `{type:"hangup"}`. The server adds `from` and broadcasts to other call participants. This implementation broadcasts within the call topic, so calls are suitable for direct calls; group-call clients need explicit peer routing/mesh negotiation.
