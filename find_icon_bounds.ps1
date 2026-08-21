Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::new('C:\Users\gadip\.gemini\antigravity\brain\74bceb43-fd88-40d8-9146-e972001ce9cf\.user_uploaded\media_1787300028126.jpg')
$w = $src.Width
$h = $src.Height

# Background sample from top-left (e.g. 10, 10)
$bg = $src.GetPixel(10, 10)
Write-Output "BG color: R=$($bg.R), G=$($bg.G), B=$($bg.B)"

# Let's define the 6 grid cells approximately:
# Row 0: y from 20 to 330
# Row 1: y from 340 to 660
# Col 0: x from 20 to 350
# Col 1: x from 350 to 680
# Col 2: x from 680 to 1000

$cells = @(
    @{ name="personal_growth"; x1=20; y1=20; x2=350; y2=330 },
    @{ name="career"; x1=350; y1=20; x2=680; y2=330 },
    @{ name="studies"; x1=680; y1=20; x2=1000; y2=330 },
    @{ name="calendar"; x1=20; y1=340; x2=350; y2=660 },
    @{ name="priority"; x1=350; y1=340; x2=680; y2=660 },
    @{ name="analytics"; x1=680; y1=340; x2=1000; y2=660 }
)

foreach ($c in $cells) {
    $minX = 9999; $maxX = -1; $minY = 9999; $maxY = -1
    for ($y = $c.y1; $y -lt $c.y2; $y++) {
        for ($x = $c.x1; $x -lt $c.x2; $x++) {
            $p = $src.GetPixel($x, $y)
            # Distance from background color
            $dist = [Math]::Sqrt([Math]::Pow($p.R - $bg.R, 2) + [Math]::Pow($p.G - $bg.G, 2) + [Math]::Pow($p.B - $bg.B, 2))
            if ($dist -gt 25) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    Write-Output "$($c.name): Bounding Box -> X: $minX..$maxX (W: $($maxX - $minX + 1)), Y: $minY..$maxY (H: $($maxY - $minY + 1))"
}
