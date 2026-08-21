Add-Type -AssemblyName System.Drawing

$srcDir = "C:\Users\gadip\.gemini\antigravity\brain\74bceb43-fd88-40d8-9146-e972001ce9cf\.user_uploaded"

$images = @{
    "ic_personal_growth.png" = "$srcDir\media_1787301593787.png"
    "ic_career.png"          = "$srcDir\media_1787301619561.png"
    "ic_studies.png"         = "$srcDir\media_1787301640039.png"
    "ic_calendar.png"        = "$srcDir\media_1787301673118.png"
    "ic_priority.png"        = "$srcDir\media_1787301697587.png"
}

New-Item -ItemType Directory -Force -Path "assets\icons" | Out-Null
New-Item -ItemType Directory -Force -Path "web\assets\icons" | Out-Null
New-Item -ItemType Directory -Force -Path "build\web\assets\icons" | Out-Null
New-Item -ItemType Directory -Force -Path "build\web\assets\assets\icons" | Out-Null

function Process-Icon([string]$inPath, [string]$outName) {
    if (-not (Test-Path $inPath)) {
        Write-Warning "File not found: $inPath"
        return
    }
    
    $bmp = [System.Drawing.Bitmap]::FromFile($inPath)
    $w = $bmp.Width
    $h = $bmp.Height
    
    # Create clean transparent ARGB bitmap
    $outBmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    # Check background color sampled from outer 4 corners
    $c1 = $bmp.GetPixel(4, 4)
    $c2 = $bmp.GetPixel($w - 5, 4)
    $c3 = $bmp.GetPixel(4, $h - 5)
    $c4 = $bmp.GetPixel($w - 5, $h - 5)
    
    $bgR = ($c1.R + $c2.R + $c3.R + $c4.R) / 4
    $bgG = ($c1.G + $c2.G + $c3.G + $c4.G) / 4
    $bgB = ($c1.B + $c2.B + $c3.B + $c4.B) / 4
    
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $p = $bmp.GetPixel($x, $y)
            $dist = [Math]::Sqrt([Math]::Pow($p.R - $bgR, 2) + [Math]::Pow($p.G - $bgG, 2) + [Math]::Pow($p.B - $bgB, 2))
            
            if ($dist -lt 22 -or ($p.R -gt 240 -and $p.G -gt 238 -and $p.B -gt 230)) {
                # Transparent background
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } elseif ($dist -lt 40) {
                # Smooth antialiased border
                $alpha = [int]([Math]::Min(255, [Math]::Max(0, ($dist - 22) / 18 * 255)))
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
            } else {
                $outBmp.SetPixel($x, $y, $p)
            }
        }
    }
    
    # Save to all destination directories
    $targets = @(
        "assets\icons\$outName",
        "web\assets\icons\$outName",
        "build\web\assets\icons\$outName",
        "build\web\assets\assets\icons\$outName"
    )
    
    foreach ($t in $targets) {
        $outBmp.Save($t, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    
    $bmp.Dispose()
    $outBmp.Dispose()
    Write-Output "Processed: $outName ($w x $h)"
}

foreach ($k in $images.Keys) {
    Process-Icon -inPath $images[$k] -outName $k
}

# Also extract analytics from media_1787301312239.jpg if needed
$analyticsSrc = "$srcDir\media_1787301312239.jpg"
if (Test-Path $analyticsSrc) {
    $bmp = [System.Drawing.Bitmap]::FromFile($analyticsSrc)
    $w = $bmp.Width
    $h = $bmp.Height
    # Analytics is in bottom right quadrant: x ~ 0.68..0.98, y ~ 0.55..0.92
    $cropX = [int]($w * 0.70)
    $cropY = [int]($h * 0.58)
    $cropW = [int]($w * 0.26)
    $cropH = [int]($h * 0.35)
    
    $cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)
    $cropped = $bmp.Clone($cropRect, $bmp.PixelFormat)
    $bmp.Dispose()
    
    # Process transparency on cropped analytics
    $outBmp = New-Object System.Drawing.Bitmap($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $cropH; $y++) {
        for ($x = 0; $x -lt $cropW; $x++) {
            $p = $cropped.GetPixel($x, $y)
            if ($p.R -gt 240 -and $p.G -gt 238 -and $p.B -gt 230) {
                $outBmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } else {
                $outBmp.SetPixel($x, $y, $p)
            }
        }
    }
    $cropped.Dispose()
    
    $targets = @(
        "assets\icons\ic_analytics.png",
        "web\assets\icons\ic_analytics.png",
        "build\web\assets\icons\ic_analytics.png",
        "build\web\assets\assets\icons\ic_analytics.png"
    )
    foreach ($t in $targets) {
        $outBmp.Save($t, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    $outBmp.Dispose()
    Write-Output "Processed: ic_analytics.png"
}
