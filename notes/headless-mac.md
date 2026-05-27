# Tuning macOS for a headless ds4-server box

The Mac that runs `ds4-server` ships with macOS defaults tuned for an interactive desktop, even when no display is attached. Several of those defaults waste CPU and battery on a headless setup.

Symptoms that point here: load average creeping up with nothing obvious running, `WindowServer` near the top of `ps`, `coreaudiod` spiking, fans audible.

## Wallpaper

macOS will faithfully animate a dynamic wallpaper for a display nobody is watching. The cost:

- `WindowServer` ~13-15% CPU (composites the animation frame by frame)
- `WallpaperVideoExtension` ~5% CPU (decodes the video)
- `VTDecoderXPCService` + `VTEncoderXPCService` ~3-5% CPU combined (video toolbox round trip)

Fix: screen-share in and pick a **static image** in System Settings -> Wallpaper. Anything without a play icon or "Dynamic" label.

Gotchas:
- Old wallpaper extensions do not die when you change wallpapers. They leak. After switching, `pkill -9 -f WallpaperVideoExtension WallpaperSequoiaExtension` (or whichever ones are stale per `ps -ef | grep -i wallpaper`).
- "Sequoia" themed wallpapers are also animated (`WallpaperSequoiaExtension`). Picking another "Sequoia" option does not help. Use a flat image.

## Bluetooth audio devices

If AirPods (or any BT headphones) are paired as the default input/output, `coreaudiod` keeps a low-power audio link alive even when nothing is playing. Sample-rate conversion across BT (e.g. 24 kHz input, 48 kHz output) is not free.

Fix: either turn off Bluetooth entirely on the headless box, or set default I/O to the Mac's built-in speakers/mic in System Settings -> Sound. Pair-and-forget your headphones from a different machine.

## coreaudiod is heisenberg-y

Polling audio state from outside (`system_profiler SPAudioDataType`, `osascript -e 'tell app "System Events"...'`) wakes `coreaudiod` to read the data, and that read itself shows up as 60%+ CPU on `coreaudiod` for the duration of the call. Do not diagnose `coreaudiod` load by running tools that ask `coreaudiod` for state — you will measure your own probe. Use `ps -o pcpu` snapshots over a few seconds instead.

## Docker VM overhead

Docker Desktop on Apple Silicon runs containers inside an Apple Virtualization.framework VM. The VM process (`com.apple.Virtualization.VirtualMachine`) commonly sits at 50-100% CPU even when containers are quiet — that is the cost of the VM doing scheduling, paging, and IO virtualization, not your containers misbehaving.

Implication: `docker stats` shows per-container CPU but understates total cost because the VM overhead is invisible to it. When `top` flags the VM, sum up the busy containers via `docker stats --no-stream` to attribute it. Idle containers can still be stopped (`docker stop <name>`) to reduce VM background work.

## Quick triage checklist

When the box feels sluggish:

1. `uptime` — if 1-min load is >2x core count, real work is happening
2. `ps -Ao pcpu,user,pid,comm | sort -rn | head -10` — who is on top?
3. If `WindowServer` is in the top 3 on a headless box, suspect dynamic wallpaper.
4. If `coreaudiod` is high without screen-share audio in use, suspect BT.
5. If `Virtualization.VirtualMachine` is high, do `docker stats --no-stream` to attribute.
6. `vm_stat | head -5` — free pages times page size (16384 on Apple Silicon). Less than ~500 MB free means memory pressure even without swap.

## Login session

A logged-in console user (`who` shows `console`) is required for screen sharing to work at all and for any GUI app to run. There is no benefit to logging out for headless operation, but be aware that the console session is what spawns most of these user-space helpers (wallpaper, sound, etc).
