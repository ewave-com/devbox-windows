@echo off

set "tempfolder=%~dp0\..\tmp"

IF NOT EXIST %tempfolder% (

    md %tempfolder%

)