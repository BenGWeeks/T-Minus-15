param (
    [string]$rootPath = $PSScriptRoot
)

function Convert-To-KebabCase {
    param (
        [string]$name
    )
    
    # For names that already contain dashes, handle carefully
    if ($name -match "-") {
        # Split by dash first, then convert each part
        $parts = $name -split "-"
        $kebabParts = @()
        
        foreach ($part in $parts) {
            # Convert each PascalCase part to kebab-case
            $kebabPart = [regex]::Replace($part, '(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])', '-$1')
            $kebabParts += $kebabPart.ToLower()
        }
        
        return ($kebabParts -join "-")
    }
    else {
        # Standard PascalCase or camelCase to kebab-case conversion
        $kebabCase = [regex]::Replace($name, '(?<!^)([A-Z][a-z]|(?<=[a-z])[A-Z])', '-$1')
        return $kebabCase.ToLower()
    }
}

function Rename-To-KebabCase {
    param (
        [string]$path,
        [switch]$whatIf
    )
    
    # Get files and folders in the current directory
    $items = @()
    
    # First process directories (bottom-up to avoid path issues)
    Get-ChildItem -Path $path -Directory -Recurse | Sort-Object -Property FullName -Descending | ForEach-Object {
        $items += $_
    }
    
    # Then process files
    Get-ChildItem -Path $path -File -Recurse | ForEach-Object {
        $items += $_
    }
    
    $log = @()
    $renamedCount = 0
    
    foreach ($item in $items) {
        $directory = Split-Path -Path $item.FullName -Parent
        $baseName = $item.BaseName
        $extension = if ($item.Extension) { $item.Extension } else { "" }
        
        # Skip files that already use kebab-case or are specific files to ignore
        if ($baseName -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or 
            $item.Name -eq "rename-to-kebab-case.ps1" -or 
            $baseName -eq "README" -or
            $item.Name -eq "Book.asciidoc") {
            continue
        }
        
        # Convert to kebab-case
        $newBaseName = Convert-To-KebabCase -name $baseName
        $newName = if ($extension) { "$newBaseName$extension" } else { $newBaseName }
        $newPath = Join-Path -Path $directory -ChildPath $newName
        
        if ($newPath -ne $item.FullName) {
            $action = if ($whatIf) { "Would rename" } else { "Renaming" }
            $logEntry = "${action}: '$($item.FullName)' to '$newPath'"
            Write-Host $logEntry
            $log += $logEntry
            
            if (-not $whatIf) {
                # Check if destination exists and handle accordingly
                if (Test-Path -Path $newPath) {
                    Write-Host "  Skipping: destination already exists" -ForegroundColor Yellow
                    $log += "  Skipped: destination already exists"
                    continue
                }
                
                try {
                    Rename-Item -Path $item.FullName -NewName $newName -ErrorAction Stop
                    $renamedCount++
                }
                catch {
                    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                    $log += "  Failed: $($_.Exception.Message)"
                }
            }
            else {
                $renamedCount++
            }
        }
    }
    
    # Now handle top-level folders
    Get-ChildItem -Path $path -Directory | ForEach-Object {
        $baseName = $_.Name
        
        # Skip folders that already use kebab-case
        if ($baseName -cmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            return
        }
        
        # Convert to kebab-case
        $newName = Convert-To-KebabCase -name $baseName
        $newPath = Join-Path -Path $path -ChildPath $newName
        
        if ($newPath -ne $_.FullName) {
            $action = if ($whatIf) { "Would rename" } else { "Renaming" }
            $logEntry = "${action}: '$($_.FullName)' to '$newPath'"
            Write-Host $logEntry
            $log += $logEntry
            
            if (-not $whatIf) {
                # Check if destination exists
                if (Test-Path -Path $newPath) {
                    Write-Host "  Skipping: destination already exists" -ForegroundColor Yellow
                    $log += "  Skipped: destination already exists"
                    return
                }
                
                try {
                    Rename-Item -Path $_.FullName -NewName $newName -ErrorAction Stop
                    $renamedCount++
                }
                catch {
                    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
                    $log += "  Failed: $($_.Exception.Message)"
                }
            }
            else {
                $renamedCount++
            }
        }
    }
    
    # Write log to file
    $logPath = Join-Path -Path $path -ChildPath "rename-log.txt"
    $log | Out-File -FilePath $logPath -Force
    
    return @{
        RenamedCount = $renamedCount
        LogPath = $logPath
    }
}

# First run in WhatIf mode to see what would change
Write-Host "Preview mode - showing what would be renamed:" -ForegroundColor Cyan
Write-Host "------------------------------------------------" -ForegroundColor Cyan
$previewResult = Rename-To-KebabCase -path $rootPath -whatIf
Write-Host "------------------------------------------------" -ForegroundColor Cyan
Write-Host "Would rename $($previewResult.RenamedCount) items" -ForegroundColor Cyan
Write-Host ""

# Ask for confirmation
$confirmation = Read-Host "Do you want to proceed with renaming these files? (Y/N)"
if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
    Write-Host "Proceeding with renaming..." -ForegroundColor Green
    $result = Rename-To-KebabCase -path $rootPath
    Write-Host "------------------------------------------------" -ForegroundColor Green
    Write-Host "Successfully renamed $($result.RenamedCount) items" -ForegroundColor Green
    Write-Host "Log file created at: $($result.LogPath)" -ForegroundColor Green
}
else {
    Write-Host "Operation cancelled" -ForegroundColor Yellow
}
