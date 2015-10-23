#!/bin/sh

createuser --connection-limit=1 --createdb --echo --encrypted --pwprompt --createrole --superuser elroot
createuser --connection-limit=20 --echo --encrypted --pwprompt ellokal

