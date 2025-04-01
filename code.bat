@echo off
REM ========================================================
REM Universal Conversion Tool v1.0 - Future Proof Edition
REM ========================================================

:: ========= Step 1: Check for Required Tools =========
powershell -NoProfile -Command ^
"function Check-Tool { param([string]$Tool, [string]$URL) { 
    if (-not (Get-Command $Tool -ErrorAction SilentlyContinue)) { 
        Write-Host \"$Tool not found. Do you want to download and install it? (Y/N)\"; 
        $ans = Read-Host; 
        if ($ans -eq 'Y') { 
            Write-Host \"Downloading $Tool...\"; 
            Invoke-WebRequest -Uri $URL -OutFile \"$env:TEMP\\$Tool.zip\"; 
            Write-Host \"Please extract and install $Tool from $env:TEMP\\$Tool.zip, then re-run this tool.\"; 
            Start-Sleep -Seconds 5; exit 
        } else { 
            Write-Host \"$Tool is required. Exiting in 5 seconds...\"; 
            Start-Sleep -Seconds 5; exit 
        } 
    } else { 
        Write-Host \"$Tool found.\" 
    } 
} ; 
Check-Tool -Tool 'ffmpeg' -URL 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'; 
Check-Tool -Tool 'magick' -URL 'https://imagemagick.org/download/binaries/ImageMagick-7.1.0-xx-Q16-x64-dll.exe';"

:: ========= Step 2: Folder Setup & Self Placement =========
set "MAINFOLDER=%~dp0Converter"
set "CONVERTFOLDER=%MAINFOLDER%\Convert"
set "OLDFOLDER=%MAINFOLDER%\Old Conversions"

if not exist "%MAINFOLDER%" (
    mkdir "%MAINFOLDER%"
)
if not exist "%CONVERTFOLDER%" (
    mkdir "%CONVERTFOLDER%"
)
if not exist "%OLDFOLDER%" (
    mkdir "%OLDFOLDER%"
)

if /I not "%~dp0"=="%MAINFOLDER%\" (
    copy "%~f0" "%MAINFOLDER%\Convert.bat" >nul
    echo Moved script to %MAINFOLDER%\Convert.bat
)

:: ========= Step 3: File Detection, Listing & Storage Warning =========
powershell -NoProfile -Command ^
"$folder = '%CONVERTFOLDER%'; 
$files = Get-ChildItem -Path $folder -File; 
if ($files.Count -eq 0) { Write-Host 'No files detected in folder:' $folder; exit } 
Write-Host 'Detected files:'; 
foreach ($f in $files) { 
    $ext = $f.Extension.ToLower(); 
    if ($ext -match '\.(mov|mp4|avi|mkv)$') { $type='Video' } 
    elseif ($ext -match '\.(mp3|wav|aac)$') { $type='Audio' } 
    elseif ($ext -match '\.(jpg|jpeg|png|gif)$') { $type='Image' } 
    else { $type='Other' } ; 
    Write-Host $f.Name ' - ' $type ' - Format:' $ext; 
} 
$drive = Get-PSDrive -Name (Split-Path $folder -Qualifier).Replace(':',''); 
$free = [math]::Round($drive.Free / 1GB,2); 
Write-Host 'Free space on drive:' $free 'GB'; 
if ($free -lt 10) { Write-Host 'Warning: Conversions may leave you with less than 10GB free space.' }"

:: ========= Step 4: User Selection for Target Formats =========
set /P TargetVideo="Enter target video format (e.g., mp4): "
set /P TargetAudio="Enter target audio format (e.g., mp3): "
set /P TargetImage="Enter target image format (e.g., png): "
set /P TargetDocument="Enter target document format (e.g., pdf): "
set /P TargetOther="Enter target format for other files (or leave blank to skip): "

:: ========= Step 5: Final Confirmation =========
choice /M "Proceed with conversion? (Y/N)"
if errorlevel 2 exit

:: ========= Step 6: Conversion Execution with Quality Preservation =========
for /f "tokens=2 delims==" %%I in ('powershell -NoProfile -Command "Get-Date -Format T"') do set STARTTIME=%%I

powershell -NoProfile -Command ^
"$folder = '%CONVERTFOLDER%'; 
$videoTarget = '%TargetVideo%'; 
$audioTarget = '%TargetAudio%'; 
$imageTarget = '%TargetImage%'; 
$documentTarget = '%TargetDocument%'; 
$otherTarget = '%TargetOther%'; 
$files = Get-ChildItem -Path $folder -File; 
$log = @(); 
foreach ($f in $files) { 
    $ext = $f.Extension.ToLower(); 
    $basename = $f.BaseName; 
    if ($ext -match '\.(mov|mp4|avi|mkv)$') { 
        if ($ext -eq ('.' + $videoTarget)) { Write-Host \"$($f.Name) is already in target video format. Skipping conversion.\"; $log += \"$($f.Name): Already $videoTarget\"; continue } 
        $target = Join-Path $folder ($basename + '.' + $videoTarget); 
        Write-Host \"Converting video file:\" $f.Name; 
        ffmpeg -i $f.FullName -c:v libx264 -pix_fmt yuv420p -crf 18 -preset slow -c:a aac -b:a 192k $target; 
        $log += \"$($f.Name): Converted to $videoTarget\"; 
    } elseif ($ext -match '\.(mp3|wav|aac|flac|ogg|m4a|aiff|wma|opus|amr)$') { 
        if ($ext -eq ('.' + $audioTarget)) { Write-Host \"$($f.Name) is already in target audio format. Skipping conversion.\"; $log += \"$($f.Name): Already $audioTarget\"; continue } 
        $target = Join-Path $folder ($basename + '.' + $audioTarget); 
        Write-Host \"Converting audio file:\" $f.Name; 
        ffmpeg -i $f.FullName -c:a aac -b:a 192k $target; 
        $log += \"$($f.Name): Converted to $audioTarget\"; 
    } elseif ($ext -match '\.(jpg|jpeg|png|gif|bmp|tiff|webp|heif|heic|raw|svg|psd)$') { 
        if ($ext -eq ('.' + $imageTarget)) { Write-Host \"$($f.Name) is already in target image format. Skipping conversion.\"; $log += \"$($f.Name): Already $imageTarget\"; continue } 
        $target = Join-Path $folder ($basename + '.' + $imageTarget); 
        Write-Host \"Converting image file:\" $f.Name; 
        magick $f.FullName $target; 
        $log += \"$($f.Name): Converted to $imageTarget\"; 
    } elseif ($ext -match '\.(pdf|doc|docx|txt|ppt|pptx|xls|xlsx|rtf|odt|epub|csv|md)$') { 
        if ($ext -eq ('.' + $documentTarget)) { Write-Host \"$($f.Name) is already in target document format. Skipping conversion.\"; $log += \"$($f.Name): Already $documentTarget\"; continue } 
        $target = Join-Path $folder ($basename + '.' + $documentTarget); 
        Write-Host \"Converting document file:\" $f.Name; 
        magick $f.FullName $target; 
        $log += \"$($f.Name): Converted to $documentTarget\"; 
    } elseif ($otherTarget -ne '') { 
        if ($ext -eq ('.' + $otherTarget)) { Write-Host \"$($f.Name) is already in target format. Skipping conversion.\"; $log += \"$($f.Name): Already $otherTarget\"; continue } 
        $target = Join-Path $folder ($basename + '.' + $otherTarget); 
        Write-Host \"Converting file:\" $f.Name; 
        Copy-Item $f.FullName $target; 
        $log += \"$($f.Name): Copied as $otherTarget\"; 
    } else { 
        Write-Host \"No conversion set for file:\" $f.Name; 
        $log += \"$($f.Name): No conversion performed\"; 
    } 
} ; 
Write-Host 'Conversion Log:'; 
$log | ForEach-Object { Write-Host $_ } ; 
if (($videoTarget -or $audioTarget -or $imageTarget -or $documentTarget) -and ($files | Where-Object { $_.Extension -in @('.mov','.mp4','.jpg','.png','.mp3','.pdf') })) { 
    [console]::beep(500,500); 
}"

:: ========= Step 7: Post-Conversion Actions =========
powershell -NoProfile -Command ^
"$oldFolder = '%OLDFOLDER%'; 
$convertFolder = '%CONVERTFOLDER%'; 
$timestamp = (Get-Date).ToString('yyyy-MM-dd_HH-mm'); 
$zipName = Join-Path $oldFolder ('Old_Conversions_' + $timestamp + '.zip'); 
$tempFolder = Join-Path $oldFolder 'temp';
if (!(Test-Path $tempFolder)) { New-Item -ItemType Directory -Path $tempFolder | Out-Null } ;
$files = Get-ChildItem -Path $convertFolder -File; 
foreach ($f in $files) { 
    if ($f.Extension -match '(\.mov|\.mp3|\.jpg|\.jpeg|\.png|\.pdf)') { Move-Item $f.FullName $tempFolder } 
} ; 
Compress-Archive -Path $tempFolder\* -DestinationPath $zipName; 
Remove-Item -Path $tempFolder -Recurse -Force; 
Write-Host 'Old conversions archived in:' $zipName; 

$size = (Get-ChildItem -Path $convertFolder -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB;
if ($size -gt 10) { 
    $zipConverted = Join-Path $convertFolder ('Converted_Files_' + $timestamp + '.zip'); 
    $structure = 'Converted Files'; 
    New-Item -ItemType Directory -Path (Join-Path $convertFolder $structure) | Out-Null; 
    foreach ($f in Get-ChildItem -Path $convertFolder -File) { 
        if ($f.Extension -match '\.(mp4)$') { $dest = Join-Path $convertFolder (Join-Path $structure 'Video.MP4') } 
        elseif ($f.Extension -match '\.(mp3)$') { $dest = Join-Path $convertFolder (Join-Path $structure 'Audio.MP3') } 
        elseif ($f.Extension -match '\.(png)$') { $dest = Join-Path $convertFolder (Join-Path $structure 'Image.PNG') } 
        else { $dest = Join-Path $convertFolder (Join-Path $structure 'Other') } ; 
        if (!(Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null } ; 
        Move-Item $f.FullName $dest; 
    } ; 
    Compress-Archive -Path (Join-Path $convertFolder $structure + '\*') -DestinationPath $zipConverted; 
    Write-Host 'Converted files archived in:' $zipConverted; 
}"

:: ========= Step 8: Estimated Time Calculation =========
for /f "tokens=2 delims==" %%I in ('powershell -NoProfile -Command "((Get-Date) - (Get-Date '%STARTTIME%')).TotalMinutes"') do set ELAPSED=%%I
echo Estimated conversion time: %ELAPSED% minutes.

:: ========= Step 9: End Script =========
echo Conversion process complete.
pause
