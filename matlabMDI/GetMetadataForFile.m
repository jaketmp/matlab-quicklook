//
//  GetMetadataForFile.m
//  matlabMDI
//
//  Created by Jake TM Pearce on 04/07/2011.
//  Copyright 2011 Imperial College. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#import <CoreData/CoreData.h>


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

	
    return TRUE;
}
