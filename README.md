# endian-gpo
This is a system that allows network administrators to control the whitelist for the transparent proxy in the [Endian Community Firewall](https://www.endian.com) through [Windows Group Policies](https://en.wikipedia.org/wiki/Group_Policy).
It consists of three parts:

* The ADMX definitions to set the appropriate registry keys on the clients.
* A Powershell startup script that reads these values and uses them to communicate with the firewall.
* A Python script that runs on the endian firewall and opens a server that listens for white-/blacklist requests and applies them.

Currently this only supports MAC Addresses.

## Setup
### Configuring the Group Policy Object
First of all, you need to install the ADMX file from this system. ADMX files are templates for group policy options. Please take a look at this link if you don't know how to install these files in your domain: http://ad.kazakinfo.com/2011/04/central-store-for-admx-templates/

After installing them, you need to configure them. Right-click your default GPO and click on `Edit`. You will have to navigate to `Computer Configuration` -> `Windows Settings` -> `Scripts` -> `Startup`. Select the `Powershell Scripts` tab, and click on the button that says `Show files`.
You will have to copy the file [client/Endian-GPO.ps1](https://github.com/StollD/endian-gpo/tree/master/client/Endian-GPO.ps1) into that folder. When you have done that, you can click the button that says `Add`, and select the file you just added.

Now every computer in your domain will execute this script when they start. However without data it will do nothing. Since you are currently editing your Default Domain Policy, you shouldn't enable whitelisting in this object - you should rather disable that. To do that, navigate to
`Computer Configuration` -> `Windows Settings` -> `Administrative Templates` -> `Endian`. Enter the static IP address of your Endian Firewall under `Endian Address`, and disable the second option (`Bypass Transparent Proxy`) to stop all computers from gettings whitelisted.

I recommend you to create a seperate Group Policy Object, and only apply it to the computers that should get whitelisted (for example: teacher computers, or managment/supervisor workstations). Inside of that GPO, you only have to enable `Bypass Transparent Proxy` and you should be ready on the client side.

### Setting up the server side
The server-side setup is a bit simpler than the client side, because everything we need is already there. Endian comes with python preinstalled and we are going to use linux/endian onboard systems to start the server together with the operating system. This requires SSH access, which you can enable
in the Administration Panel: http://docs.endian.com/3.2/utm/system.html#ssh-access

However, there is one thing that needs to be installed by you: the python flask library for hosting HTTP servers and the gunicorn application server. So, when you have logged into your firewall using your prefered SSH client, you need to run `pip install flask` and `pip install gunicorn`. 
After the installation finished, you can upload the [server/Endian-GPO.py](https://github.com/StollD/endian-gpo/tree/master/server/Endian-GPO.py) script somewhere to the firewall, and run it using the [server/startup.sh](https://github.com/StollD/endian-gpo/tree/master/server/startup.sh) 
script. This script **must be** started from the same directory as `Endian-GPO.py`, otherwise it won't work.

To start the server automatically when Endian starts, you should add a call to `startup.sh` to the Endian autostart system: https://help.endian.com/hc/en-us/articles/218146618-Endian-s-startup-scripts-with-inithooks

To test if the server works, you can open `http://<your endian ip>:7777/` in your browser, and you should see a **Not found** answer.

## License
Copyright (c) 2017 Dorian Stoll
Licensed under the terms of the MIT License.