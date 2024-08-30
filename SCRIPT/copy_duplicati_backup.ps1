# Définir les chemins de la source et de la destination
$sourcePath = "Z:\"
$destinationPath = "C:\Backup Server\backups\"

# Obtenir les listes de fichiers des deux répertoires
$sourceFiles = Get-ChildItem -Path $sourcePath -Recurse
$destinationFiles = Get-ChildItem -Path $destinationPath -Recurse

# Créer des hashtables pour faciliter la comparaison
$sourceHash = @{}
$destinationHash = @{}

foreach ($file in $sourceFiles) {
    $relativePath = $file.FullName.Substring($sourcePath.Length)
    $sourceHash[$relativePath] = $file
}

foreach ($file in $destinationFiles) {
    $relativePath = $file.FullName.Substring($destinationPath.Length)
    $destinationHash[$relativePath] = $file
}

# Supprimer les fichiers de la destination qui ne sont pas dans la source
foreach ($relativePath in $destinationHash.Keys) {
    if (-not $sourceHash.ContainsKey($relativePath)) {
        $fileToDelete = $destinationHash[$relativePath].FullName
        Remove-Item -Path $fileToDelete -Force
        Write-Host "Deleted: $fileToDelete"
    }
}

# Copier les fichiers manquants de la source vers la destination
foreach ($relativePath in $sourceHash.Keys) {
    if (-not $destinationHash.ContainsKey($relativePath)) {
        $sourceFile = $sourceHash[$relativePath].FullName
        $destinationFile = Join-Path $destinationPath $relativePath
        $destinationDir = Split-Path $destinationFile

        # Créer le répertoire de destination si nécessaire
        if (-not (Test-Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force
        }

        # Copier le fichier
        Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        Write-Host "Copied: $sourceFile to $destinationFile"
    }
}
