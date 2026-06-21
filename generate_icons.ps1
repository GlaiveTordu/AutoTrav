Add-Type -AssemblyName System.Drawing

function Save-Icon($name, $drawAction) {
    $bmp = New-Object System.Drawing.Bitmap(24, 24)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $goldColor = [System.Drawing.Color]::FromArgb(229, 193, 128) # E5C180
    $pen = New-Object System.Drawing.Pen($goldColor, 2.0)
    $brush = New-Object System.Drawing.SolidBrush($goldColor)
    
    $drawAction.Invoke($g, $pen, $brush)
    
    $pen.Dispose()
    $brush.Dispose()
    $g.Dispose()
    
    $bmp.Save("c:\Users\quent\Desktop\ScriptDofus\$name", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

# 1. cycle.png (Circular arrow)
Save-Icon "cycle.png" {
    param($g, $pen, $brush)
    # Draw arc
    $rect = New-Object System.Drawing.RectangleF(3.5, 3.5, 17, 17)
    $g.DrawArc($pen, $rect, -45, 270)
    # Draw arrowhead
    $points = @(
        (New-Object System.Drawing.PointF(12, 0)),
        (New-Object System.Drawing.PointF(18, 5)),
        (New-Object System.Drawing.PointF(12, 10))
    )
    $g.FillPolygon($brush, $points)
}

# 2. invite.png (Group Invite - two users)
Save-Icon "invite.png" {
    param($g, $pen, $brush)
    # Back user
    $g.FillEllipse($brush, 11, 2, 6, 6) # Head
    $g.DrawArc($pen, 7, 9, 14, 11, 180, 180) # Shoulders
    # Front user
    $g.FillEllipse($brush, 5, 5, 7, 7) # Head
    $g.DrawArc($pen, 1, 13, 15, 12, 180, 180) # Shoulders
}

# 3. trade.png (Exchange - two opposite arrows)
Save-Icon "trade.png" {
    param($g, $pen, $brush)
    # Top arrow (pointing right)
    $g.DrawLine($pen, 2, 7, 18, 7)
    $pointsRight = @(
        (New-Object System.Drawing.PointF(15, 3)),
        (New-Object System.Drawing.PointF(21, 7)),
        (New-Object System.Drawing.PointF(15, 11))
    )
    $g.FillPolygon($brush, $pointsRight)
    
    # Bottom arrow (pointing left)
    $g.DrawLine($pen, 22, 17, 6, 17)
    $pointsLeft = @(
        (New-Object System.Drawing.PointF(9, 13)),
        (New-Object System.Drawing.PointF(3, 17)),
        (New-Object System.Drawing.PointF(9, 21))
    )
    $g.FillPolygon($brush, $pointsLeft)
}

# 4. pause.png (Pause)
Save-Icon "pause.png" {
    param($g, $pen, $brush)
    $g.FillRectangle($brush, 6, 4, 4, 16)
    $g.FillRectangle($brush, 14, 4, 4, 16)
}

# 5. play.png (Play)
Save-Icon "play.png" {
    param($g, $pen, $brush)
    $points = @(
        (New-Object System.Drawing.PointF(6, 4)),
        (New-Object System.Drawing.PointF(19, 12)),
        (New-Object System.Drawing.PointF(6, 20))
    )
    $g.FillPolygon($brush, $points)
}
