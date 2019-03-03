# ruby 1.8.7
system("title ADF 2012.01 Patcher by Zack")
puts
@total = [0, 0] # number of [all, patched] files

def patch(filename)
    @total[0] += 1
    puts "\nProcessing #{filename}..."
    # do not patch patched ones
    if File.exist?(filename + ".bak") then puts(filename + " might have already been patched. No operation performed."); return false end
    f = open(filename, "r+b") # read and write, binary
    g = open(filename + ".bak", "wb")
    @times = 0 # number of to-be-patched patterns
    @bytes = 0 # processed length [in tenths MB]
    loop do
        b = f.gets(sep="\x75") # read until met with 0x75 (the first byte of JNZ)
        len = b.size # read length
        g.write(b) # copy
        mb = @bytes.to_i; @bytes += len/104857.6 # check if the change is larger than 0.1 MB (to run more smoothly)
        print("\rProcessed ~%.1f MB. " % (@bytes/10)) if @bytes.to_i != mb

        b2 = f.getc # to check if met with EOF
        if b2.nil? then f.close; g.close; break end # EOF
        g.putc(b2); d = f.read(14) # check the pattern
        if d.length < 14 then g.write(d); f.close; g.close; break end # EOF
        case d
        when "\x8b\x55\xd0\xb9\xff\xff\xff\xff\x3b\x55\xc4\x0f\x4f\xc1"
            puts "\rFound pattern, JNZ -> NOP: 8B 55 D0 B9 FF FF FF FF 3B 55 C4 0F 4F C1\t\t[14]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90) # first JNZ -> NOP
            g.write(f.read(16)) # copy
        when "\x8b\x95\x18\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\xf0" # two possible patterns
            print "\rFound pattern, JNZ -> NOP: 8B 95 18 FF FF FF B9 FF FF FF FF 3B 95 F0 ... "
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            d2 = f.read(22)
            if d2[-3] == 0xc1 # possible pattern 1
                puts "C1\t[20]"
            elsif d2[-3] == 0x3c # possible pattern 2
                d2 += f.read(12); puts "FF\t[32]"
            else # never happened, but just in case
                f.seek(-22, 1); puts "???\t[ERROR]"; next
            end
            g.write(d2)
        when "\x8b\x95\x20\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x18"
            puts "\rFound pattern, JNZ -> NOP: 8B 95 20 FF FF FF B9 FF FF FF FF 3B 95 18 ... C1\t[20]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(22))
        when "\x8b\x95\x04\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\xfc"
            puts "\rFound pattern, JNZ -> NOP: 8B 95 04 FF FF FF B9 FF FF FF FF 3B 95 FC ... FF\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(34))
        when "\x8b\x8d\x18\xff\xff\xff\x8b\x85\x3c\x86\xff\xff\x3b\x8d"
            puts "\rFound pattern, JNZ -> NOP: 8B 8D 18 FF FF FF 8B 85 3C 86 FF FF 3B 8D ... FF\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(34))
        when "\x8b\x95\x28\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\xac"
            puts "\rFound pattern, JNZ -> NOP: 8B 95 28 FF FF FF B9 FF FF FF FF 3B 95 AC ... FF\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(34))
        when "\x8b\x95\x00\xff\xff\xff\xb9\xff\xff\xff\xff\x3b\x95\x9c"
            puts "\rFound pattern, JNZ -> NOP: 8B 95 00 FF FF FF B9 FF FF FF FF 3B 95 9C ... FF\t[32]"
            f.seek(-16, 1); f.putc(0x90); f.putc(0x90)
            g.write(f.read(34))
        else
            f.seek(-14, 1); next # not a to-be-patched pattern; roll back
        end
        f.seek(-2, 1); f.putc(0x90); f.putc(0x90) # second JNZ -> NOP
        @times += 1
    end
    if @times.zero?
        # not applicable
        File.delete(filename + ".bak"); puts "No to-be-patched pattern found in " + filename
        return false
    else
        puts "Patched " + @times.to_s + " place(s) in " + filename
        @total[1] += 1
        return true
    end
rescue Interrupt # Ctrl-C
    print "Do you want to (C)ontinue, to stop patching this (F)ile or to stop the whole (O)peration (note that all these may cause unrepairable damage to the file): "
    # cleanse well
    f.close; g.close
    File.delete(filename + ".bak")
    case STDIN.gets.downcase[0]
    when 99 # "c"
        @total[0] -= 1; retry
    when 111 # "o"
        puts "\nIn this operation, #{@total[1]} out of #{@total[0]} file(s) have been patched."; exit        
    end
    return false
rescue # error
    puts "Error occurred:"
    puts $!.inspect
    puts $@.inspect
    return false
end

alias :_exit :exit
def exit(code=0) # to pause before exiting
    print "\nEND OF OPERATION. "
    system("pause")
    _exit(code)
end

puts "Are you sure to patch all the applicable .exe files in this folder(y/n):\n\t" + File.expand_path(".")
exit unless STDIN.gets.downcase[0] == 121 # "y"
for i in Dir.entries(".")
    patch(i) if File.extname(i) == ".exe"
end
puts "\nIn this operation, #{@total[1]} out of #{@total[0]} file(s) have been patched."
exit
