rem Magento files not worth pulling locally.
@SET IGNORE=%IGNORE% -ignore "Path dumps/*"
@SET IGNORE=%IGNORE% -ignore "Path platform-tools"
@SET IGNORE=%IGNORE% -ignore "Path var/*"
@SET IGNORE=%IGNORE% -ignore "Path docker-config/*"
@SET IGNORE=%IGNORE% -ignore "Path .idea"

rem Other files not worth pushing to the container.
@SET IGNORE=%IGNORE% -ignore "Path .git"
@SET IGNORE=%IGNORE% -ignore "Path .git/*"
@SET IGNORE=%IGNORE% -ignore "Path .env"
@SET IGNORE=%IGNORE% -ignore "Path .env-project.json"
rem @SET IGNORE=%IGNORE% -ignore "Path public_html/node_modules"
@SET IGNORE=%IGNORE% -ignore "Path supervisord.log"
@SET IGNORE=%IGNORE% -ignore "Path supervisord.pid"
@SET IGNORE=%IGNORE% -ignore "Path .bashrc"
@SET IGNORE=%IGNORE% -ignore "Path .nano"

@SET IGNORE=%IGNORE% -ignore "Path .npm"
@SET IGNORE=%IGNORE% -ignore "Path unison.exe"
@SET IGNORE=%IGNORE% -ignore "Path unison-fsmonitor.exe"
@SET IGNORE=%IGNORE% -ignore "Path .unison"
@SET IGNORE=%IGNORE% -ignore "Name {.*.swp}"

rem Akeneo ignores
@SET IGNORE=%IGNORE% -ignore "Path var/cache"
@SET IGNORE=%IGNORE% -ignore "Path web/bundles"
@SET IGNORE=%IGNORE% -ignore "Path web/js/"