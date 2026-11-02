# Lock screen art

The woman, her arm and her hand on the lock screen come from this folder. The ones here
are placeholders, waiting for the real illustrations.

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
- `arc`: the angles of the first and last star of a row. `step` is the gap between two
  stars, `rowGap` how far in the next row sits once one is full.

To check your art without locking anything: `qs ipc -p . call lock preview`, then type.
Escape leaves the preview. `qs ipc -p . call lock press` adds a star from the terminal.
