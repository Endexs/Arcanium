# vendor/

Third-party code, unmodified.

## visualizer/
The observability UI from disler/super-simple-software-factory
(`.claude/skills/sssf/apps/visualizer`, commit de31374). Vue 3 + Vite, served by
a small read-only Bun server.

It reads SSSF's `sssf.db` schema, which is not ours. `bin/arcanium-visualize`
builds a throwaway projection of our data into that shape, so this stays
unmodified and can be re-pulled from upstream at any time.
