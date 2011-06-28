#!/usr/bin/ruby

#  fix_loader_path.rb
#  Fix the install path of the matlab dylibs to relfect their location in the final package
#
#  Created by Jake TM Pearce on 27/06/2011.
#  Copyright 2011. All rights reserved.

Dir.chdir("#{ARGV[0]}/matlab.qlgenerator/Contents/Frameworks")

Dir.glob("*.dylib*") {|fileName|

    if File.symlink?(fileName) == false
        
        puts("Got " + fileName)
        
        refList = %x[otool -L -X #{fileName}]
        
        File.chmod(0777, fileName) 

        refList.each do |ref|
            
            
            # Move @loader_path to ../Frameworks
            if ref =~ /\t@loader_path\/(lib.+?)\s/
                if $1 == fileName
                    %x[install_name_tool -id "@loader_path/../Frameworks/#{$1}" #{fileName}]
                end
                
                puts "install_name_tool -change \"@loader_path/#{$1}\" \"@loader_path/../Frameworks/#{$1}\" #{fileName}"
                %x[install_name_tool -change "@loader_path/#{$1}" "@loader_path/../Frameworks/#{$1}" #{fileName}]
            end
            
            if ref =~ /\t(lib.+?)\s/
                puts "install_name_tool -change \"#{$1}\" \"@loader_path/../Frameworks/#{$1}\" #{fileName}"
                %x[install_name_tool -change "#{$1}" "@loader_path/../Frameworks/#{$1}" #{fileName}]
            end

            
        end
        
        File.chmod(0444, fileName)
    
    end
}

# Now - because we linked before the dylibs were copied and we changed them, we have to alter the install name in the binary
Dir.chdir("../MacOS")

fileName = "matlab"

File.chmod(0777, fileName) 
refList = %x[otool -L -X #{fileName}]

puts refList

refList.each do |ref|
    # Move @loader_path to ../Frameworks
    if ref =~ /\t@loader_path\/(lib.+?)\s/

        puts "install_name_tool -change \"@loader_path/#{$1}\" \"@loader_path/../Frameworks/#{$1}\" #{fileName}"
        %x[install_name_tool -change "@loader_path/#{$1}" "@loader_path/../Frameworks/#{$1}" #{fileName}]
    end
end

File.chmod(0444, fileName)