param([string]$OutputDir = "Z:\", [string]$ImageIds = "0900c8af8005c987,0900c8af80054d55,0900c8af800547da,0900c8af8005b0ac")

$ids = $ImageIds.Split(",")
$connStr = "Server=.\VIDA;Integrated Security=SSPI;Database=imagerepository;Connection Timeout=60;Command Timeout=120"
$conn = New-Object System.Data.SqlClient.SqlConnection($connStr)
$conn.Open()

foreach ($imgid in $ids) {
    $sql = "SELECT TOP 1 imageData FROM LocalizedGraphics WHERE fkGraphic = '$imgid' ORDER BY DATALENGTH(imageData) DESC"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($sql, $conn)
    $cmd.CommandTimeout = 120
    $reader = $cmd.ExecuteReader()
    if ($reader.Read()) {
        $len = [int]$reader.GetBytes(0, 0, $null, 0, 0)
        $bytes = New-Object byte[] $len
        $reader.GetBytes(0, 0, $bytes, 0, $len) | Out-Null
        $outpath = Join-Path $OutputDir "$imgid.gif"
        [System.IO.File]::WriteAllBytes($outpath, $bytes)
        Write-Host "OK $imgid.gif ($len bytes)"
    } else {
        Write-Host "NOT FOUND: $imgid"
    }
    $reader.Close()
}
$conn.Close()
Write-Host "Done."
