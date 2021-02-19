param (
    [string]$ZipFile = $(throw "-ZipFile is required"),
    [string]$ExtractDirectory = $(throw "-ExtractDirectory is required")
)

Add-Type -A System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $ExtractDirectory)