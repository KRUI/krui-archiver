krui-archiver
=============
krui-archiver is a bash-based webstream archiver used on 89.7FM and The Lab. It allows 24/7 archiving of a webstream on an hourly basis, and sorts the audio based on the date and time of recording. As it relies on Greg Sharp's `streamripper` (http://streamripper.sourceforge.net), software licensed under v3 of the GPL, it is released under the same license (see License header for more details). 

Install
=============
1. Check a clone of this repo `git clone https://github.com/KRUI/krui-archiver`
2. Install streamripper - OS X users should use [homebrew](https://github.com/Homebrew/homebrew) `brew install streamripper`
3. Configure the script by setting the configurable user parameters:

	```
	prefix="<filename_prefix>"                                            # Prefix used when naming files. Useful when archiving different stations into one directory.
	radiostream="<link to stream .m3u with port>"                         # Link to recording target (must be a webstream, obviously)
	dest_path="<absolute path to store recordings>"                       # Absolute path for recordings. No trailing slash!
	audio_sizecap=<cap in megabytes>                                      # Size cap of audio storage path in megabytes. As the size of the storage directory approaches
	                                                                      # 90% of the cap defined here, emails will be sent.
	notification_email=alert@domain.com                                   # Email that should processing errors and warnings`
	```

4. Give krui-archiver.sh execute permissions using `chmod +x /path/to/krui-archiver.sh` and launch. It will run continuously until you stop it by killing the bash window or sending a ^C interrupt.

_NOTE:_ If you are using the GNU date/time utils, you will experience problems with the timestamp functionality. If you are on OS X, you are fine (as of 10.9.1). A fix for GNU systems is to download and compile the BSD `date` and `time` utilities and hardcode them into each `date`/`time` call below.   

License
=============
krui-archiver (C) 2013 - Tony Andrys

Licensed under the GPL v3, see LICENSE for more details.
