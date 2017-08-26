# MATLAB quicklook and spotlight plugins for Mac OS X

Plugins to improve the interaction of MATLAB and Mac OS X.
These plugins require Mac OS X 10.10 (Yosemite) or later.


## Installation

After downloading and extracting the zip files from the **[Releases](https://github.com/jaketmp/matlab-quicklook/releases/latest)** tab above, drag each of the plugins to the folder indicated. This will install the plugins for all users (you may need to enter the password for an administrator account). If you lack administrator privileges or only wish to install for one user, follow the instructions below.

Place the matlab.qlgenerator file into `/Library/QuickLook` (for all users) or `~/Library/QuickLook` (for the current user only).

The Mac operating system should notice the plugin installation and start using it automatically. If it doesn't seem to, try logging out and in again, or run Terminal.app and enter this command:

    qlmanage -r

and press return.

## Project compilation notes

Compilation of this code requires the MATLAB `libmat.dylib` library, and all its dependent libraries. As the current release of MATLAB, only ships with 64-bit versions of these libraries, hence, it only builds an x86_64 product.

The script *JTPcollectDependencies.py* can be run with a dylib as a target to collect all the dependent libraries into a specified location.

Some of the MATLAB libraries install paths are not prepended with `@rpath`, *JTPfixDependencyIDs* will fix this.

### Dynamic libaries
+	libmat.dylib
+	libmx.dylib
and dependencies.

### Headers
+	mat.h
+	matrix.h
+	tmwtypes.h

### Data files
+	lcdata.xml
+	icudt40l.dat

They can be located in the `{matlab .app bundle}/bin/maci64/` folder. Put all the .dylibs into the `dylibs/` folder in the project, and the header and data files into the projects root folder
