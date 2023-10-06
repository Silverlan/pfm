# PFM

The Pragma Filmmaker is a software for creating and rendering 3D animated movies and images and runs on the Pragma Game Engine. Please see the repository for [Pragma](https://github.com/Silverlan/pragma#readme) for more information.

Contributions
------
PFM is a Lua-based addon for Pragma. If you would like to contribute to the development of PFM, all you need is a source code editor of your choice (though Visual Studio Code is highly recommended) and some experience with Lua 5.1. Here are the recommended steps:
1) Download and extract the [latest version](https://github.com/Silverlan/pragma/releases/tag/nightly) of Pragma (you do not need the source code for Pragma to contribute to PFM)
2) Delete the existing "Pragma/addons/filmmaker" directory
3) Fork [this repository](https://github.com/Silverlan/pfm) and clone your fork into "Pragma/addons/filmmaker_fork". Do *not* fork into "addons/filmmaker", otherwise your changes will get overwritten the next time you update Pragma/PFM.
4) (Optional) Follow the instructions on [the wiki](https://wiki.pragma-engine.com/books/lua-api/page/visual-studio-code) to set up Visual Studio Code for Lua development with Pragma

You can find the Lua-script files for PFM in "Pragma/addons/filmmaker_fork/lua". For some basic information on how to use the Lua API in Pragma, please check out [the wiki](https://wiki.pragma-engine.com/books/lua-api).

To update Pragma/PFM, you can still use the auto-updater functionality of PFM. Simply make sure to delete the "Pragma/addons/filmmaker" directory again after the update.
