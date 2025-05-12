# Script to rename image files from spaces to CamelCase and update references
$mappings = @{
    "Agile vs DevOps.png" = "AgileVsDevOps.png"
    "Agile vs DevOps.psd" = "AgileVsDevOps.psd"
    "Assessment and adoption.png" = "AssessmentAndAdoption.png"
    "Assessment and adoption.psd" = "AssessmentAndAdoption.psd"
    "Average company lifespan.png" = "AverageCompanyLifespan.png"
    "Bugs.png" = "Bugs.png"
    "Bugs.psd" = "Bugs.psd"
    "Burndown chart.png" = "BurndownChart.png"
    "Burndown chart.psd" = "BurndownChart.psd"
    "Designs.png" = "Designs.png"
    "Designs.psd" = "Designs.psd"
    "Estimating.png" = "Estimating.png"
    "Estimating.psd" = "Estimating.psd"
    "Gantt Chart.png" = "GanttChart.png"
    "Gantt Chart.psd" = "GanttChart.psd"
    "GitFlow.png" = "GitFlow.png"
    "Idea to Production.png" = "IdeaToProduction.png"
    "Infinity Lifecycle (Book).png" = "InfinityLifecycleBook.png"
    "Infinity Lifecycle (Book).psd" = "InfinityLifecycleBook.psd"
    "Iterative Improvement.png" = "IterativeImprovement.png"
    "Iterative Improvement.psd" = "IterativeImprovement.psd"
    "Lean Startup.png" = "LeanStartup.png"
    "Product backlog.png" = "ProductBacklog.png"
    "Product backlog.psd" = "ProductBacklog.psd"
    "README.psd" = "README.psd"
    "Release Pipelines (Detailed Security).png" = "ReleasePipelinesDetailedSecurity.png"
    "Release Pipelines (Detailed).png" = "ReleasePipelinesDetailed.png"
    "Release Pipelines (Detailed).psd" = "ReleasePipelinesDetailed.psd"
    "Release Pipelines (Template).png" = "ReleasePipelinesTemplate.png"
    "Release Pipelines (Template).psd" = "ReleasePipelinesTemplate.psd"
    "Release Pipelines.png" = "ReleasePipelines.png"
    "Release Pipelines.psd" = "ReleasePipelines.psd"
    "Scrum.png" = "Scrum.png"
    "Scrum.psd" = "Scrum.psd"
    "Team Agility - T-Minus-15 Workshop - Quality.png" = "TeamAgilityTMinus15WorkshopQuality.png"
    "Test Plan.png" = "TestPlan.png"
    "Test Plan.psd" = "TestPlan.psd"
    "Value Delivery.png" = "ValueDelivery.png"
}

# Step 1: Rename image files
Write-Host "Renaming image files..."
$imagesDir = "Images"
foreach ($mapping in $mappings.GetEnumerator()) {
    $oldPath = Join-Path -Path $imagesDir -ChildPath $mapping.Key
    $newPath = Join-Path -Path $imagesDir -ChildPath $mapping.Value
    
    if (Test-Path $oldPath) {
        Write-Host "Renaming '$($mapping.Key)' to '$($mapping.Value)'..."
        Rename-Item -Path $oldPath -NewName $mapping.Value -Force
    } else {
        Write-Host "Warning: File '$oldPath' not found"
    }
}

# Step 2: Update all references in AsciiDoc files
Write-Host "Updating references in AsciiDoc files..."
$asciidocFiles = Get-ChildItem -Path "." -Filter "*.asciidoc" -Recurse

foreach ($file in $asciidocFiles) {
    Write-Host "Processing file: $($file.FullName)"
    $content = Get-Content -Path $file.FullName -Raw
    
    $modified = $false
    foreach ($mapping in $mappings.GetEnumerator()) {
        # Escape special characters for regex
        $oldNameEscaped = [regex]::Escape($mapping.Key)
        # Handle URL encoding (spaces as %20)
        $oldNameEncoded = $oldNameEscaped.Replace("\ ", "%20")
        
        # Only update if it contains the string
        if ($content -match [regex]::Escape("Images/$oldNameEncoded") -or $content -match [regex]::Escape("Images/$oldNameEscaped")) {
            Write-Host "  Replacing '$($mapping.Key)' with '$($mapping.Value)' in $($file.Name)"
            $content = $content -replace [regex]::Escape("Images/$oldNameEncoded"), "Images/$($mapping.Value)"
            $content = $content -replace [regex]::Escape("Images/$oldNameEscaped"), "Images/$($mapping.Value)"
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $file.FullName -Value $content
        Write-Host "  Updated file: $($file.Name)"
    }
}

Write-Host "Image renaming complete!"
