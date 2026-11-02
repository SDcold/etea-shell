# Lock screen art

The woman, her arm and her hand on the lock screen come from this folder. They are
traced from `Reaching Woman with Flowing Curls.png` (1024×1536, already cut out):

1. The PNG is split in two: the arm above the sleeve, given a stub that carries on under
   the sleeve so turning it never opens a gap, and the body without it.
2. The body is brightened (`magick body.png -channel RGB -gamma 2.4 +channel`), or the
   tracer merges the dark strands of hair into one black mass.
3. Both go through VectorCraft's Image Trace (colour, 16–24 colours, paths 85–88,
   corners 35, noise 3). The arm is turned 82° clockwise around the shoulder (745, 750)
   so it points right, and exported cropped to itself; the body keeps the full artboard.
4. `scripts/qt-svg.py traced.svg source.png out.svg [2.4]` brings the colours back down,
   breaks up the paths Qt is too small for, and seals the seams between shapes.

The clouds are still a placeholder.

- `body.svg` (or .png): the woman seen from behind. She sits in front and gets blurred.
- `arm.svg` (or .png): the arm and its open hand, drawn **pointing right**, with the
  shoulder end on the left. It turns around the shoulder to hide each new star.
- `scene.json`: where everything goes. Change the file names there if you use PNGs.

In `scene.json`, lengths are shares of the screen height and `x` is measured from the
middle of the screen, so the scene fits any screen.

- `body`: `x` of its centre, `bottom` edge, `height`, and how much `blur`.
- `arm`: its `width`, the `pivot` (the shoulder end, as a share of the image), and `hand`
  (where the middle of the hand is along the image, as a share of its width).
- `shoulder`: where the pivot lands on screen.
- `rest`: the arm's angle with no stars, in degrees. 0 points right, -90 points up.
- `follow`: how many stars her hand chases before it stays put and lets the rest shine.
- `arc`: the angles of the first and last star of a row. `step` is the gap between two
  stars, `rowGap` how far in the next row sits once one is full.

To check your art without locking anything: `qs ipc -p . call lock preview`, then type.
Escape leaves the preview. `qs ipc -p . call lock press` adds a star from the terminal.
