# redmine_basix

## Overiview

This is a Redmine plugin for integration with Basix PBX.

It permits to initiate calls by clicking on icons that will show up in the pages:

![basix_redmine phone_icons](./images/redmine_basix.phone_icons.png)

It also converts comments' wav, mp3, ogg links to audio tags so that the files can be listened to without leaving the current page.

## Installation and configuration

To install it, do it as usual:
  - go to your redmine/plugins folder
  - clone this repo
  - restart redmine

 Ex:
```
  cd redmine/plugins/
  git clone https://github.com/brastelcloud/redmine_basix
```

To configure, go to http://YOUR_REDMINE_SERVER/settings/plugin/redmine_basix

and set values (contact Basix Support Center for details):
 
![basix_redmine configuration](./images/redmine_basix.configuration.png)

## Uninstallation 

To remove this plugin just delete the folder redmine/plugins/redmine_basix
