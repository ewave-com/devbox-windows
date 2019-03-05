rem Magento files not worth pulling locally.
@SET IGNORE=%IGNORE% -ignore "Path dumps/*"
@SET IGNORE=%IGNORE% -ignore "Path platform-tools"
@SET IGNORE=%IGNORE% -ignore "Path var/*"
@SET IGNORE=%IGNORE% -ignore "Path docker-config/*"
@SET IGNORE=%IGNORE% -ignore "Path .idea"

rem Magento files not worth pulling locally.
@SET IGNORE=%IGNORE% -ignore "Path pub/static/*"
@SET IGNORE=%IGNORE% -ignore "Path var/.setup_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path var/.update_cronjob_status"
@SET IGNORE=%IGNORE% -ignore "Path var/cache"
@SET IGNORE=%IGNORE% -ignore "Path var/composer_home"
@SET IGNORE=%IGNORE% -ignore "Path var/log"
@SET IGNORE=%IGNORE% -ignore "Path var/page_cache"
@SET IGNORE=%IGNORE% -ignore "Path var/session"
@SET IGNORE=%IGNORE% -ignore "Path var/tmp"
@SET IGNORE=%IGNORE% -ignore "Path var/view_preprocessed"

@SET IGNORE=%IGNORE% -ignore "Path docker-config"

rem Other files not worth pushing to the container.
@SET IGNORE=%IGNORE% -ignore "Path .git"
@SET IGNORE=%IGNORE% -ignore "Path .git/*"
@SET IGNORE=%IGNORE% -ignore "Path .gitignore"
@SET IGNORE=%IGNORE% -ignore "Path .gitattributes"
@SET IGNORE=%IGNORE% -ignore "Path .magento"
@SET IGNORE=%IGNORE% -ignore "Path .env"
@SET IGNORE=%IGNORE% -ignore "Path .env-files-mapping.json"

rem @SET IGNORE=%IGNORE% -ignore "Path public_html/node_modules"
@SET IGNORE=%IGNORE% -ignore "Path supervisord.log"
@SET IGNORE=%IGNORE% -ignore "Path supervisord.pid"
@SET IGNORE=%IGNORE% -ignore "Path .bashrc"
@SET IGNORE=%IGNORE% -ignore "Path .nano"

@SET IGNORE=%IGNORE% -ignore "Path node_modules_remote"
@SET IGNORE=%IGNORE% -ignore "Path .npm"
@SET IGNORE=%IGNORE% -ignore "Path unison.exe"
@SET IGNORE=%IGNORE% -ignore "Path unison-fsmonitor.exe"
@SET IGNORE=%IGNORE% -ignore "Path .unison"
@SET IGNORE=%IGNORE% -ignore "Name {.*.swp}"