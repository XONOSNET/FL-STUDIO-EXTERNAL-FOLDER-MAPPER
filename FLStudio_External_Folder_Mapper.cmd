:: FL STUDIO EXTERNAL SAMPLE DIRECTORY MAPPER
:: ------------------------------------------
:: 		Author: Tim W (timothy@xonos.net)
:: 		Date: 12/15/2018
:: 		Version: 1.2
:: ------------------------------------------
::
::		What does it do?
::		--------------------------------------------------------------
:: 		This script provides an easy method to creating remote folders
::		in your patch/sample library. For instance, you could place all
::		of your midis, samples, loops, etc., in a dropbox directory and
::		use this to quickly bridge FL Studio with a directory that is
::		located elsewhere. You may also use local server paths as well.
::		
::
::		What does it NOT do?
::		--------------------------------------------------------------
::		* FTP Paths
::		* Remote Server Paths Requiring Authentication
::		* Make FL more compliant with your procrastination. :p
::		
::		How does it work?
::		--------------------------------------------------------------
::		It simply creates a creates symbolic links which are pretty
::		much just shortcuts that work exactly the same way that folder
::		paths do with the exception that FL Studio recognizes them as
::		folders the same way that Windows (and other apps) do.

@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

::Sets the width and height of the CMD window.
mode con: cols=150 lines=40

SET _cwd=%~dp0
SET _tmp_br=^ ^ ^ ^ ^ ^ ^ ^^^|
SET _tmp_xbr=^ ^^^|^ ^ ^ ^ ^ ^^^:

CALL :RENDER_BANNER
CALL :CHECK_ADMIN

ECHO %_tmp_br%^| [ Obtaining FL Studio Path from Registry ]
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: @Note: Get path to FL.exe
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
FOR /F "usebackq tokens=3*" %%A IN (`REG QUERY "HKEY_CURRENT_USER\Software\Image-Line\Shared\Paths" /v "FL Studio"`) DO (SET _FL_EXE_PATH=%%B)
SET _FL_DATA_PATH=%_FL_EXE_PATH:FL.exe=Data\Patches\%




:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
ECHO %_tmp_br%^| [ Checking to see if FL is properly installed. ]
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: @Note: Prompt user to continue if FL.EXE is missing.
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%_FL_EXE_PATH%" (GOTO :FL_NOTFOUND) ELSE GOTO :CONFIRM_FL_INSTALL




::Just some notification lines.
:CONFIRM_FL_INSTALL
	ECHO %_tmp_br%^| [ FL is properly installed. ]
	ECHO %_tmp_br%^| :
	ECHO %_tmp_br%^| : Patch / Sample Directory:
	ECHO %_tmp_br%^| : -------------------------
	ECHO %_tmp_br%^| * %_FL_DATA_PATH%
	GOTO :CHECK_DATA_DIRECTORY

	
	
	
::Verifies whether or not the data folder exists. If not, it'll fall back on a function to create one.
:CHECK_DATA_DIRECTORY
	IF NOT EXIST "%_FL_DATA_PATH%" (GOTO :FL_NO_DATA_DIRECTORY) ELSE ECHO %_tmp_br%^| [ FL is properly installed. ]
	ECHO.
	ECHO.
	ECHO.
	GOTO :MAKE_PATCH_FOLDER

	
	
	
::Asks the user to put in the path to the source directory which will be linked.
:FL_FOUND
	SET /p _tmp_link_path="(^!)    [^> Please paste the path of the external directory you would like to add: "
	IF NOT EXIST "%_tmp_link_path%" (GOTO :REMOTE_PATH_NOT_FOUND) ELSE CALL :MAKE_LINK "%_tmp_link_path%"
	PAUSE

	
	
	
::This is called when the source directory can't be found. It'll loop back to the directory input section.
:REMOTE_PATH_NOT_FOUND
	ECHO ^ ^ ^ ^ ^ ^ ^ ^:^:^ ------------------------------------------------------------------------
	ECHO ^ ^ ^ ^ ^ ^ ^ ^:^:^ You entered^: %_tmp_link_path%
	ECHO ^(X^)^ ^ ^ ^ ^:^:^ [ERROR]^: The path you entered does not exist. Please enter a valid path^^!
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^          (ex: C:\dropbox\samples\drumkit)
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ ------------------------------------------------------------------------
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ 
	GOTO :FL_FOUND

	
	
	
::This is the link handling & confirmation before commiting the link.
:MAKE_LINK
	IF NOT EXIST "%~1" (GOTO :FL_FOUND) ELSE FOR /f "delims=" %%A IN ("%~1") DO set _tmp_target_folder_name=%%~nxA
	SET _tmp_target_path="%_FL_DATA_PATH%%_tmp_target_folder_name%"
	SET _tmp_source_path="%~1"
	CLS
	ECHO ^ ^*^ ^ ^ ^ ^ ^:^:^ --------------------------------------------------------------------------
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ - The following link will be made. Please confirm that this is accurate. -
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ --------------------------------------------------------------------------
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^              (Virtual Directory)
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^*^   .-^<--^<--^< [%_tmp_target_path%]
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^|^  ^v       
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^|^  ^|       
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^|^  ^v       
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^|^  ^|       
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^|^  ^v          (Source Directory)
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^*^   `-^>--^>--^> [%_tmp_source_path%]
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ 
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ --------------------------------------------------------------------------
	ECHO ^ ^|^ ^ ^ ^ ^ ^:^:^ 
	<NUL set /p=^(^*^)    ^[^]^ Enter [Y] to commit linking or [N] to return to add a different directory^:^ 
	CHOICE /C YN /N
	IF %ERRORLEVEL%==1 GOTO :COMMIT_LINK
	IF %ERRORLEVEL%==2 GOTO :FL_FOUND




::This makes the link and removes pre-existing links (if there are any naming conflicts).
::@TODO: Add option to rename pre-existing link upon folder naming conflict.
:COMMIT_LINK
	::Remove link if it already exists.
	IF EXIST %_tmp_target_path% (
		rd /s /q %_tmp_target_path%
	)

	start /wait cmd /c mklink /d %_tmp_target_path% %_tmp_source_path%
	
	SET _TMP_LINK_RESULT=%ERRORLEVEL%
	ECHO ^(^*^)^ ^ ^ ^ ^:^:^  The following folder is now accessible in the FL Studio Browser:
	ECHO ^ ^|^ ^ ^ ^ ^ ^*^*^  %_tmp_target_path%
	IF NOT "%_TMP_LINK_RESULT%"=="0" ECHO ^(^^!^)    [^> [FATAL ERROR]^: RUN THIS AS ADMIN - DUDE^^!^ 
	IF NOT "%_TMP_LINK_RESULT%"=="0" PAUSE >nul
	IF NOT "%_TMP_LINK_RESULT%"=="0" GOTO :CLOSE_OUT
	
	<NUL set /p=^(^?^)^ ^ ^ ^ ^<^>  Would you like to add another directory? Enter [Y] to confirm - [N] to exit^:^ 
	CHOICE /C YN /N
	IF %ERRORLEVEL%==1 GOTO :FL_FOUND
	IF %ERRORLEVEL%==2 GOTO :CLOSE_OUT





::Function: Haults the script because the data directory is missing.
:FL_NO_DATA_DIRECTORY
	CALL :br 1
	ECHO ^(X^)^ ^ ^ ^ ^:^:^ [ERROR]^: The FL Studio Patches directory was not found! It must exist for this to work.
	ECHO %_tmp_xbr%^:^ ^ ^|
	ECHO %_tmp_xbr%^:^ ^ ^*--^>^ ^ %_FL_DATA_PATH%
	ECHO %_tmp_xbr%^:
	ECHO %_tmp_xbr%^:^  Would you like to create the folder structure listed above?
	ECHO ^(^?^)^ ^ ^ ^ ^<^>  Enter [Y] to confirm - [N] to cancel^:^ 
	CHOICE /C YN /N
	IF %ERRORLEVEL%==1 GOTO :MAKE_DATA_FOLDER_STRUCTURE
	IF %ERRORLEVEL%==2 GOTO :CLOSE_OUT
	GOTO :CLOSE_OUT


::Function: Haults the script because the data directory is missing.
:MAKE_PATCH_FOLDER
	ECHO ^ ^ ^ ^ ^ ^ ^ ^#^:^ [FOLDER]^* You may now enter a directory name or path which will house your mapped folders.
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^: If you would prefer these mapped folders remain in the patches folder (root),
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^* simply leave it blank.
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ----------------------------------------------------------------------------------
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^* Note: The root directory is the Data\Patches\ folder. Anything entered here will
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^:       be added to this path. For instance, if you enter "Samples\Packs\Vocals",
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^:       the folders being mapped will exist in Data\Patches\Samples\Packs\Vocals.
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^:       The folder structure will automatically be created if it doesn't already 
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ^*       exist.
	ECHO ^ ^ ^ ^ ^ ^ ^ ^|^:^         ----------------------------------------------------------------------------------
	ECHO %_tmp_br%^:         ^|     Default Root Directory: 
	ECHO %_tmp_br%^:         ^*--^>  "%_FL_DATA_PATH%"
	ECHO %_tmp_br%^:
	ECHO %_tmp_br%^:
	ECHO ^ ^ ^ ^ ^ ^ ^ ^`^*^ Examples^: Samples
	ECHO ^ ^ ^ ^ ^ ^ ^ ^ ^|^-----^>     Samples\Drumkits
	ECHO ^ ^ ^ ^ ^ ^ ^ ^ ^|^-----^>     Mixer presets
	ECHO ^ ^ ^ ^ ^ ^ ^ ^ ^|^-----^>     Samples\Packs\Vocals
	ECHO ^ ^ ^ ^ ^ ^ ^ ^ ^*^-----^>     Channel presets\Serum2
	ECHO.
	set /p _tmp_cust_fldr="(?)    [ > Enter a valid new or existing folder name or path (WITHOUT the trailing backslash) or simply leave it blank: "
	
	::If the custom folder(s) defined is not blank.
	IF NOT "%_tmp_cust_fldr%" == "" ( GOTO :MAKE_CUSTOM_PATH )

	::If the custom folder(s) defined is blank.
	IF "%_tmp_cust_fldr%" == "" ( GOTO :ROOT_FOLDER_SELECTED )
	
:MAKE_CUSTOM_PATH
	IF NOT EXIST "%_FL_DATA_PATH%%_tmp_cust_fldr%"  ( MKDIR "%_FL_DATA_PATH%%_tmp_cust_fldr%\" )
	SET _FL_DATA_PATH=%_FL_DATA_PATH%%_tmp_cust_fldr%\
	ECHO ^ ^ ^ ^ ^ ^ ^ ^*^*^ %_FL_DATA_PATH%
	GOTO :CUSTOM_FOLDER_SELECTED

::When no custom folder is entered.
:ROOT_FOLDER_SELECTED
	ECHO %_tmp_xbr%^:^ No custom folder structure was specified. Defaulting root directory.
	ECHO %_tmp_xbr%^:^ ^[%_FL_DATA_PATH%^] has been selected. 
	GOTO :FL_FOUND
	
::When a custom path is entered.
:CUSTOM_FOLDER_SELECTED
	ECHO %_tmp_br%^: 
	ECHO %_tmp_br%^: 
	ECHO %_tmp_xbr%^:^ ^[%_FL_DATA_PATH%^] has been selected. 
	GOTO :FL_FOUND

::Function: Creates the folder structure necessary for this script to work.
:MAKE_DATA_FOLDER_STRUCTURE
	MKDIR "%_FL_DATA_PATH%"
	GOTO :MAKE_PATCH_FOLDER

::Function: Offers option to continue on anyways, even though FL.exe is missing.
:FL_NOTFOUND
	CALL :br 1
	ECHO ^(X^)^ ^ ^ ^ ^:^:^ [ERROR]^: Could not locate FL Studio at the following path.
	ECHO %_tmp_xbr%^:^ ^ ^ ^ ^|
	ECHO %_tmp_xbr%^:^ ^ ^ ^ ^*--^>^ ^ %_FL_EXE_PATH%
	ECHO %_tmp_xbr%^:
	ECHO %_tmp_xbr%^:
	<NUL set /p=(?)    ^<^>  Would you like to continue anyways? 
	<NUL set /p= Enter [Y] or [N]^:^ 
	CHOICE /C YN /N
	IF %ERRORLEVEL%==1 GOTO :CHECK_DATA_DIRECTORY
	IF %ERRORLEVEL%==2 GOTO :CLOSE_OUT




:: Function: Creates preformatted line breaks
:br
	SET _tmp_br_pfx=%~2
	IF "%~2"=="" SET _tmp_br_pfx=^^^|
	for /L %%T in (1,1,%~1) do ECHO %_tmp_br%%_tmp_br_pfx%
	EXIT /B 0

:: Function: Generates the intro banner
:RENDER_BANNER
	ECHO.
	ECHO ^ ^ ^ ^ ^ ^ ^ ___________________________________.--FLSTUDIO-PATCH-^&-SAMPLE-MAPPER--.______________________________________
	ECHO ^ ^ ^ ^ ^ ^ /___________________________________.----------------------------------.______________________________________\
	ECHO ^ ^ ^ ^ ^ ^/                                                                                                               \
	ECHO ^ ^ ^ ^ ^ ^\  - OBTAINING FL STUDIO PATH FROM REGISTRY [ HKEY_CURRENT_USER\Software\Image-Line\Shared\Paths\FL Studio ] -  /
	ECHO ^ ^ ^ ^ ^ ^ ^\_____________________________________________________________________________________________________________/
	EXIT /B 0

:CHECK_ADMIN
    net session >nul 2>&1
    IF %ERRORLEVEL%== 0 ( EXIT /B 0 )
	ECHO                    ^|^|
	ECHO                    ^|^|
	ECHO                    ^|^|
	ECHO                    ^|^|______________________________________________________________________________________
	ECHO                    ^|                                                                                       ^|
	ECHO                    ^| ^(^^!^) YOU MUST RUN THIS SCRIPT AS ADMIN OR IT WILL BE UNABLE TO CREATE SYMBOLIC LINKS.  ^|
	ECHO                    ^|_______________________________________________________________________________________^|
	PAUSE >nul
	GOTO :CLOSE_OUT




:CLOSE_OUT
	EXIT
