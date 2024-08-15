@echo off
setlocal enabledelayedexpansion
set temp_script=%temp%\diskpart_script.txt
FOR /F "tokens=* skip=9" %%a IN ('echo list vdisk ^| diskpart') do (
	echo %%a:~0, -1%% | findstr /C:"OneDriveTemp" >nul
	if !errorlevel!==0 (
        echo %%a | findstr /C:"Attached" >nul
        if !errorlevel!==0 (
            for /f "tokens=4" %%b in ("%%a") do (
				echo Found OneDrive Personal Vault: %%a
				echo Assigning drive letter
				(
				echo select disk %%b
				echo select partition 1
				echo assign
				echo exit
				) > %temp_script%
				diskpart /s %temp_script% > nul
				del %temp_script%
				FOR /F "tokens=* skip=9" %%c IN ('echo list vol ^| diskpart') do (
					echo %%c:~0, -1%% | findstr /C:"OneDrive" >nul
					if !errorlevel!==0 (
						for /f "tokens=3" %%d in ("%%c") do (
							echo Personal Vault drive letter: %%d
							echo Saving External Key File to %1
							manage-bde -protectors -get %%d: -sek %1 > nul
						)
					)
				)
            )
        )
    )
)
