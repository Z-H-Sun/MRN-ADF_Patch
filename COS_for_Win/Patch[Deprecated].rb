system("title ChemOffice Suite 18~22 Patcher [DEPRECATED] by Zack")
Dir.chdir(File.dirname($Exerb ? ExerbRuntime.filepath : __FILE__)) # change currentDir to the file location

# Read *backwards* as there are multiple `patterns' while always the last one is of interest
# See also: [flori/file-tail](https://github.com/flori/file-tail/blob/master/lib/file/tail.rb)
BUF_SIZE = 1 << 16
@total = [0, 0, 0, 0, 0] # number of [all, patched, restored, ignored, failed] files

def patch(filename, mode)
  f = open(filename, 'rb')
  f.seek(0, 2) # start from EOF
  tail = '' # the remaining part not dealt with in the last block, which ends with a "\x2a"
  last = 0  # the length of content when reading for the last time
  loop do
    begin
      f.seek(-BUF_SIZE, 1)
      d = f.read(BUF_SIZE) + tail
      ind = d.index("\x2a")
      if ind.nil?
        tail = ''
      else
        tail = d[0, ind+1] # the new `tail'
        d = d[ind+1..-1]
      end
    rescue Errno::EINVAL # reach the beginning of the file
      last = f.tell
      f.rewind
      d = f.read(last) + tail
    end
    pos = f.tell # current position
    offset = d.rindex(/\xdc\x12\x07\x28....\x07\x0a[\x06\x17]\x2a/)
    unless offset.nil?
      @total[0] += 1
      puts "\n\e[4m#{filename}\e[0m"
      offset2 = ind+offset+11-BUF_SIZE
      if d[offset+10,2] == "\x17\x2a"
        print "\e[1;33mPatched Pattern\e[0m [dc 12 07 28 .. .. .. .. 07 0a \e[7m17\e[0m 2a] \e[1;33mfound at offset 0x#{(pos+offset2).to_s(16)}\e[0m "
      else
        print "\e[1;32mPattern to be patched\e[0m [dc 12 07 28 .. .. .. .. 07 0a \e[7m06\e[0m 2a] \e[1;32mfound at offset 0x#{(pos+offset2).to_s(16)}\e[0m "
      end
      tempMode = mode
      if mode == 'A'
        print "\nChoose the \e[4m[P]atch\e[0m or \e[4m[R]estore\e[0m mode: "
        print(tempMode = `choice /T 10 /C PR /D P /N`.chomp.upcase)
      end
      if d[offset+10,2] == "\x17\x2a"
        if tempMode == 'R'
          f2 = open(filename, 'r+b')
          f2.seek(pos+offset2, 0)
          f2.write("\x06")
          f2.close
          puts "\e[1;33m: Restored.\e[0m"
          @total[2] += 1
        else
          puts ": Ignored."
          @total[3] += 1
        end
      else
        if tempMode == 'R'
          puts ": Ignored."
          @total[3] += 1
        else
          f2 = open(filename, 'r+b') # write separately
          f2.seek(pos+offset2, 0)
          f2.write("\x17")
          f2.close
          puts "\e[1;32m: Patched.\e[0m"
          @total[1] += 1
        end
      end
      last = -1 # elicit `break'
      break
    end
    break unless last.zero?
    f.seek(-BUF_SIZE, 1)
  end
  # puts "\e[1;31mNo pattern found.\e[0m No operation taken." if last >= 0
  f.close
rescue # error
  puts "\e[1;31mError occurred:"
  @total[4] += 1
  puts $!.inspect; puts $@.inspect
  print "\e[0m"
end

listVer = [[], []]
puts "\n***** Note: Use this tool only when you want to activate multiple ChemOffice users in your local network, as this crack method is flawed (e.g. Chem3D hotlink cannot work properly in ChemDraw). Otherwise, try the other better crack tool here: https://bit.ly/3NQfPZV ****\n\nYou have:"
for i in 0..1 # check 32-bit and 64-bit registry
  list = ''
  print "  \e[1;33m#{(i+1)*32}-bit ChemOffice\e[0m "
  ['HKLM', 'HKCU'].each {|j| list +=  `reg query #{j}\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall /s /t REG_SZ /f "ChemOffice " /reg:#{(i+1)*32} 2>nul`} # check CurrentUser and LocalMachine ("ChemOffice " the space is necessary to exclude ChemOffice+)
  for k in list.split("\n\n")
    next unless k.include?('DisplayName')
    key = k.strip.split("\n")[0]
    ['DisplayName', 'VersionMajor', 'VersionMinor', 'InstallLocation'].each {|l| listVer[i] << `reg query \"#{key}\" /v #{l} /reg:#{(i+1)*32} 2>nul`.strip.split('  ')[-1]}
    (1..2).each {|l| eval "listVer[i][l] = #{listVer[i][l]}"} # convert to integer
    print "[#{listVer[i][0]}, Version #{listVer[i][1]}.#{listVer[i][2]}] installed at\n    \e[4m#{listVer[i][3]}\e[0m"
    break
  end
  if listVer[i].empty? then puts "\e[1;31mNOT installed\e[0m"; next end
  if listVer[i][1] < 18
    print " \e[1;31m(NOT supported)\e[0m"
    listVer[i] = []
  end
  puts
end
print "\nIs the information correct? [Y/N] (\e[1;32mPress `Y' or wait for 10 seconds\e[0m to confirm; or press `N' within 10 seconds to decline and then enter the information manually) "
puts(c = `choice /T 10 /D Y /N`.chomp.upcase)
if c=='N'
  for i in 0..1
    puts; puts "For \e[1;33m#{(i+1)*32}-bit ChemOffice\e[0m:"
    print '  Enter the version number (e.g. 18.2, 20.0): ____'; print "\b"*4
    v = `cmd /V /C \"set /p var=&& echo !var!\"` # STDIN.gets will not work after calling `choice`
    listVer[i][1] = v.split('.')[0].to_i
    listVer[i][2] = v.split('.')[1].to_i
    if listVer[i][1] < 18
      puts "  \e[1;31m(NOT supported)\e[0m"
      listVer[i] = []
    else
      print '  Enter the installation path: _________________________'; print "\b"*25
      listVer[i][3] = `cmd /V /C \"set /p var=&& echo !var!\"`.chomp
    end
  end
end

if listVer[0].empty? and listVer[1].empty? then system('pause'); exit end
print "\nDo you wish to \e[4m[P]atch\e[0m, \e[4m[R]estore\e[0m, or \e[4mbe [A]sked to decide for\e[0m each file? (Press P, R, or A; or wait for 10 seconds to start with the `Patch' mode as the default choice) "
puts(m = `choice /T 10 /C PRA /D P /N`.chomp.upcase)

require 'find'
patch = []
exts = ['.exe', '.dll', '.ocx', '.pyd']
for i in 0..1
  next if listVer[i].empty?
  Find.find(listVer[i][3]) {|j| patch << j.gsub('/', "\\") if exts.include?(File.extname(j).downcase) and File.basename(j)[0, 5] != 'FlxCo'}
end
patch.each {|i| patch(i, m)}

puts; puts "Among #{@total[0]} activation-related files, \e[1;32m#{@total[1]} were patched, \e[1;33m#{@total[2]} were restored, \e[1;31m#{@total[4]} failed, \e[0mand #{@total[3]} were ignored."

puts; system('pause'); exit
