# T-Minus-15 Simple Kebab Case Converter
# This script finds and converts PascalCase file and folder names to kebab-case

param (
    [switch]$Execute = $false
)

# Define the project root path
$rootPath = $PSScriptRoot

# Function to convert PascalCase to kebab-case
function ConvertTo-KebabCase($text) {
    if ($text -match "-") {
        # Already contains hyphens, handle carefully
        return $text.ToLower()
    }
    
    # Convert PascalCase or camelCase to kebab-case
    $kebabCase = $text -creplace '(?<!^)(?=[A-Z])', '-'
    return $kebabCase.ToLower()
}

# List of files and folders to ignore
$ignoreList = @(
    "simple-kebab-rename.ps1",
    "kebab-case-converter.ps1",
    "rename-files-to-kebab.ps1",
    "preview-rename.ps1",
    "rename-to-kebab-case.ps1",
    "rename-log.txt",
    "Book.asciidoc",
    "README.md",
    ".git"
)

# Array to store items to be renamed
$itemsToRename = @()

# Find all files that need to be renamed
Write-Host "Scanning for files to rename..." -ForegroundColor Cyan
Get-ChildItem -Path $rootPath -File -Recurse | ForEach-Object {
    $fileName = $_.Name
    $filePath = $_.FullName
    $ext = $_.Extension
    $baseName = $_.BaseName
    
    # Skip if the file should be ignored
    if ($ignoreList -contains $fileName) {
        return
    }
    
    # Skip if already in kebab-case
    if ($baseName -cmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        return
    }
    
    $newBaseName = ConvertTo-KebabCase -text $baseName
    $newName = $newBaseName + $ext
    
    # Add to list if the name would change
    if ($newName -ne $fileName) {
        $itemsToRename += [PSCustomObject]@{
            Type = "File"
            Path = $filePath
            OldName = $fileName
            NewName = $newName
            ParentPath = Split-Path -Path $filePath -Parent
        }
    }
}

# Find all directories that need to be renamed, from deepest to shallowest
Write-Host "Scanning for directories to rename..." -ForegroundColor Cyan
Get-ChildItem -Path $rootPath -Directory -Recurse | Sort-Object { ($_.FullName.Split('\').Count) } -Descending | ForEach-Object {
    $dirName = $_.Name
    $dirPath = $_.FullName
    
    # Skip if the folder should be ignored
    if ($ignoreList -contains $dirName) {
        return
    }
    
    # Skip if already in kebab-case
    if ($dirName -cmatch "^[a-z0-9]+(-[a-z0-9]+)*$") {
        return
    }
    
    $newName = ConvertTo-KebabCase -text $dirName
    
    # Add to list if the name would change
    if ($newName -ne $dirName) {
        $itemsToRename += [PSCustomObject]@{
            Type = "Directory"
            Path = $dirPath
            OldName = $dirName
            NewName = $newName
            ParentPath = Split-Path -Path $dirPath -Parent
        }
    }
}

# Display preview
if ($itemsToRename.Count -eq 0) {
    Write-Host "No items need to be renamed. All files and folders already follow kebab-case naming convention." -ForegroundColor Green
}
else {
    Write-Host "`nItems that would be renamed to kebab-case:" -ForegroundColor Yellow
    Write-Host "------------------------------------------" -ForegroundColor Yellow
    
    $itemsToRename | ForEach-Object {
        $relativePath = $_.Path.Replace($rootPath, "").TrimStart('\')
        Write-Host "[$($_.Type)] $relativePath"
        Write-Host "    $($_.OldName) => $($_.NewName)" -ForegroundColor Green
    }
    
    Write-Host "------------------------------------------" -ForegroundColor Yellow
    Write-Host "Total: $($itemsToRename.Count) items would be renamed" -ForegroundColor Yellow
    Write-Host ""
    
    # Execute the renaming if requested
    if ($Execute) {
            $successCount = 0
            $errorCount = 0
            
            # Create a log file
            $logFile = Join-Path -Path $rootPath -ChildPath "rename-log.txt"
            "Renaming log - $(Get-Date)" | Out-File -FilePath $logFile -Force
            
            # Rename files first
            Write-Host "`nRenaming files..." -ForegroundColor Cyan
            $itemsToRename | Where-Object { $_.Type -eq "File" } | ForEach-Object {
                $oldPath = $_.Path
                
                try {
                    Write-Host "Renaming: $($_.OldName) to $($_.NewName)"
                    Rename-Item -Path $oldPath -NewName $_.NewName -ErrorAction Stop
                    "SUCCESS: [File] $($_.Path) to $($_.NewName)" | Out-File -FilePath $logFile -Append
                    $successCount++
                }
                catch {
                    Write-Host "ERROR: Failed to rename $($_.OldName): $($_.Exception.Message)" -ForegroundColor Red
                    "ERROR: [File] $($_.Path) to $($_.NewName) - $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
                    $errorCount++
                }
            }
            
            # Then rename directories from deepest to shallowest
            Write-Host "`nRenaming directories..." -ForegroundColor Cyan
            $itemsToRename | Where-Object { $_.Type -eq "Directory" } | Sort-Object { ($_.Path.Split('\').Count) } -Descending | ForEach-Object {
                $oldPath = $_.Path
                
                try {
                    Write-Host "Renaming: $($_.OldName) to $($_.NewName)"
                    Rename-Item -Path $oldPath -NewName $_.NewName -ErrorAction Stop
                    "SUCCESS: [Directory] $($_.Path) to $($_.NewName)" | Out-File -FilePath $logFile -Append
                    $successCount++
                }
                catch {
                    Write-Host "ERROR: Failed to rename $($_.OldName): $($_.Exception.Message)" -ForegroundColor Red
                    "ERROR: [Directory] $($_.Path) to $($_.NewName) - $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
                    $errorCount++
                }
            }
            
            # Summary
            Write-Host "`nRenaming complete:" -ForegroundColor Cyan
            Write-Host "- $successCount of $($itemsToRename.Count) items renamed successfully" -ForegroundColor Green
            if ($errorCount -gt 0) {
                Write-Host "- $errorCount items failed to rename" -ForegroundColor Red
            }
            Write-Host "- Log file created at: $logFile" -ForegroundColor Cyan

    }
    else {
        Write-Host "This was just a preview. To execute the renaming operation, run this script with the -Execute parameter:" -ForegroundColor Cyan
        Write-Host "  powershell -ExecutionPolicy Bypass -File simple-kebab-rename.ps1 -Execute" -ForegroundColor Cyan
    }
}
