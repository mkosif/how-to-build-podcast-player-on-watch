# rawfile assets

The services read bundled audio assets from this folder through
`context.resourceManager.getRawFd(...)`. Drop matching files in to enable each
feature; missing files are tolerated and the codelab still demonstrates the
common-event flow when they are absent.

## Expected files

| File | Used by | Purpose |
|---|---|---|
| `sample_episode.mp3` | `AudioPlayerService`, `MetadataService` | Bundled podcast episode for the rawfile `AVFileDescriptor` path. `AVMetadataExtractor` also reads its title, duration, and album cover. |
| `sfx_tap.ogg` | `SoundEffectService` | Short tap feedback played on every button press. |
| `sfx_skip.ogg` | `SoundEffectService` | Skip-forward / skip-back feedback. |
| `sfx_chime.ogg` | `SoundEffectService` | Completion chime played when an episode ends. |

Use any CC0 / royalty-free audio you like. Keep the sfx files under ~200 ms
for the latency benefits SoundPool is designed for.
