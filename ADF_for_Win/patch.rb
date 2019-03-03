# ruby 1.8.7
system("title ADF 2012.01 Patcher by Zack")
@total = [0, 0] # number of [all, patched] files

def patch(filename)
    @total[0] += 1
    puts; system "echo \e[1;33mProcessing\e[0m #{filename}..."
    # do not patch patched ones
    if File.exist?(filename + ".bak") then system("echo #{filename} might have already been patched. \e[1;33mNo operation performed.\e[0m"); return false end
    f = open(filename, "r+b") # read and write, binary
    g = open(filename + ".bak", "wb")
    @times = 0 # number of to-be-patched patterns
    @bytes = 0 # processed length [in tenths MB]
    loop do
        b = f.gets(sep="\x75") # read until met with 0x75 (JNZ)
        if b.nil? then f.close; g.close; break end # EOF
        len = b.size # read length
        g.write(b) # copy
        mb = @bytes.to_i; @bytes += len/104857.6 # check if the change is larger than 0.1 MB (to run more smoothly)
        print("\rProcessed ~%.1f MB. " % (@bytes/10)) if @bytes.to_i != mb
        
        next if len < 17
        d = b[-17, 16] # check the pattern
        case d
        when "\xff\xff\xb9\x00\x00\x00\x00\x0f\x4f\xc8\x89\x8d\x3c\x86\xff\xff"
            print "\r"; system "echo \e[1;32mFound pattern\e[0m, MOV ECX,   0 ^-^> MOV ECX, -1: FE FF FF \e[7mB9 00 00 00 00\e[0m 0F 4F C8 89 8D 3C 86 FF"
            f.seek(-14, 1); f.write("\xff\xff\xff\xff"); f.seek(10, 1)
        when "\xff\xff\xba\xff\xff\xff\xff\x0f\x4f\xca\x89\x8d\x6c\xaa\xff\xff", "\xff\xff\xba\xff\xff\xff\xff\x0f\x4f\xca\x89\x8d\x3c\xb2\xff\xff","\xff\xff\xba\xff\xff\xff\xff\x0f\x4f\xca\x89\x8d\x0c\xaa\xff\xff"
            print "\r"; system "echo \e[1;32mFound pattern\e[0m, XOR ECX, ECX ^-^> MOV  CL, -1: FF FF FF \e[7m33 C9\e[0m 3B 95 .. F. FF FF BA FF FF FF FF"
            f.seek(-22, 1); f.write("\xb1\xff"); f.seek(20, 1)
        when "\x33\xc0\xb9\xff\xff\xff\xff\x3b\x95\x1c\xff\xff\xff\x0f\x4f\xc1", "\x33\xc0\xb9\xff\xff\xff\xff\x3b\x95\xf4\xfe\xff\xff\x0f\x4f\xc1"
            print "\r"; system "echo \e[1;32mFound pattern\e[0m, XOR EAX, EAX ^-^> MOV  AL, -1: FF FF FF \e[7m33 C0\e[0m B9 FF FF FF FF 3B 95 .. F. FF FF"
            f.seek(-17, 1); f.write("\xb0\xff"); f.seek(15, 1)
        when "\x8b\x55\xd8\x8b\xc6\xb9\xff\xff\xff\xff\x3b\x55\xc8\x0f\x4f\xc1"
            print "\r"; system "echo \e[1;32mFound pattern\e[0m, MOV EAX, ESI ^-^> MOV  AL, -1: 8B 55 D8 \e[7m8B C6\e[0m B9 FF FF FF FF 3B 55 C8 0F 4F C1"
            f.seek(-14, 1); f.write("\xb0\xff"); f.seek(12, 1)
        when "\x95\xfc\xfe\xff\xff\x8b\xd7\x0f\x4f\xd1\x89\x95\x1c\xae\xff\xff"
            print "\r"; system "echo \e[1;32mFound pattern\e[0m, MOV EDX, EDI ^-^> MOV  DL, -1: FE FF FF \e[7m8B D7\e[0m 0F 4F D1 89 95 1C AE FF FF 75 20"
            f.seek(-12, 1); f.write("\xb2\xff"); f.seek(10, 1)
        else
            next # not a to-be-patched pattern; roll back
        end
        @times += 1
    end
    if @times.zero?
        # not applicable
        File.delete(filename + ".bak"); system "echo \e[1;33mNo to-be-patched pattern found in \e[0m" + filename
        return false
    else
        system "echo \e[1;33mPatched " + @times.to_s + " place(s) in \e[0m" + filename
        @total[1] += 1
        return true
    end
rescue Interrupt # Ctrl-C
    system "echo \e[1;33mDo you want to \e[4mC\e[24montinue, to stop patching this \e[4mF\e[24mile or to stop the whole \e[4mO\e[24mperation?\e[0m"
    print "(C/F/O; Note that all these may cause unrepairable damage to the file): "
    # cleanse well
    f.close; g.close
    File.delete(filename + ".bak")
    case STDIN.gets.downcase[0]
    when 99 # "c"
        @total[0] -= 1; retry
    when 111 # "o"
        puts; system "echo In this operation, \e[1;32m#{@total[1]} out of #{@total[0]} file(s) have been patched.\e[0m"; exit
    end
    return false
rescue # error
    system "echo \e[1;31mError occurred:\e[0m"
    puts $!.inspect
    puts $@.inspect
    return false
end

alias :_exit :exit
def exit(code=0) # to pause before exiting
    system "echo \e[1;33m"
    print "END OF OPERATION. "
    system "pause"
    _exit(code)
end

loop do
    begin
        puts; insPath = ENV['SCMLICENSE']
        if insPath.nil? then system "echo \e[1;31mSeems that ADF is not installed \e[0msince $SCMLICENSE is not set."; exit end
        system "echo \e[1;33mIs ADF 2012 installed at the following path? \e[0mEnter \e[4mY\e[24m for yes or else the real path:"
        insPath = File.join(File.dirname(insPath), "bin").gsub("\\", "/")
        puts "\t\"#{insPath}\""
        l = STDIN.gets.chomp
        insPath = l if l.downcase[0] != 121 # "y"
        Dir.chdir(insPath)
        break
    rescue
        system "echo \e[1;31m"; print "Cannot get access to the designated folder: "; system "echo \e[0mPlease retry."
        print "\t\"#{insPath}\"\n\n"
        system "pause && cls"
    end
end
for i in Dir.entries(".")
    patch(i) if File.extname(i) == ".exe"
end
puts; system "echo In this operation, \e[1;32m#{@total[1]} out of #{@total[0]} file(s) have been patched.\e[0m"
exit
