system("title ChemOffice Suite 18~22 Patcher by Zack")
Dir.chdir(File.dirname($Exerb ? ExerbRuntime.filepath : __FILE__)) # change currentDir to the file location

@total = [0, 0, 0, 0, 0] # number of [all, patched, restored, ignored, failed] files

def patch(filename, mode)
  f = open(filename, 'r+b')
  while not f.eof?
    d = f.gets(sep="\x2a") # read until met with 0x2a (retn)
    next if d.size < 42 # Filter 1
    next unless d[-5, 5] == "\x0a\x06\x0b\x07\x2a"
    next unless d[-12, 6] == "\x2d\x04\x17\x0a\x2b\x02" # Filter 2
    case d[-6]
    when 0x17
      patched = true
    when 0x16
      patched = false
    else
      next
    end
    @total[0] += 1
    f.seek(-6, 1)
    puts "\n\e[4m#{filename}\e[0m"
    print "\e[1;33m#{patched ? 'Patched pattern' : 'Pattern to be patched'}\e[0m [2d 04 17 0a 2b 02 \e[7m1#{patched ? 7 : 6}\e[0m 0a 06 0b 07 2a] \e[1;33mfound at offset 0x#{f.tell.to_s(16)}\e[0m "
    tempMode = mode
    if mode == 'A'
      print "\nChoose the \e[4m[P]atch\e[0m or \e[4m[R]estore\e[0m mode: "
      print(tempMode = `choice /T 10 /C PR /D P /N`.chomp.upcase)
    end
    if patched
      if tempMode == 'R'
        f.write("\x16")
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
        f.write("\x17")
        puts "\e[1;32m: Patched.\e[0m"
        @total[1] += 1
      end
    end
    break
  end
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
rename = []; patch = []
exts = ['.exe', '.dll', '.ocx', '.pyd']
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
