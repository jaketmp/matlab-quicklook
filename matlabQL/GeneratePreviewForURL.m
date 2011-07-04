#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>


#include "mat.h"

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 Version 2.
 Complete rewrite for Snow Leopard, dropping PPC support, adding x86_64 and 
 bumping matlab libraries to release 2009b.
 ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	/*
	 * Setup everything quick here.
	 */
	NSMutableString *html, *htmlTable;					// Write the contents of the matlab file into here.
	NSString *htmlPath;									// Path to the html template within the bundle.
	NSImage *theIcon;									// File icon.
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	// Determine desired localisations and load strings
	NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"org.smrsgroup.matlab.qlgenerator"];
	[pluginBundle retain];
	
	// Get the posix-style path for the thing we are quicklooking at
	CFStringRef fullPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
	
	// If previewing is canceled, don't bother loading data.
	if(QLPreviewRequestIsCancelled(preview)) {
		CFRelease(fullPath);
		[pluginBundle release];
		[pool release];
		return noErr;
	}
    
	/*
	 * Load and Format Data here
	 */
	MATFile *pmat;
	mxArray *pa;
 	int varCount = 0;
	
	// Load file to scrape for matrices.
	const char *matFilePath = [[(NSURL *)url relativePath] cStringUsingEncoding:NSUTF8StringEncoding]; // Just a pointer to url, no need to free.
	pmat = matOpen(matFilePath, "r");
	if (pmat == NULL) {
		CFRelease(fullPath);
		[pluginBundle release];
		[pool release];
		return readErr; // Return a file read error here.
	}
	htmlTable = [[[NSMutableString alloc] init] autorelease];
	// Iterate over headers of all variables
	const char *name;
	mwSize *dims;
	
	
	while((pa = matGetNextVariableInfo(pmat, &name))){
		[htmlTable appendString:[NSString stringWithFormat:@"<tr><td>%s</td>", name]];
		
		// Determine the data type in the array
		NSString *arrayType;
		mxClassID   category;
		category = mxGetClassID(pa);
		switch(category)  {
			case mxUNKNOWN_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Unknown" 
                                                                            value:@"Unknown" 
                                                                            table:nil];			break;
			case mxCELL_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Cell" 
                                                                          value:@"Cell" 
                                                                          table:nil];			break;
			case mxSTRUCT_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Structure" 
                                                                           value:@"Structure" 
                                                                           table:nil];			break;
			case mxLOGICAL_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Logical"
                                                                            value:@"Logical" 
                                                                            table:nil];			break;
			case mxCHAR_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"String"
                                                                          value:@"String" 
                                                                          table:nil];			break;
			case mxDOUBLE_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Double"
                                                                           value:@"Double" 
                                                                           table:nil];			break;
			case mxSINGLE_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Single"
                                                                           value:@"Single" 
                                                                           table:nil];			break;
			case mxINT8_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Integer (8-bit)"
                                                                          value:@"Integer (8-bit)" 
                                                                          table:nil];			break;
			case mxUINT8_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Integer (unsigned 8-bit)"
                                                                           value:@"Integer (unsigned 8-bit)" 
                                                                           table:nil];			break;
			case mxINT16_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Integer (16-bit)"
                                                                           value:@"Integer (16-bit)" 
                                                                           table:nil];			break;
			case mxUINT16_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Integer (unsigned 16-bit)"
                                                                           value:@"Integer (unsigned 16-bit)" 
                                                                           table:nil];			break;
			case mxINT32_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Integer (32-bit)"
                                                                           value:@"Integer (32-bit)" 
                                                                           table:nil];			break;
			case mxUINT32_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Integer (unsigned 32-bit)"
                                                                           value:@"Integer (unsigned 32-bit)" 
                                                                           table:nil];			break;
			case mxINT64_CLASS:		arrayType = [pluginBundle localizedStringForKey:@"Integer (64-bit)"
                                                                           value:@"Integer (64-bit)" 
                                                                           table:nil];			break;
			case mxUINT64_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Integer (unsigned 64-bit)"
                                                                           value:@"Integer (unsigned 64-bit)" 
                                                                           table:nil];			break;
			case mxFUNCTION_CLASS:	arrayType = [pluginBundle localizedStringForKey:@"Function"
                                                                             value:@"Function" 
                                                                             table:nil];		break;
			default: arrayType = [pluginBundle localizedStringForKey:@"Unknown (error)"
															   value:@"Unknown (error)" 
															   table:nil];						break;
		}
		[htmlTable appendString:[NSString stringWithFormat:@"<td>%@</td>", arrayType]];
        
		mwSize ndim = mxGetNumberOfDimensions(pa);
		dims = (mwSize *)mxGetDimensions(pa);
		// Extract the dimesions of each array
		int j;
		[htmlTable appendString:[NSString stringWithFormat:@"<td>%i", *dims]];
		for(j = 1; j < ndim; j++){
			dims++;
			[htmlTable appendString:[NSString stringWithFormat:@" &times; %i", *dims]];
		}
		[htmlTable appendString:@"</td>"];
		[htmlTable appendString:@"</tr>"];
		
		varCount++;
		mxDestroyArray(pa);
		// Maybe check for cancel here? Would seem to help in situations with large numbers of vars.
	}
	matClose(pmat);
	
	// Check for cancel
	if(QLPreviewRequestIsCancelled(preview)) {
		CFRelease(fullPath);
		[pluginBundle release];
		[pool release];
		return noErr;
	}
    
	// Set properties for the preview data
	NSMutableDictionary *props = [[[NSMutableDictionary alloc] init] autorelease];
	
	CFStringRef fileName = CFURLCopyLastPathComponent(url);
    [props setObject:@"UTF-8" forKey:(NSString *)kQLPreviewPropertyTextEncodingNameKey];
    [props setObject:@"text/html" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
	[props setObject:(NSString *)fileName forKey:(NSString *)kQLPreviewPropertyDisplayNameKey];
    [props setObject:[NSNumber numberWithInt:1000] forKey:(NSString *)kQLPreviewPropertyWidthKey];
    [props setObject:[NSNumber numberWithInt:800] forKey:(NSString *)kQLPreviewPropertyHeightKey];
	
	/*
	 * Load the HTML template
	 */
	//Get the template path
	htmlPath = [[[NSString alloc] initWithFormat:@"%@%@", [pluginBundle bundlePath], @"/Contents/Resources/index.html"] autorelease];
	NSError *htmlError;
    html = [[[NSMutableString alloc] initWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&htmlError] autorelease];
	
	
	// Do our formating + localisations
	NSString *prettyPath = [(NSString*)fullPath stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
	[html replaceOccurrencesOfString:@"%path%" withString:prettyPath options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	
	// Localised strings
	[html replaceOccurrencesOfString:@"%Path%" 
						  withString:[pluginBundle localizedStringForKey:@"%Path%" value:@"path" table:nil]
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Date_Modified%" 
						  withString:[pluginBundle localizedStringForKey:@"%Date_Modified%" value:@"Date Modified" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Size%" 
						  withString:[pluginBundle localizedStringForKey:@"%Size%" value:@"Size" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Number_of_Vars%" 
						  withString:[pluginBundle localizedStringForKey:@"%Number_of_Vars%" value:@"Number of Variables" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Name%" 
						  withString:[pluginBundle localizedStringForKey:@"%Name%" value:@"Name" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Type%" 
						  withString:[pluginBundle localizedStringForKey:@"%Type%" value:@"Type" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%Dimensions%" 
						  withString:[pluginBundle localizedStringForKey:@"%Dimensions%" value:@"Dimensions" table:nil] 
							 options:NSLiteralSearch 
							   range:NSMakeRange(0, [html length])];
	
	// Get POSIX file info.
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:(NSString*)fullPath error:NULL];
	// Localise date
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];	
	[html replaceOccurrencesOfString:@"%time%" withString:[dateFormatter stringFromDate:[fileAttributes fileModificationDate]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	
	
	uint64 fileSize = [fileAttributes fileSize];
	// Format size string
	NSString *sizeString;
	if(fileSize < 1024){ //B
		sizeString = [[[NSString alloc] initWithFormat:[pluginBundle localizedStringForKey:@"%qi bytes" 
																					 value:@"%qi bytes" 
																					 table:nil], fileSize] 
					  autorelease];
	} else if(fileSize <= 1048576){ //KB
		float fileSizeFraction = (float)fileSize / 1024.0;
		sizeString = [[[NSString alloc] initWithFormat:[pluginBundle localizedStringForKey:@"%1.2f KB" 
																					 value:@"%1.2f KB" 
																					 table:nil], fileSizeFraction] 
					  autorelease];
		
	} else if(fileSize <= 1073741824){ //MB
		float fileSizeFraction = (float)fileSize / 1048576.0;
		sizeString = [[[NSString alloc] initWithFormat:[pluginBundle localizedStringForKey:@"%1.2f MB" 
																					 value:@"%1.2f MB" 
																					 table:nil], fileSizeFraction] 
					  autorelease];
		
	} else if(fileSize <= 1099511627776){ //GB
		float fileSizeFraction = (float)fileSize / 1073741824.0;
		sizeString = [[[NSString alloc] initWithFormat:[pluginBundle localizedStringForKey:@"%1.2f GB" 
																					 value:@"%1.2f GB" 
																					 table:nil], fileSizeFraction] 
					  autorelease];
		
	} else{ //GB Fall through to TB for now // if(fileSize > 1099511627776)
		float fileSizeFraction = (float)fileSize / 1099511627776.0;
		sizeString = [[[NSString alloc] initWithFormat:[pluginBundle localizedStringForKey:@"%1.2f TB" 
																					 value:@"%1.2f TB" 
																					 table:nil], fileSizeFraction] 
					  autorelease];
	}
	[html replaceOccurrencesOfString:@"%size%" withString:sizeString options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	[html replaceOccurrencesOfString:@"%noVars%" withString:[[[NSString alloc] initWithFormat:@"%i", varCount] autorelease] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	
	
	[html replaceOccurrencesOfString:@"%name%" withString:(NSString*)fileName options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	CFRelease(fileName);
	
	// Insert table of file contents.
	[html replaceOccurrencesOfString:@"%table_data%" withString:htmlTable options:NSLiteralSearch range:NSMakeRange(0, [html length])];
	
	// Get file icon
	theIcon = [[[NSWorkspace sharedWorkspace] iconForFile:(NSString*)fullPath] retain];
	[theIcon setSize:NSMakeSize(128.0,128.0)];
	
	NSData *iconData = [[theIcon TIFFRepresentation] retain];
	NSMutableDictionary *iconProps=[[[NSMutableDictionary alloc] init] autorelease];
	[iconProps setObject:@"image/tiff" forKey:(NSString *)kQLPreviewPropertyMIMETypeKey];
	[iconProps setObject:iconData forKey:(NSString *)kQLPreviewPropertyAttachmentDataKey];
	[props setObject:[NSDictionary dictionaryWithObject:iconProps forKey:@"icon.tiff"] forKey:(NSString *)kQLPreviewPropertyAttachmentsKey];
	
	
	// Check for cancel
	if(QLPreviewRequestIsCancelled(preview)) {
		CFRelease(fullPath);
		[theIcon release];
		[iconData release];
		[pluginBundle release];
		[pool release];
		return noErr;
	}
	// Send the html to be rendered.
	QLPreviewRequestSetDataRepresentation(preview,(CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML,(CFDictionaryRef)props);
	
	CFRelease(fullPath);
	[theIcon release];
	[iconData release];
	[pluginBundle release];
    [pool release];
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
