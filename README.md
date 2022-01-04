# Warden Docker Environment Creator (Magento + Symfony)

This is a bash script to speed up the application (`Magento` & `Symfony`) environment creation for warden based development.

## INSTALL
You can simply download the script file and give the executable permission.
```
curl -0 https://raw.githubusercontent.com/MagePsycho/warden-docker-environment-creator/master/src/wenv-creator.sh -o wenv-creator.sh
chmod +x wenv-creator.sh
```

To make it system wide command
```
mv wenv-creator.sh ~/bin/wenv-creator

#OR
#mv wenv-creator.sh /usr/local/bin/wenv-creator
```

## USAGE
To display help
```
wenv-creator --help
```

To create warden environment for `Magento`
```
wenv-creator --project=... --type=magento2
# Or just
wenv-creator --project=...
```

To create warden environment for `Symfony`
```
wenv-creator --project=... --type=symfony
```

To update the script
```
wenv-creator --self-update
```