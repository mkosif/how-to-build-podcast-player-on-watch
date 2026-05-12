# rawfile assets

The services read bundled audio assets from this folder through
`context.resourceManager.getRawFd(...)`. Drop matching files in to enable each
feature; missing files are tolerated and the codelab still demonstrates the
common-event flow when they are absent.

## Expected files

| File | Used by | Purpose |
|---|---|---|
| `episode_machine_stops.mp3` | `AudioPlayerService`, `MetadataService` | Bundled offline episode for the rawfile `AVFileDescriptor` path. `AVMetadataExtractor` also reads its title, duration, and album cover. |
| `episode_electricity.mp3` | `AudioPlayerService`, `MetadataService` | Second bundled offline episode used to verify skip/reload against a distinct rawfile source. |
| `sfx_tap.ogg` | `SoundEffectService` | Short tap feedback played on every button press. |
| `sfx_skip.ogg` | `SoundEffectService` | Skip-forward / skip-back feedback. |
| `sfx_chime.ogg` | `SoundEffectService` | Completion chime played when an episode ends. |

Use any CC0 / royalty-free audio you like. Keep tap and skip effects very
short for the latency benefits SoundPool is designed for; completion chimes can
be slightly longer.

## Bundled demo assets

| File | Source |
|---|---|
| `episode_machine_stops.mp3` | 24-second excerpt from LibriVox "The Machine Stops" by E. M. Forster, public domain. Includes generated embedded cover art for `fetchAlbumCover`. |
| `episode_electricity.mp3` | 24-second excerpt from LibriVox "Twenty Thousand Leagues Under the Sea" by Jules Verne, chapter "Everything through Electricity", public domain. Includes generated embedded cover art for `fetchAlbumCover`. |
| `sfx_tap.ogg` | OpenGameArt "Beep Sound" by Test User, CC0. |
| `sfx_skip.ogg` | OpenGameArt "Ping pong sounds" by Aj_, CC0. |
| `sfx_chime.ogg` | OpenGameArt "Win Jingle" by Fupi, CC0. |
