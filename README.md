# redmine_basix

## Overview

This is a Redmine plugin for integration with Basix PBX.

It permits to initiate calls by clicking on phone icons that will show up in the issue pages:

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

and set values according to your account (contact Basix Support Center for details):
 
![basix_redmine configuration](./images/redmine_basix.configuration.png)

For this plugin to work, it is necessary that the users at Basix and Redmine have the same login name. 

So if your user name at Basix is 'john', your Redmine user login name should also be 'john'.

## Tips

You can add a custom field phone_number in the issue element. If this field is filled, we will also add a phone icon for it and this will permit to make calls to that number.
The field can be filled with a fixed or mobile number like '0311112222' or '09033334444' but can also be filled with an extension number like '1234' or even a user name like 'john' (actually, any destination is valid).

This will permit for example to handle tickets for external customers and also to set the internal customer in case they don't use redmine.

The calls will go out as group call which means:
  - for external calls (calls to PSTN, fixed or mobile number) the group calling_number will be used
  - for internal calls (calls to other users) the group name should show up in the callee terminal (OBS: this is not ready yet).

## Uninstallation 

To remove this plugin just delete the folder redmine/plugins/redmine_basix
