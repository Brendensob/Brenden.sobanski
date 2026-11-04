---
tags: [session]
---
# 2026-11-04: Find Public Game shows "Unknown request."

**Asked:** "when i host a game and my friend clicks find game it only shows unkown request".

**Cause:** the [[Online Server]] on Render was still running the code from the morning of 2026-10-27. Public games (`/rooms`) were added that afternoon. Render never redeployed it, so it didn't know the request. Checked by calling the live server with a throwaway name.

**Done:**
- `.github/workflows/server-deploy.yml` asks Render to redeploy whenever the server code changes on `main` (needs the `RENDER_DEPLOY_HOOK` secret).
- The game says "The online server needs an update. Try again in a few minutes." instead of "Unknown request."
- Tests: server tests OK, two-player test 0 failures, autotest 0 failures.

**Next:** Brenden presses Manual Deploy > Deploy latest commit on Render, and saves the Deploy Hook as a GitHub secret.
