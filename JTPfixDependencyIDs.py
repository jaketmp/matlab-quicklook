"""JTPfixDependencyIDs"""

import sys
import re
from subprocess import check_output
import os
from os import path
from subprocess import call
import logging
import shutil

class JTPfixDependencyIDs:
    def fixDependencyIDs(args, source):

        # Get directory contents
        contents = os.listdir(source)

        for filename in contents:
            # Only look at dylibs
            if re.match('.+?\.dylib', filename, flags=0):

                filePath = path.join(source, filename)

                # Get the install name 
                installName = check_output(['otool', '-D', '-X', filePath])


                # Check install name is prepened with @rpath
                installNameMatch = re.match('(@rpath/.+?\.dylib)', installName, flags=0)

                if installNameMatch:
                    # Skip those already using @rpath
                    logging.debug(filename + ' has the install name: ' + installNameMatch.group(1) + ' skipping.')

                else:
                    # Fix the non-relative install names.
                    installNameMatch = re.match('(.+?\.dylib)', installName, flags=0)
                    newInstallName = path.join('@rpath', installNameMatch.group(1))
                    logging.debug(filename + ' has the install name: ' + installNameMatch.group(1) + ' modifying to: ' + newInstallName)

                    check_output(['install_name_tool', '-id', newInstallName, filePath])


def main():
    import sys
    import argparse

    parser = argparse.ArgumentParser(description='Check the install name of dylibs and fix thise that are not prepended with @rpath.')
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    parser.add_argument('source', type=str, help='Path to the folder of dylibs to check.')

    args = parser.parse_args()

    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
        logging.debug('Parsing install names, working in: ' + args.source)

    """Get working."""
    JTPfixDependencyIDs().fixDependencyIDs(args.source)


if __name__=='__main__':
    main()
