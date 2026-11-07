---
tags: [tech, server]
---
# Online Server

`godot/server/pixel_server.py` is plain Python 3 with nothing to install. It does three things:
- claims names;
- keeps friends lists (saved to `names.json`);
- relays room traffic, so players never see each other's IP.

## How games reach it
| What | Where |
|---|---|
| Names, friends, server time | `POST` on the main port (24566 at home, 443 on Render) |
| Room relay | WebSocket at `/relay` on the **same port** (`wss://` on Render) |
| Old raw relay (desktop only, unused by the game now) | main port + 1 (24567), off with `--no-raw-relay` |

The game uses the WebSocket relay everywhere, so the **phone/browser build can host and join rooms**. Browsers can't open raw connections, which is why phones couldn't go online before (2026-10-27). The server also answers the browser's CORS check, since the web game lives on GitHub Pages.

## Gem packs (Stripe, 2026-11-07)
| Route | What it does |
|---|---|
| `POST /gems/packs` | The packs and whether Stripe is on (`STRIPE_SECRET_KEY` set) |
| `POST /gems/buy` | Makes a Stripe Checkout page for a pack, tagged with the player's name |
| `POST /gems/claim` | Checks the game's open checkouts with Stripe; paid ones not yet credited give their gems and are marked `credited` on the payment |
| `GET /paid` | The thank-you page after paying |

- Set `STRIPE_SECRET_KEY` on Render (Environment). Without it the shop says packs aren't set up yet.
- Nothing is stored on the server: Stripe keeps the "credited" mark, so a payment never gives gems twice.
- Tests: `GemsTest` in `server/test_server.py` with a fake Stripe.

## Hosting (Render, free)
- `render.yaml` at the repo root sets it up as a free Render web service named `pixel-wilds-brendensob`.
- **Live** since 2026-10-27 (Brenden deployed it).
- **One-time setup (done):** open https://render.com/deploy?repo=https://github.com/Brendensob/Brenden.sobanski, sign in with GitHub, press Deploy.
- The game looks for it at `https://pixel-wilds-brendensob.onrender.com` (`ONLINE_SERVER` in `scripts/online.gd`). If Render gives a different address, put it in `godot/server.txt`.
- **Redeploying:** Render did not redeploy it on its own (found 2026-11-04). `.github/workflows/server-deploy.yml` calls Render's Deploy Hook whenever `godot/server/` or `render.yaml` changes on `main`. It needs the hook URL (Render: service > Settings > Deploy Hook) saved as the GitHub secret `RENDER_DEPLOY_HOOK`. Without it, redeploy by hand: Manual Deploy > Deploy latest commit.
- If the server is older than the game, the game says "The online server needs an update."
- **Sleeps** after 15 minutes with nobody on; the first request wakes it in about a minute. The game's first call (server time) waits up to 75 s for this.
- **No saved disk on the free plan**: a restart can wipe names. Each game keeps its name key and friends list and puts them back with `/restore` when the server says it doesn't know them. A friendship only counts once **both** players have put each other back, so nobody can fake one.

## Pointing the game somewhere else
| Way | Example |
|---|---|
| `godot/server.txt` in the repo | `https://my-server.onrender.com` |
| `server.txt` next to the game or in its save folder | `192.168.1.20` |
| Web link | `https://brendensob.github.io/Brenden.sobanski/?server=https://...` |
| Command line | `-- --server http://127.0.0.1:24566` (the autotest and nettest use this address by default) |

- **Public games:** a host's hello can say `"public": true`. `/rooms` lists public rooms (name, players, full) and anyone may join one; other rooms stay friends-only. `/friends` also says whether a friend's room is public.
- **For Steam:** swap `relay_peer.gd` for Steam's relay (GodotSteam).
