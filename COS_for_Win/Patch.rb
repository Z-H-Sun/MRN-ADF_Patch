system("title ChemOffice Suite 18~20 Patcher by Zack")
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
    offset = d.rindex(/\x2d\x04\x17\x0a\x2b\x02[\x16\x17]\x0a\x06\x0b\x07\x2a/)
    unless offset.nil?
      @total[0] += 1
      puts "\n\e[4m#{filename}\e[0m"
      offset2 = ind+offset+7-BUF_SIZE
      if d[offset, 7] == "\x2d\x04\x17\x0a\x2b\x02\x17"
        print "\e[1;33mPatched Pattern\e[0m [2d 04 17 0a 2b 02 \e[7m17\e[0m 0a 06 0b 07 2a] \e[1;33mfound at offset 0x#{(pos+offset2).to_s(16)}\e[0m "
      else
        print "\e[1;32mPattern to be patched\e[0m [2d 04 17 0a 2b 02 \e[7m16\e[0m 0a 06 0b 07 2a] \e[1;32mfound at offset 0x#{(pos+offset2).to_s(16)}\e[0m "
      end
      tempMode = mode
      if mode == 'A'
        print "\nChoose the \e[4m[P]atch\e[0m or \e[4m[R]estore\e[0m mode: "
        print(tempMode = `choice /T 10 /C PR /D P /N`.chomp.upcase)
      end
      if d[offset, 7] == "\x2d\x04\x17\x0a\x2b\x02\x17"
        if tempMode == 'R'
          f2 = open(filename, 'r+b')
          f2.seek(pos+offset2, 0)
          f2.write("\x16")
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
puts "\nYou have:"
for i in 0..1 # check 32-bit and 64-bit registry
  list = ''
  print "  \e[1;33m#{(i+1)*32}-bit ChemOffice\e[0m "
  ['HKLM', 'HKCU'].each {|j| list +=  `reg query #{j}\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall /s /t REG_SZ /f ChemOffice /reg:#{(i+1)*32} 2>nul`} # check CurrentUser and LocalMachine
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
rename = []; patch = []
exts = ['.exe', '.dll', '.ocx']
for i in 0..1
  next if listVer[i].empty?
  rename << File.join(listVer[i][3], 'Common\DLLs\FlxComm' + '64'*i + '.dll')
  rename << File.join(listVer[i][3], 'Common\DLLs\FlxCore' + '64'*i + '.dll')
  next if listVer[i][1] < 19
  Find.find(listVer[i][3]) {|j| patch << j.gsub('/', "\\") if exts.include?(File.extname(j).downcase) and File.basename(j)[0, 5] != 'FlxCo'}
end
rename.each do |i|
  puts "\n\e[4m#{i}\e[0m"
  @total[0] += 1
  if File.exist?(i)
    print "\e[1;32mFound .dll file\e[0m "
  elsif File.exist?(i+'.bak')
    print "\e[1;33mFound .bak file\e[0m "
  else
    print "\e[1;31mFile not found.\e[0m"
    @total[4] += 1
  end
  tempMode = m
  if m == 'A'
    print "\nChoose the \e[4m[P]atch\e[0m or \e[4m[R]estore\e[0m mode: "
    print(tempMode = `choice /T 10 /C PR /D P /N`.chomp.upcase)
  end
  begin
    if File.exist?(i)
      if tempMode == 'R'
        puts ": Ignored."
        @total[3] += 1
      else
        File.rename(i, i+'.bak')
        puts "\e[1;32m: Renamed to .bak file.\e[0m"
        @total[1] += 1
      end
    else
      if tempMode == 'R'
        File.rename(i+'.bak', i)
        puts "\e[1;33m: Renamed to .dll file.\e[0m"
        @total[2] += 1
      else
        puts ": Ignored."
        @total[3] += 1
      end
    end
  rescue
    puts "\e[1;31mError occurred:"
    @total[4] += 1
    puts $!.inspect; puts $@.inspect
    print "\e[0m"
  end
end
patch.each {|i| patch(i, m)}

puts; puts "Among #{@total[0]} activation-related files, \e[1;32m#{@total[1]} were patched, \e[1;33m#{@total[2]} were restored, \e[1;31m#{@total[4]} failed, \e[0mand #{@total[3]} were ignored."

if m == 'R' then puts; system('pause'); exit end

for i in 0..1
  next if listVer[i].empty?
  next if listVer[i][1] < 18
  key = "HKLM\\Software\\PerkinElmerInformatics\\ChemBioOffice\\#{listVer[i][1]}.#{listVer[i][2]}\\Ultra"
  `reg add #{key} /f /reg:#{(i+1)*32}`
  `reg add #{key} /v \"Activation Code\" /t REG_SZ /d 6UE-7IMW3-5W-QZ5P-J3PCX-OHDX-35GRN /f /reg:#{(i+1)*32}`
  `reg add #{key} /v \"Serial Number\" /t REG_SZ /d 875-385499-9864 /f /reg:#{(i+1)*32}`
  `reg add #{key} /v Success /t REG_SZ /d True /f /reg:#{(i+1)*32}`
end

puts "\nRegistry entries modified. \e[1;32mEND OF PATCH.\e[0m\nOptional: In the following lines, please input \e[4marbitrary\e[0m info (or leave blank), and enjoy using ChemOffice Crack!" unless m == 'R'

info = ['', '', '']
print '  User Name:    _______________'; print "\b"*15
info[0] = `cmd /V /C \"set /p var=&& echo !var!\"`.chomp
print '  Email:        _______________'; print "\b"*15
info[1] = `cmd /V /C \"set /p var=&& echo !var!\"`.chomp
print '  Organization: _______________'; print "\b"*15
info[2] = `cmd /V /C \"set /p var=&& echo !var!\"`.chomp

for i in 0..1
  next if listVer[i].empty?
  next if listVer[i][1] < 18
  key = "HKLM\\Software\\PerkinElmerInformatics\\ChemBioOffice\\#{listVer[i][1]}.#{listVer[i][2]}\\Ultra"
  `reg add #{key} /v \"User Name\" /t REG_SZ /d \"#{info[0]}\" /f /reg:#{(i+1)*32}`
  `reg add #{key} /v Email /t REG_SZ /d \"#{info[1]}\" /f /reg:#{(i+1)*32}`
  `reg add #{key} /v Organization /t REG_SZ /d \"#{info[2]}\" /f /reg:#{(i+1)*32}`
end
puts; system('pause')
