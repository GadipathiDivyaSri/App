Add-Type -AssemblyName System.Drawing
$srcPath = "C:\Users\ushma\.gemini\antigravity\brain\97162d54-0326-4a3b-8680-6508b970e95d\.user_uploaded\media_1790775459612.jpg"
$src = [System.Drawing.Image]::FromFile($srcPath)

$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

foreach ($folder in $sizes.Keys) {
    $sz = $sizes[$folder]
    $bmp = New-Object System.Drawing.Bitmap $sz, $sz
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($src, 0, 0, $sz, $sz)
    
    $outDir = "android/app/src/main/res/$folder"
    if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force }
    $outPath = "$outDir/ic_launcher.png"
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Generated $outPath ($sz x $sz)"
}

# Also save asset logo
$logoDir = "assets/images"
if (!(Test-Path $logoDir)) { New-Item -ItemType Directory -Path $logoDir -Force }
Copy-Item $srcPath "$logoDir/app_logo.png" -Force
Write-Host "Copied assets/images/app_logo.png"

$src.Dispose()
