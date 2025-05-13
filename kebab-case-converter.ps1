# Kebab Case Conversion Script for T-Minus-15 Project
# This script converts PascalCase file and folder names to kebab-case

param (
    [switch]$Execute = $false
)

Write-Host "T-Minus-15 Kebab Case Converter" -ForegroundColor Cyan
Write-Host "----------------------------------" -ForegroundColor Cyan
Write-Host "This script will convert PascalCase file and folder names to kebab-case."
Write-Host ""

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

# List of files and folders to ignore (already kebab-case or special files)
$ignoreList = @(
    "kebab-case-converter.ps1",
    "rename-files-to-kebab.ps1",
    "preview-rename.ps1",
    "rename-to-kebab-case.ps1",
    "rename-log.txt",
    "book.asciidoc",
    "Book.asciidoc",
    "README.md",
    ".git"
)

# Array to store items to be renamed
$itemsToRename = @()

# Process directories first, from deepest to shallowest
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

# Process files
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

# Process top-level directories separately
Get-ChildItem -Path $rootPath -Directory | ForEach-Object {
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
    
    # Check if not already in the list
    if ($newName -ne $dirName -and -not ($itemsToRename | Where-Object { $_.Path -eq $dirPath })) {
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
    Write-Host "Items that would be renamed to kebab-case:" -ForegroundColor Yellow
    Write-Host "----------------------------------" -ForegroundColor Yellow
    
    $itemsToRename | ForEach-Object {
        $relativePath = $_.Path.Replace($rootPath, "").TrimStart('\')
        Write-Host "[$($_.Type)] $relativePath" -NoNewline
        Write-Host " → " -ForegroundColor Cyan -NoNewline
        Write-Host "$($_.NewName)" -ForegroundColor Green
    }
    
    Write-Host "----------------------------------" -ForegroundColor Yellow
    Write-Host "Total: $($itemsToRename.Count) items" -ForegroundColor Yellow
    Write-Host ""
    
    # Execute the renaming if requested
    if ($Execute) {
        $confirmation = Read-Host "Do you want to proceed with renaming these items? (Y/N)"
        if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
            $successCount = 0
            $errorLog = @()
            
            # Create a log file
            $logFile = Join-Path -Path $rootPath -ChildPath "rename-log.txt"
            "Renaming log - $(Get-Date)" | Out-File -FilePath $logFile -Force
            
            # Rename files first (less likely to cause issues)
            $itemsToRename | Where-Object { $_.Type -eq "File" } | ForEach-Object {
                $oldPath = $_.Path
                $newPath = Join-Path -Path $_.ParentPath -ChildPath $_.NewName
                
                try {
                    Write-Host "Renaming: $($_.OldName) → $($_.NewName)" -NoNewline
                    Rename-Item -Path $oldPath -NewName $_.NewName -ErrorAction Stop
                    Write-Host " ✓" -ForegroundColor Green
                    "SUCCESS: [$($_.Type)] $($_.Path) → $newPath" | Out-File -FilePath $logFile -Append
                    $successCount++
                }
                catch {
                    Write-Host " ✗" -ForegroundColor Red
                    "ERROR: [$($_.Type)] $($_.Path) → $newPath - $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
                    $errorLog += "Failed to rename $($_.OldName): $($_.Exception.Message)"
                }
            }
            
            # Then rename directories from deepest to shallowest
            $itemsToRename | Where-Object { $_.Type -eq "Directory" } | Sort-Object { ($_.Path.Split('\').Count) } -Descending | ForEach-Object {
                $oldPath = $_.Path
                $newPath = Join-Path -Path $_.ParentPath -ChildPath $_.NewName
                
                try {
                    Write-Host "Renaming: $($_.OldName) → $($_.NewName)" -NoNewline
                    Rename-Item -Path $oldPath -NewName $_.NewName -ErrorAction Stop
                    Write-Host " ✓" -ForegroundColor Green
                    "SUCCESS: [$($_.Type)] $($_.Path) → $newPath" | Out-File -FilePath $logFile -Append
                    $successCount++
                }
                catch {
                    Write-Host " ✗" -ForegroundColor Red
                    "ERROR: [$($_.Type)] $($_.Path) → $newPath - $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
                    $errorLog += "Failed to rename $($_.OldName): $($_.Exception.Message)"
                }
            }
            
            # Summary
            Write-Host ""
            Write-Host "Renaming complete: $successCount of $($itemsToRename.Count) items renamed successfully" -ForegroundColor Cyan
            
            if ($errorLog.Count -gt 0) {
                Write-Host "Errors encountered:" -ForegroundColor Red
                $errorLog | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
            }
            
            Write-Host "Log file created at: $logFile" -ForegroundColor Cyan
        }
        else {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "This was just a preview. To execute the renaming operation, run this script with the -Execute parameter:" -ForegroundColor Cyan
        Write-Host "  powershell -ExecutionPolicy Bypass -File kebab-case-converter.ps1 -Execute" -ForegroundColor Cyan
    }
}
