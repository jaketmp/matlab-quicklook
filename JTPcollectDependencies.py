"""JTPcollectDependencies"""

import sys
import re
from subprocess import check_output
import os
from os import path
from subprocess import call
import logging
import shutil

class JTPcollectDependencies:
    def collectDependencies(self, args):
       
        # Move libary into target directory, checking if it is a exists or is a symlink.
        fileMoved = self.moveLibrary(args.source, args.destination)
        
        # Read dendencies into a list, skip if the file has already been moved and therefore parsed
        if fileMoved != 1:
            currentLib = path.basename(args.source)
            logging.debug('Parsing dependencies for ' + currentLib)

            # Skip symlinks
            if not path.islink(args.source):

                dependencies = check_output(['otool', '-L', '-X', args.source])

                for libPath in dependencies.split('\t'):
                    # If dependency starts @rpath, call collectDependancies() to collect it.
                    libPath = libPath.rstrip()
                    libNameMatch = re.match('@rpath/(.+?\.dylib)\W.+', libPath, flags=0)
                        
                    if libNameMatch:
                        libName = libNameMatch.group(1)

                        # Skip the self reference
                        if currentLib != libName:
                        
                            args2 = args
                            sourcePath = path.split(args.source)
                            args2.source = path.join(sourcePath[0], libName)
                            self.collectDependencies(args2)

        elif fileMoved == -1:
            logging.error('Error encountered moving: ' + args.source)

        # Return when done.

    def moveLibrary(self, source, destination):
        """Move dylibs, checking for symlinks, returns, 0 file moved ok, 1, file existed already, -1 error."""
        
        # Check the file is not already present.
        fileName = path.basename(source)
        fullDest = path.join(destination, fileName)
        
        # Skip files already present at the destination.
        if path.isfile(fullDest):
            
            logging.debug(fileName + ' already present in destination, skipping.')
            return 1
        
        # Check if we have a symlink.
        elif path.islink(source):
            # If so, copy the target and relink.
            linkDestination = path.realpath(source)
            linkDestinationName = path.basename(linkDestination)

            # Move the source
            self.moveLibrary(linkDestination, destination)
            
            # Relink the reference.
            linkFile = path.join(destination, fileName)

            os.symlink(linkDestinationName, linkFile)
            
            logging.debug(fileName + ' relinked to ' + linkDestination + '.')
            return 0
        
        # Copy normaly
        else:

            destinationFile = path.join(destination, fileName)
            shutil.copy(source, destinationFile)

            logging.debug(fileName + ' copied to destination.')
            return 0
        
        # Should never fall through to here.
        return -1


def main():
    import sys
    import argparse

    parser = argparse.ArgumentParser(description='Collect all the runtime (@rpath/...) dylibs a specified dylib is dependent on.')
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    parser.add_argument('source', type=str, help='Path to the dylib to parse.')
    parser.add_argument('destination', type=str, help='Path to a directory to save the collected dylibs into.')


    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
        logging.debug('Parsing dependencies, starting with: ' + args.source + '\nCopying to: ' + args.destination)

    """Get working."""
    JTPcollectDependencies().collectDependencies(args)


if __name__=='__main__':
    main()
