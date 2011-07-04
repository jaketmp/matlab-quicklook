A quicklook generator for Mac OS X.

Previews the variables stored within MATLABs '.mat' workspace files.

This code requires the MATLAB 'libmat.dylib', and all dependent libraries. As the current release of MATLAB only ships with 64 bit versions of these libraries, it only builds an x86_64 product.

The code has been built and tested against the libraries shipped with the r2011a release of MATLAB - I'm not sure how The Mathworks feel about distributing them alone - so the following are missing from the un-built binary:

	libboost_date_time.dylib
	libboost_filesystem.dylib
	libboost_regex.dylib
	libboost_signals.dylib
	libboost_system.dylib
	libboost_thread.dylib
	libhdf5.6.0.2.dylib
	libhdf5.6.dylib
	libhdf5_hl.6.0.2.dylib
	libhdf5_hl.6.dylib
	libicudata.dylib.42
	libicudata.dylib.42.1
	libicui18n.dylib.42
	libicui18n.dylib.42.1
	libicuio.dylib.42
	libicuio.dylib.42.1
	libicuuc.dylib.42
	libicuuc.dylib.42.1
	libmat.dylib
	libmwMATLAB_res.dylib
	libmwfl.dylib
	libmwi18n.dylib
	libmwresource_core.dylib
	libmx.dylib
	libut.dylib

	mat.h
	matrix.h
	tmwtypes.h

	lcdata.xml
	icudt40l.dat
	
They can be located in the '{matlab .app bundle}/bin/maci64/' folder.