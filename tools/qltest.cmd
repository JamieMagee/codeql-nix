@echo off

"%CODEQL_DIST%\codeql.exe" database index-files ^
    --include-extension=.nix ^
    --size-limit=5m ^
    --language=nix ^
    --working-dir=. ^
    "%CODEQL_EXTRACTOR_NIX_WIP_DATABASE%"

exit /b %ERRORLEVEL%
