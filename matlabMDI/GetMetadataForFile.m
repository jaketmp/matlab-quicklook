//
//  GetMetadataForFile.m
//  matlabMDI
//
//  Created by Jake TM Pearce on 04/07/2011.
//  Copyright 2011 Imperial College. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#import <CoreData/CoreData.h>
#include "mat.h"


//==============================================================================
//
//	Get metadata attributes from document files
//
//	The purpose of this function is to extract useful information from the
//	file formats for your document, and set the values into the attribute
//  dictionary for Spotlight to include.
//
//==============================================================================


Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attributes, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
	/* Pull any available metadata from the pathToFile at the specified path */
    /* Return the attribute keys and attribute values in the dict */
    /* Return TRUE if successful, FALSE if there was no data provided */
    /*
	 * Setup everything quick here.
	 */
	MATFile *pmat;
	const char **dir;
	int	  ndir;
	int	  i;
	Boolean notesFound = FALSE;
	mxArray *pa;
	CFMutableStringRef variableNames;
	char *matFilePath = malloc(CFStringGetMaximumSizeOfFileSystemRepresentation(pathToFile));
	
	
	CFStringGetFileSystemRepresentation(pathToFile, matFilePath, CFStringGetMaximumSizeOfFileSystemRepresentation(pathToFile));
	
	/*
	 * Open pathToFile to get directory
	 */
	pmat = matOpen((char *)matFilePath, "r");
	if(pmat == NULL) {
		free(matFilePath);
		return FALSE;
	}
	
	/*
	 * get directory of MAT-pathToFile
	 */
	variableNames = CFStringCreateMutable(kCFAllocatorDefault, 0);
	dir = (const char **)matGetDir(pmat, &ndir);
	if(dir == NULL) {
		free(matFilePath);
		CFRelease(variableNames);
		return FALSE;
	}else{
		// Read var names from the dir.
		for (i=0; i < ndir; i++){
			// Get variable names here.
			CFStringAppendCString(variableNames, dir[i], kCFStringEncodingUTF8);
			CFStringAppendCString(variableNames, " ", kCFStringEncodingUTF8);
			
			// Check if we have notes:
			if(strcmp(dir[i], "Notes") == 0){
				notesFound = TRUE;
			}
		}
	}
	mxFree(dir);
	// Close pmat, and we are done ...
	if(matClose(pmat) != 0) {
		free(matFilePath);
		CFRelease(variableNames);
		return FALSE;
	}
	
	// Get notes variable.
	if(notesFound){
		// Reopen the mat file to read notes
		pmat = matOpen((char *)matFilePath, "r");
		if(pmat == NULL) {
			free(matFilePath);
			CFRelease(variableNames);
			return FALSE;
		}
		
		// Grab the notes var straight out.
		pa = matGetVariable(pmat, "Notes");
		if(pa == NULL) {
			free(matFilePath);
			CFRelease(variableNames);
			return FALSE;
		}
		
		// Check kind is char array.
		if(mxGetClassID(pa) == mxCHAR_CLASS){
			char *notes;
			// Get a cstring from the array.
			notes = mxArrayToString(pa);
			
			// Dump the notes into the general text buffer.
			CFStringAppendCString(variableNames, notes, kCFStringEncodingUTF8);
			
			// Free the cstring;
			mxFree(notes);
		}
		
		mxDestroyArray(pa);
	}
	// Put variableNames into the return (attributes) dictionary
	CFDictionaryAddValue(attributes, CFSTR("kMDItemTextContent"), variableNames);
	
	free(matFilePath);
	CFRelease(variableNames);
    return TRUE;
}
