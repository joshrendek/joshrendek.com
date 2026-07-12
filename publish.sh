#!/bin/bash
hugo
rsync -avz --delete --exclude=docs public/ www-data@static-sites:html/
