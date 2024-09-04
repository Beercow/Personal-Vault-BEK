@echo off

echo.                                                                            
echo                                      ==--------=                            
echo                                    ---::::::::::--                          
echo                                   -:::::::::::::::-    =---------=          
echo                                  =-::::-------:::::- =-----------:-=        
echo                                  =::::--=    =-::::-=--------:-------       
echo                                  =::::-=      =-:::---------:::----:--      
echo                                  =::::-=       -------------::--------      
echo                                  =-::::-           =-------::---------      
echo                                   --:::--     ===---------:::------:--      
echo                                   --::::--------------------------::-       
echo                                  =---:::------------------------::-=        
echo                                 ==------------------------------=+          
echo                                  *=----------====---------==---=            
echo           -----------------------++----------===-----------++=-=            
echo           ---=====================+=----------===----------=+=-=            
echo           ---==------------------==+------------------------++-=            
echo           ---==------------------==+=--------------------=+++=-=            
echo           --===---=====-------===++**--------------==+***+++=--=            
echo           ---==--=++++==----==++++++*+-::---==++++++=========--=            
echo           ---==--==++++==---=+++++===+++*****+===------===-----=            
echo           ---==----=+++==--=++++===-=====++++==--------===-=---=            
echo           ---==----==+++=--=++++==---==-==++++==-------====----=            
echo           ---==-----==++==-=++++==------==++++=--------====----=            
echo           ---==------==++====++++==----==++++==--------====----=            
echo           ---==-------==++=-==++++++++++++++==----------==-----=            
echo           ---==---------===--===+++++++++++==--------====+===--=            
echo           ---==---=--------=---===========-----------=+++=++=--=            
echo           --===------------==------------------------========--=            
echo           ---=============================================-----=            
echo           ---=============================================-----=            
echo           -----------------------------------------------------=            
echo             =------=                                 ---=                   
echo.                                                                            

setlocal enabledelayedexpansion
set temp_script=%temp%\diskpart_script.txt
set foundMatch=0
set volMatch=0

:START
set /P "BEKpath=Enter path to save external key to: "
IF "%BEKpath%" == "" GOTO START

REM Check if the last character is a backslash and remove it
if "%BEKpath:~-1%"=="\" set "BEKpath=%BEKpath:~0,-1%"

IF NOT EXIST "%BEKpath%" (
	MKDIR "%BEKpath%"
)

:GETKEY
FOR /F "tokens=* skip=9" %%a IN ('echo list vdisk ^| diskpart') do (
    echo %%a:~0, -1%% | findstr /C:"OneDriveTemp" >nul
    if !errorlevel!==0 (
        echo %%a | findstr /C:"Attached" >nul
        if !errorlevel!==0 (
            set foundMatch=1
            for /f "tokens=4" %%b in ("%%a") do (
                echo.
				echo Found OneDrive Personal Vault: %%a
				echo.
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
						set volMatch=1
                        for /f "tokens=3" %%d in ("%%c") do (
                            echo.
							echo Personal Vault drive letter: %%d
                            echo.
							echo Saving External Key File to %BEKpath%
							echo.
                            manage-bde -protectors -get %%d: -sek "%BEKpath%" > nul
							timeout 5 > nul
							attrib -s -h "%BEKpath%"\*.BEK
                            
                            set /P "disable=Would you like to disable BitLocker on %%d (Y/[N])?"
                            IF /I "!disable!" NEQ "Y" GOTO END
                            
                            echo.
							echo Disabling BitLocker on %%d
                            manage-bde -protectors -disable %%d: -rebootcount 0
                        )
                    )
                )
            )
        )
    )
)

REM Check if any matches were found
if !foundMatch!==0 (
    echo.
	echo No OneDrive Personal Vaults were found.
	GOTO END:\
)

if !volMatch!==0 (
    echo.
	echo No OneDrive Personal Vaults volumes were found.
)

:END
endlocal
