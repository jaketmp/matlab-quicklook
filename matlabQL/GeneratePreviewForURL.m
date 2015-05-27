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
	
	@autoreleasepool {
	
	// Determine desired localisations and load strings
		NSBundle *pluginBundle = [NSBundle bundleWithIdentifier:@"org.smrsgroup.matlab.qlgenerator"];
		
		// Get the posix-style path for the thing we are quicklooking at
		CFStringRef fullPath = CFURLCopyFileSystemPath(url, kCFURLPOSIXPathStyle);
		
		// If previewing is canceled, don't bother loading data.
		if(QLPreviewRequestIsCancelled(preview)) {
			CFRelease(fullPath);
			return noErr;
		}
    
		/*
		 * Load and Format Data here
		 */
		MATFile *pmat;
		mxArray *pa;
        int varCount = 0;
		
		// Load file to scrape for matrices.
		const char *matFilePath = [[(__bridge NSURL *)url relativePath] cStringUsingEncoding:NSUTF8StringEncoding]; // Just a pointer to url, no need to free.
		pmat = matOpen(matFilePath, "r");
		if (pmat == NULL) {
			CFRelease(fullPath);
			return readErr; // Return a file read error here.
		}
		htmlTable = [[NSMutableString alloc] init];
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
                                                                                  table:nil];		    break;
				default:                arrayType = [pluginBundle localizedStringForKey:@"Unknown (error)"
                                                                                  value:@"Unknown (error)"
                                                                                  table:nil];			break;
			}
			[htmlTable appendString:[NSString stringWithFormat:@"<td>%@</td>", arrayType]];
        
			mwSize ndim = mxGetNumberOfDimensions(pa);
			dims = (mwSize *)mxGetDimensions(pa);
			// Extract the dimesions of each array
			int j;
			[htmlTable appendString:[NSString stringWithFormat:@"<td>%i", (int)*dims]];
			for(j = 1; j < ndim; j++){
				dims++;
				[htmlTable appendString:[NSString stringWithFormat:@" &times; %i", (int)*dims]];
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
			return noErr;
		}
    
		// Set properties for the preview data
		NSMutableDictionary *props = [[NSMutableDictionary alloc] init];
		
		CFStringRef fileName = CFURLCopyLastPathComponent(url);
        props[(NSString *)kQLPreviewPropertyTextEncodingNameKey] = @"UTF-8";
        props[(NSString *)kQLPreviewPropertyMIMETypeKey] = @"text/html";
		props[(NSString *)kQLPreviewPropertyDisplayNameKey] = (__bridge NSString *)fileName;
        props[(NSString *)kQLPreviewPropertyWidthKey] = @1000;
        props[(NSString *)kQLPreviewPropertyHeightKey] = @800;
		
		/*
		 * Load the HTML template
		 */
		//Get the template path
		htmlPath = [[NSString alloc] initWithFormat:@"%@%@", [pluginBundle bundlePath], @"/Contents/Resources/index.html"];
		NSError *htmlError;
        html = [[NSMutableString alloc] initWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:&htmlError];
		
		
		// Do our formating + localisations
		NSString *prettyPath = [(__bridge NSString*)fullPath stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
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
		
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:(__bridge NSString*)fullPath error:NULL];
		// Localise date
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];	
		[html replaceOccurrencesOfString:@"%time%" withString:[dateFormatter stringFromDate:[fileAttributes fileModificationDate]] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		
		uint64 fileSize = [fileAttributes fileSize];
		// Format size string
        NSString *sizeString = [NSByteCountFormatter stringFromByteCount:fileSize countStyle:NSByteCountFormatterCountStyleFile];
		[html replaceOccurrencesOfString:@"%size%" withString:sizeString options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		[html replaceOccurrencesOfString:@"%noVars%" withString:[[NSString alloc] initWithFormat:@"%i", varCount] options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		
		[html replaceOccurrencesOfString:@"%name%" withString:(__bridge NSString*)fileName options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		CFRelease(fileName);
		
		// Insert table of file contents.
		[html replaceOccurrencesOfString:@"%table_data%" withString:htmlTable options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		// Get file icon
		theIcon = [[NSWorkspace sharedWorkspace] iconForFile:(__bridge NSString*)fullPath];
		[theIcon setSize:NSMakeSize(256.0,256.0)];
		
		NSData *iconData = [theIcon TIFFRepresentation];
		
        NSString *base64 = [[NSString alloc] initWithData:[iconData base64EncodedDataWithOptions:0]
                                                 encoding:NSUTF8StringEncoding];
        NSString *image = [NSString stringWithFormat:@"data:image/tiff;base64,%@", base64];
        [html replaceOccurrencesOfString:@"%image%" withString:image options:NSLiteralSearch range:NSMakeRange(0, [html length])];
		
		// Check for cancel
		if(QLPreviewRequestIsCancelled(preview)) {
			CFRelease(fullPath);
			return noErr;
		}
		// Send the html to be rendered.
		QLPreviewRequestSetDataRepresentation(preview,(__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],kUTTypeHTML,(__bridge CFDictionaryRef)props);
		
		CFRelease(fullPath);
    return noErr;
    }
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
