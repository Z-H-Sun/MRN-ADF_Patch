# encoding: UTF-8
# ruby 2.4.5

print "\e]0;ADF 2012.01 Patcher by Zack\a"
@total = [0, 0] # number of [all, patched] files

def patch(filename)
    @total[0] += 1
    puts "\n\e[1;33mProcessing\e[0m #{filename}..."
    # do not patch patched ones
    if File.exist?(filename + ".bak") then puts(filename + " might have already been patched. \e[1;33mNo operation performed.\e[0m"); return false end
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
        print("\r\e[1;33mProcessed\e[0m ~%.1f MB. " % (@bytes/10)) if @bytes.to_i != mb

        next if len < 14
        d = b[-14, 12] # check the pattern
        case d
        when "\xff\xff\xff\x41\xbc\x00\x00\x00\x00\x44\x0f\x4f".force_encoding("ASCII-8BIT")
            puts "\r\e[1;32mFound pattern\e[0m, MOV R12D, 0 -> MOV R12D, -1: FF FF FF \e[7m41 BC 00 00 00 00\e[0m 44 0F 4F"
            f.seek(-9, 1); f.write("\xff\xff\xff\xff"); f.seek(5, 1)
        when "\x33\xc0\xb9\xff\xff\xff\xff\x3b\x55\xdc\x0f\x4f".force_encoding("ASCII-8BIT")
            puts "\r\e[1;32mFound pattern\e[0m, XOR EAX, EAX -> MOV  AL, -1: \e[7m33 C0\e[0m B9 FF FF FF FF 3B 55 DC 0F 4F"
            f.seek(-14, 1); f.write("\xb0\xff"); f.seek(12, 1)
        else
            next # not a to-be-patched pattern; roll back
        end
        @times += 1
    end
    if @times.zero?
        # not applicable
        File.delete(filename + ".bak"); puts "\e[1;33mNo to-be-patched pattern found in \e[0m" + filename
        return false
    else
        puts "\e[1;32mPatched " + @times.to_s + " place(s) in \e[0m" + filename
        @total[1] += 1
        return true
    end
rescue Interrupt # Ctrl-C
    puts "\e[1;33mDo you want to \e[4mC\e[24montinue, to stop patching this \e[4mF\e[24mile or to stop the whole \e[4mO\e[24mperation?\e[0m"
    print "(C/F/O; Note that all these may cause unrepairable damage to the file): "
    # cleanse well
    f.close; g.close
    File.delete(filename + ".bak")
    case STDIN.gets.downcase[0]
    when "c"
        @total[0] -= 1; retry
    when "o"
        puts "\nIn this operation, \e[1;32m#{@total[1]} out of #{@total[0]} file(s) have been patched.\e[0m"; exit        
    end
    return false
rescue # error
    puts "\e[1;31mError occurred:\e[0m"
    puts $!.inspect
    puts $@.inspect
    return false
end

alias :_exit :exit
def exit(code=0) # to pause before exiting
    print "\n\e[1;33mEND OF OPERATION.\e[0m Press Enter to continue..."
    STDIN.gets
    _exit(code)
end

loop do
    begin
        puts; insPath = ENV['ADFBIN']
        if insPath.nil? then puts "\e[1;31mSeems that ADF is not installed \e[0msince $ADFBIN is not set."; exit end
        puts "\e[1;33mIs ADF 2012 installed at the following path? \e[0mEnter \e[4mY\e[24m for yes or else the real path:"
        puts "\t\"#{insPath}\""
        l = STDIN.gets.chomp
        insPath = l if l.downcase[0] != "y"
        Dir.chdir(insPath)
        break
    rescue
        puts "\n\e[1;31mCannot get access to the designated folder: \e[0mPress Enter to retry..."
        print "\t\"#{insPath}\"\n\n"
        STDIN.gets
        print "\ec"
    end
end

plist = Dir.entries('.').delete_if {|i| File.extname(i) != ".exe"}
plist.each_with_index {|i, x| plist[x] = File.readlink(i) if File.symlink?(i)}
plist.uniq.each {|i| patch(i)}

puts "\nIn this operation, \e[1;32m#{@total[1]} out of #{@total[0]} file(s) have been patched.\e[0m"
exit
