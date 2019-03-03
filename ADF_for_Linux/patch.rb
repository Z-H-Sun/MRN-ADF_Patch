# encoding: ASCII-8BIT
# ruby 2.4.5
# The above designation of encoding (as binary) is essential, or else the comparison b/w the read strings and the target strings will be problematic
print "\e]0;ADF 2012.01 Patcher by Zack\a"
puts
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
        b = f.gets(sep="\x75") # read until met with 0x75 (the first byte of JNZ)
        len = b.size # read length
        g.write(b) # copy
        mb = @bytes.to_i; @bytes += len/104857.6 # check if the change is larger than 0.1 MB (to run more smoothly)
        print("\r\e[1;33mProcessed\e[0m ~%.1f MB. " % (@bytes/10)) if @bytes.to_i != mb

        b2 = f.getc # to check if met with EOF
        if b2.nil? then f.close; g.close; break end # EOF
        g.putc(b2); d = f.read(14) # check the pattern
        if d.nil? then f.close; g.close; break end
        if d.length < 14 then g.write(d); f.close; g.close; break end # EOF
        case d
        when "\x8b\x55\xe4\xb9\xff\xff\xff\xff\x3b\x55\xd8\x0f\x4f\xc1"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 55 E4 B9 FF FF FF FF 3B 55 D8 0F 4F C1\t\t[14]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90) # first JNZ -> NOP
            g.write(f.read(16)) # copy
        when "\x8b\x95\x28\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x20"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 95 28 FF FF FF B9 FF FF FF FF 3B 95 20 ... E1\t[20]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(23))
        when "\x8b\x95\x1c\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x14"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 95 1C FF FF FF B9 FF FF FF FF 3B 95 14 ... E1\t[20]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(23))
        when "\x8b\x85\x1c\xff\xff\xff\xba\xff\xff\xff\xff\x3b\x85\x14"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 85 1C FF FF FF BA FF FF FF FF 3B 85 14 ... E2\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(23))
        when "\x8b\x95\x24\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x1c"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 95 24 FF FF FF B9 FF FF FF FF 3B 95 1C ... E1\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(23))
        when "\x8b\x95\x30\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x28"
            puts "\r\e[1;32mFound pattern\e[0m, JNZ -> NOP: 8B 95 30 FF FF FF B9 FF FF FF FF 3B 95 28 ... E1\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(23))
        else
            f.seek(-14, 1); next # not a to-be-patched pattern; roll back
        end
        f.seek(-2, 1); f.putc(0x90); f.putc(0x90) # second JNZ -> NOP
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
    print "\e[1;33mDo you want to (C)ontinue, to stop patching this (F)ile or to stop the whole (O)peration (note that all these may cause unrepairable damage to the file): \e[0m"
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

puts "\e[1;33mAre you sure to patch all the applicable .exe files in this folder(y/n):\e[0m\n\t" + File.expand_path(".")
exit unless STDIN.gets.downcase[0] == "y"
for i in Dir.entries(".")
    patch(i) if File.extname(i) == ".exe"
end
puts "\nIn this operation, \e[1;32m#{@total[1]} out of #{@total[0]} file(s) have been patched.\e[0m"
exit