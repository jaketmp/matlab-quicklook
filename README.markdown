# MATLAB quicklook and spotlight plugins for Mac OS X

Plugins to improve the interaction of MATLAB and Mac OS X. 
These plugins require Mac OS X 10.10 (Yosemite) or later.


### matlab.quicklook
Previews the variables stored within MATLABs *.mat* workspace files.

Install the plugin in `/Library/QuickLook`.

### matlab.mdimporter
Allows Spotlight to search *.mat* files for variable names, additionally the contents of any text variable named *Notes* shall also be indexed.

Install the plugin in `/Library/Spotlight`.


## Project notes

This code requires the MATLAB 'libmat.dylib', and all dependent libraries. As the current release of MATLAB only ships with 64-bit versions of these libraries, it only builds an x86_64 product.

The script 'JTPcollectDependencies.py' can be run with a dylib as a target to collect all the dependent libraries into a specified location.

Some of the MATLAB libraries install paths are not prepended with `@rpath`, 'JTPfixDependencyIDs' will fix this.

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

They can be located in the `{matlab .app bundle}/bin/maci64/` folder. Put all the .dylibs into the 'dylibs/' folder in the project, and the header and data files into the projects root folder
