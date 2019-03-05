set arg1=%1
set arg2=%2
IF "%arg2%" NEQ "" (
    for /F "delims=" %%a in ('findstr %arg1% %arg2%') do set "temp_x=%%a"
) else (
    for /F "delims=" %%a in ('findstr /I %arg1% projects\%PROJECT_NAME%\.env') do set "temp_x=%%a"
)
for /f "tokens=1* delims==" %%a in ("%temp_x%") do (
      set part1=%%a
      set %arg1%=%%b
    )


