Validator Launcher for Mac, v0.9.2, 2016-12-17, © 2015 Lothar Haeger (lothar.haeger@is4it.de)

download url: https://iam.is4it.de/public/download/ValidatorLauncher_0.9.2.app.zip
home page url: http://www.is4it.de/en/solution/identity-access-management/
source code: https://github.com/NetIQValidator/ValidatorLauncher/tree/master/Mac
License: Mozilla Public License v2.0, see http://mozilla.org/MPL/2.0/ for details

NetIQ Validator comes with launch scripts for all supported platforms (Linux/Mac/Windows) but those are console mode shell scripts and offer not much comfort. A while ago when I was still using a Windows laptop as my main workhorse, I wrote a little tool to quickly launch NetIQ Validator from a task bar icon instead. Since I moved on to a MacBook in the mean time and Validator runs on OS-X just fine, I jumped at the opportunity to try out Apple’s new programming language Swift and wrote a native Mac version over the summer.

The Validator Launcher for Mac  is a native OS-X app that sits in the menu bar and (by default) starts the Validator service and auto-launches the Validator client web page. From the menu bar icon you can

– open the Validator client web page
– open the Validator runner web page
– open the Validator scheduler web page
– disable autostart of the Validator client
– choose your preferred browser
– enforce use of your custom license file

When you run ValidatorLauncher.app the first time, it will prompt you for the install location of NetIQ Validator, so make sure you have it already installed by then.

If you buy a Validator license you’ll receive a license.dat file that you need to copy into the config subfolder of your Validator install. Since the Validator download comes with an evaluation license file as well this will most likely overwrite your copy during an update. So simply keep your custom license somewhere in a safe place outside the install folder and point the Launcher to it – it will copy the license.dat into the right place on the fly.

Current version 0.9.2 has been developed for and tested with NetIQ Validator version 1.4.1, available from https://dl.netiq.com/Download?buildid=A4ptieHnQXE~