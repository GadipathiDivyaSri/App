Add-Type -AssemblyName System.Drawing

$srcPath = 'C:\Users\gadip\.gemini\antigravity\brain\74bceb43-fd88-40d8-9146-e972001ce9cf\.user_uploaded\media_1787300028126.jpg'
$src = [System.Drawing.Bitmap]::new($srcPath)

# Ensure directories exist
$dirs = @(
    "assets/icons",
    "web/assets/icons",
    "build/web/assets/assets/icons",
    "build/web/assets/icons"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

$icons = @(
    @{ name="ic_personal_growth"; minX=62; maxX=308; minY=70; maxY=296 },
    @{ name="ic_career"; minX=410; maxX=612; minY=76; maxY=280 },
    @{ name="ic_studies"; minX=750; maxX=948; minY=108; maxY=250 },
    @{ name="ic_calendar"; minX=58; maxX=304; minY=402; maxY=624 },
    @{ name="ic_priority"; minX=432; maxX=590; minY=410; maxY=616 },
    @{ name="ic_analytics"; minX=764; maxX=940; minY=424; maxY=604 }
)

# Background color sampling
$bgR = 255.0; $bgG = 254.0; $bgB = 246.0

foreach ($ic in $icons) {
    $w = $ic.maxX - $ic.minX + 1
    $h = $ic.maxY - $ic.minY + 1
    $dim = [Math]::Max($w, $h) + 16
    $cx = ($ic.minX + $ic.maxX) / 2.0
    $cy = ($ic.minY + $ic.maxY) / 2.0
    
    $startX = [int]($cx - $dim / 2.0)
    $startY = [int]($cy - $dim / 2.0)
    
    # Create cropped bitmap
    $cropBmp = [System.Drawing.Bitmap]::new($dim, $dim, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    $thresh1 = 18.0
    $thresh2 = 42.0
    
    for ($y = 0; $y -lt $dim; $y++) {
        for ($x = 0; $x -lt $dim; $x++) {
            $srcX = $startX + $x
            $srcY = $startY + $y
            
            if ($srcX -ge 0 -and $srcX -lt $src.Width -and $srcY -ge 0 -and $srcY -lt $src.Height) {
                $p = $src.GetPixel($srcX, $srcY)
                
                # Check for white inside calendar or icons
                # Only make background transparent if outside or if close to bg tint
                $dist = [Math]::Sqrt([Math]::Pow($p.R - $bgR, 2) + [Math]::Pow($p.G - $bgG, 2) + [Math]::Pow($p.B - $bgB, 2))
                
                # If it's pure white (255, 255, 255) inside briefcase handle, calendar sheet, or arrow, preserve it
                $isWhite = ($p.R -ge 250 -and $p.G -ge 250 -and $p.B -ge 250)
                
                # Distance from center ratio to protect internal whites
                $distCenter = [Math]::Sqrt([Math]::Pow($x - $dim/2, 2) + [Math]::Pow($y - $dim/2, 2))
                $maxRadius = $dim * 0.45
                
                $alpha = 255
                if ($dist -lt $thresh1) {
                    $alpha = 0
                } elseif ($dist -lt $thresh2) {
                    $t = ($dist - $thresh1) / ($thresh2 - $thresh1)
                    $alpha = [int]($t * 255)
                }
                
                # Keep internal elements solid if surrounded by color
                if ($distCenter -lt ($dim * 0.35) -and ($p.R -gt 240 -and $p.G -gt 240 -and $p.B -gt 240)) {
                    # For calendar page, briefcase handle, or zigzag line, keep opaque
                    if ($ic.name -eq "ic_calendar" -or $ic.name -eq "ic_career" -or $ic.name -eq "ic_personal_growth") {
                        # If within internal bounding box, keep white opaque
                        if ($srcX -gt ($ic.minX + 15) -and $srcX -lt ($ic.maxX - 15) -and $srcY -gt ($ic.minY + 15) -and $srcY -lt ($ic.maxY - 15)) {
                            $alpha = 255
                        }
                    }
                }
                
                $color = [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B)
                $cropBmp.SetPixel($x, $y, $color)
            } else {
                $cropBmp.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            }
        }
    }
    
    # Scale to high-res 256x256 with high quality interpolation
    $finalBmp = [System.Drawing.Bitmap]::new(256, 256, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($finalBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($cropBmp, 0, 0, 256, 256)
    $g.Dispose()
    $cropBmp.Dispose()
    
    # Save to all target paths
    foreach ($d in $dirs) {
        $outPath = "$d/$($ic.name).png"
        $finalBmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output "Saved: $outPath"
    }
    $finalBmp.Dispose()
}
$src.Dispose()
Write-Output "ALL ICONS EXTRACTED SUCCESSFULLY!"
