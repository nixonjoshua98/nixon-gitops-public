$ErrorActionPreference = "Stop"

$tempParent = [System.IO.Path]::GetTempPath()
$tempGuid   = [System.Guid]::NewGuid().ToString()
$tempDir    = Join-Path -Path $tempParent -ChildPath $tempGuid

New-Item -ItemType Directory -Path $tempDir

git clone "https://github.com/nixonjoshua98/nixon-gitops.git" $tempDir

$destinationPath = "./nixon-gitops"

if (Test-Path -Path $destinationPath) {
    Remove-Item -Path $destinationPath -Recurse -Force
}

Move-Item -Path $tempDir -Destination $destinationPath