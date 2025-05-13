# T-Minus-15 File Renaming Script
# Lists files and directories that need to be renamed to kebab-case

# Root directory
$rootPath = $PSScriptRoot

# Function to convert to kebab-case
function ConvertToKebabCase($name) {
    $kebabCase = $name -creplace '(?<!^)(?=[A-Z])', '-'
    return $kebabCase.ToLower()
}

# Files to ignore
$ignoreList = @(
    "list-files-to-rename.ps1",
    "simple-kebab-rename.ps1",
    "kebab-case-converter.ps1",
    "rename-files-to-kebab.ps1",
    "preview-rename.ps1",
    "rename-to-kebab-case.ps1",
    "Book.asciidoc",
    "README.md",
    ".git"
)

# Get all files
Write-Host "Files to rename to kebab-case:" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Check files
$files = Get-ChildItem -Path $rootPath -File -Recurse
foreach ($file in $files) {
    # Skip ignored files
    if ($ignoreList -contains $file.Name) { continue }
    
    # Skip files already in kebab-case
    if ($file.BaseName -cmatch "^[a-z0-9]+(-[a-z0-9]+)*$") { continue }
    
    # Get the new name
    $newName = ConvertToKebabCase -name $file.BaseName
    $newFileName = $newName + $file.Extension
    
    Write-Host "Current: $($file.Name)"
    Write-Host "New:     $newFileName"
    Write-Host "Path:    $($file.DirectoryName)"
    Write-Host "----------------------------" -ForegroundColor Cyan
}

# Check directories
Write-Host "`nDirectories to rename to kebab-case:" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

$dirs = Get-ChildItem -Path $rootPath -Directory -Recurse
foreach ($dir in $dirs) {
    # Skip ignored directories
    if ($ignoreList -contains $dir.Name) { continue }
    
    # Skip directories already in kebab-case
    if ($dir.Name -cmatch "^[a-z0-9]+(-[a-z0-9]+)*$") { continue }
    
    # Get the new name
    $newName = ConvertToKebabCase -name $dir.Name
    
    Write-Host "Current: $($dir.Name)"
    Write-Host "New:     $newName"
    Write-Host "Path:    $($dir.Parent.FullName)"
    Write-Host "----------------------------" -ForegroundColor Yellow
}

Write-Host "`nTo rename these files, you can use the following command:"
Write-Host "powershell -ExecutionPolicy Bypass -File simple-kebab-rename.ps1 -Execute" -ForegroundColor Green
