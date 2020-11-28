@echo off

set version=%1
set type=%2

set oldcwd=%cd%
cd /d %~dp0
del /f/q *.exe > NUL 2>&1

for %%f in (*.pl) do (
    call :compile %%f 
)

del /f/q trova-%version%.%type%
set cmd=7z -t%type% a trova-%version%.%type% *.exe LICENSE.txt
echo %cmd%
call %cmd%
del /f/q *.exe > NUL 2>&1

goto end

:compile
    set cmd=pp -o %~n1.exe %1
    echo %cmd%
    call %cmd%
    goto :eof

:end
    cd /d "%oldcwd%"
    set oldcwd=
    set version=
    set type=
