---
tags: [project, money]
---
# Monetization

Brenden (2026-10-17): *"keep the gem shop I wanna make money from this too"*.

## What's in the game now
- **Gems** are the premium currency. They show next to the clock; tap them for the Gem Shop.
- The Gem Shop sells:
  - keys;
  - every character (100 / 300 / 800 / 2,000 gems, the original's tiers);
  - Combination Scrolls and Magic Seeds.
- **Gem packs for real money** (2026-11-07) through Stripe Checkout: 100 / 550 / 1,200 / 2,500 gems for $0.99 / $4.99 / $9.99 / $19.99 (placeholder prices). They work once Stripe is switched on (below).
- Gems also come from:
  - bosses, chests, magic seeds and quests;
  - buying them for **2,500 Pixel Coins each**.

- Gems also unlock Banka's backpacks 2 to 6 (2026-11-04).

See [[Currencies and Gem Shop]] for the details.

## Switching gem packs on
1. Open a **Stripe** account (stripe.com). It needs an adult's identity and bank account, so a parent may have to open it.
2. In Stripe, copy the **secret key** (starts `sk_live_`, or `sk_test_` to try it with test cards).
3. On Render, open the pixel server → Environment → add `STRIPE_SECRET_KEY` with that key. Save; the server restarts.
4. The Gem Shop then shows the packs. Prices are in `GEM_PACKS` in `server/pixel_server.py`.

The server checks every payment with Stripe and only then gives the gems, once per payment (Stripe remembers it was credited).

## What real-money gems needed (2026-11-04)
Brenden said gems should cost real money, like PSG2. The game is played on the web (GitHub Pages), so that needs:
1. **A payment account in Brenden's name,** such as Stripe or PayPal (a phone app would use Google Play or Apple instead). Only he can open it: it needs his identity and a bank account, and an adult if he is under 18.
2. **A small server that checks each payment** and then gives the gems. Saves live in the browser, so without it anyone could edit their gem count.
3. Prices for gem packs.
Until then, gems for 2,500 coins stay in the Gem Shop.

## Ways to earn later (to decide, see [[Open Questions]])
1. **Paid game on Steam.** The simplest: one price, no store inside the game.
2. **Real-money gem packs.** Use Steam's in-game purchases (Steamworks microtransactions) through GodotSteam. On a phone app this would mean Google Play or Apple in-app purchases instead.
3. **Both:** a low price plus optional gem packs.
4. **Cosmetics:** capes, wings and emotes are a fair thing to sell, because they don't change how strong you are.

> [!note]
> The project first aimed for "no pay-to-win". Selling cosmetics and convenience keeps players happier than selling power.
