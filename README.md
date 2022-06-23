ReadMe - Lomiri File Manager
============================

Lomiri File Manager App is the official file manager app for Ubuntu Touch. We follow an open
source model where the code is available to anyone to branch and hack on. The
Lomiri File Manager App originally followed a test driven development (TDD) where tests were
written in parallel to feature implementation to help spot regressions easier.

Attention!
==========
Currently the ci is unable to build the c++ parts due to memory lag. As workaround the app is
built into the prebuilt directory externally and fetches the qml parts from src. From this dir the
pure app is built by the ci as expected. So before publishing a new version be sure to keep that
dir upstream!

Telegram group
==============
Join the Telgram group by clicking this link
* [Telegram group](https://t.me/ubports_fm_app)

Building with clickable
=======================
The easiest way to build this app is using clickable by running the command:

```
clickable
```

See [clickable documentation](http://clickable.bhdouglass.com/en/latest/) for details.

Building without clickable
==========================
**DEPENDENCIES ARE NEEDED TO BE INSTALLED TO BUILD AND RUN THE APP**.

A complete list of dependencies for the project can be found in filemanager-app/debian/control

The following essential packages are also required to develop this app:
* [ubuntu-sdk](http://developer.ubuntu.com/start)
* intltool   - run  `sudo apt-get install intltool`

Useful Links
============
Here are some useful links with regards to the File Manager App development.

* [UBports](https://ubports.com/)
* [clickable](http://clickable.bhdouglass.com/en/latest/)
* [OpenStore](https://open-store.io/app/filemanager.ubports)
