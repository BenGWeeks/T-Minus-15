param (
    [string]$rootPath = $PSScriptRoot,
    [switch]$executeRename = $false
)

function Convert-ToPascalCase {
    param (
        [string]$text
    )
    return (Get-Culture).TextInfo.ToTitleCase($text.ToLower().Replace('-', ' ')).Replace(' ', '')
}

function Convert-ToKebabCase {
    param (
        [string]$text
    )
    # Convert PascalCase or camelCase to kebab-case
    $kebabCase = $text -creplace '(?<!^)(?=[A-Z])', '-'
    return $kebabCase.ToLower()
}

function Get-FilesToRename {
    param (
        [string]$path
    )
    
    $filesToRename = @()
    
    # Get all files and directories recursively
    $allItems = Get-ChildItem -Path $path -Recurse -Force
    
    foreach ($item in $allItems) {
        $fileName = $item.Name
        $baseName = $item.BaseName
        $extension = $item.Extension
        
        # Skip if already in kebab-case or special files
        if ($baseName -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or 
            $fileName -eq "rename-files-to-kebab.ps1" -or 
            $fileName -eq "preview-rename.ps1" -or 
            $fileName -eq "rename-to-kebab-case.ps1" -or
            $baseName -eq "README" -or
            $fileName -eq "Book.asciidoc" -or
            $fileName -eq "LICENSE") {
            continue
        }
        
        # Convert to kebab-case
        $newBaseName = Convert-ToKebabCase -text $baseName
        $newName = if ($extension) { "$newBaseName$extension" } else { $newBaseName }
        
        if ($newName -ne $fileName) {
            $filesToRename += [PSCustomObject]@{
                Path = $item.FullName
                CurrentName = $fileName
                NewName = $newName
                IsDirectory = $item -is [System.IO.DirectoryInfo]
                Level = ($item.FullName.Split([IO.Path]::DirectorySeparatorChar).Count)
            }
        }
    }
    
    # Also check top-level directories
    Get-ChildItem -Path $path -Directory | ForEach-Object {
        $dirName = $_.Name
        
        # Skip if already in kebab-case
        if ($dirName -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            return
        }
        
        $newName = Convert-ToKebabCase -text $dirName
        
        if ($newName -ne $dirName) {
            $filesToRename += [PSCustomObject]@{
                Path = $_.FullName
                CurrentName = $dirName
                NewName = $newName
                IsDirectory = $true
                Level = 1
            }
        }
    }
    
    return $filesToRename | Sort-Object -Property @{Expression="IsDirectory"; Descending=$false}, @{Expression="Level"; Descending=$true}
}

# Get list of files to rename
$filesToRename = Get-FilesToRename -path $rootPath

# Display preview
Write-Host "Files and folders that would be renamed to kebab-case:" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor Cyan

$filesToRename | ForEach-Object {
    $dir = Split-Path -Parent $_.Path
    Write-Host "Would rename: '$($_.CurrentName)' -> '$($_.NewName)' in $dir"
}

Write-Host "--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Total items to rename: $($filesToRename.Count)" -ForegroundColor Cyan
Write-Host ""

# Execute renaming if requested
if ($executeRename) {
    $confirmation = Read-Host "Are you sure you want to rename these $($filesToRename.Count) items? (y/n)"
    
    if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
        $log = @()
        $successCount = 0
        
        # First rename files (they're less likely to cause issues)
        $filesToRename | Where-Object { -not $_.IsDirectory } | ForEach-Object {
            $dir = Split-Path -Parent $_.Path
            $oldFullPath = $_.Path
            $newFullPath = Join-Path -Path $dir -ChildPath $_.NewName
            
            try {
                Rename-Item -Path $oldFullPath -NewName $_.NewName -ErrorAction Stop
                $log += "Renamed: '$($_.CurrentName)' -> '$($_.NewName)' in $dir"
                Write-Host "Renamed: '$($_.CurrentName)' -> '$($_.NewName)'" -ForegroundColor Green
                $successCount++
            }
            catch {
                $log += "Failed to rename: '$($_.CurrentName)' -> '$($_.NewName)' in $dir. Error: $($_.Exception.Message)"
                Write-Host "Failed to rename: '$($_.CurrentName)' -> '$($_.NewName)'. Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Then rename directories in reverse order of path depth (to avoid path issues)
        $filesToRename | Where-Object { $_.IsDirectory } | Sort-Object -Property Level -Descending | ForEach-Object {
            $dir = Split-Path -Parent $_.Path
            $oldFullPath = $_.Path
            $newFullPath = Join-Path -Path $dir -ChildPath $_.NewName
            
            try {
                Rename-Item -Path $oldFullPath -NewName $_.NewName -ErrorAction Stop
                $log += "Renamed: '$($_.CurrentName)' -> '$($_.NewName)' in $dir"
                Write-Host "Renamed: '$($_.CurrentName)' -> '$($_.NewName)'" -ForegroundColor Green
                $successCount++
            }
            catch {
                $log += "Failed to rename: '$($_.CurrentName)' -> '$($_.NewName)' in $dir. Error: $($_.Exception.Message)"
                Write-Host "Failed to rename: '$($_.CurrentName)' -> '$($_.NewName)'. Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        # Save log to file
        $log | Out-File -FilePath (Join-Path -Path $rootPath -ChildPath "rename-log.txt") -Force
        
        Write-Host ""
        Write-Host "Successfully renamed $successCount out of $($filesToRename.Count) items" -ForegroundColor Cyan
        Write-Host "Log saved to '$(Join-Path -Path $rootPath -ChildPath "rename-log.txt")'"
    }
    else {
        Write-Host "Renaming operation canceled" -ForegroundColor Yellow
    }
}
else {
    Write-Host "This was only a preview. To execute the rename operation, run this script with the -executeRename parameter:" -ForegroundColor Yellow
    Write-Host "  powershell -ExecutionPolicy Bypass -File rename-files-to-kebab.ps1 -executeRename" -ForegroundColor Yellow
}
