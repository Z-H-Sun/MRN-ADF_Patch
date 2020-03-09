# encoding: ASCII-8Bit
# ruby 1.8.7
system("title MestReNova 14/12 Patcher by Zack")
@total = [0, 0] # number of [all, patched] files

def patch(filename)
    puts "\n\e[1;33mProcessing\e[0m #{filename}..."
    # do not patch patched ones
    if File.exist?(filename + ".bak")
        puts 'This file might have already been patched [Press `Y\' to override].'
        if `choice /N`.chomp.downcase != 'y'
            puts("\e[1;33mNo operation performed.\e[0m")
            return false
        end
    end
    f = open(filename, "r+b") # read and write, binary
    g = open(filename + ".bak", "wb")
    @times = 0 # number of to-be-patched patterns
    loop do
        b = f.gets(sep="\x80") # read until met with 0x80
        if b.nil? then f.close; g.close; break end # EOF
        len = b.size # read length
        g.write(b) # copy
        
        next if len < 17
        d = b[-17, 17] # check the pattern
        case d[-4, 4]
        when "\x0b\x00\x00\x80"
            ind = d.index("\x75")
            next if ind.nil?
            pat = f.read(17); f.seek(-17, 1)
            next unless pat.include?("\x0b\x00\x00\x80")
            puts "\e[1;32mFound pattern\e[0m, JNZ -> JMP: \e[7m75 ..\e[0m .* \e[7m0B 00 00 80\e[0m .* \e[7m0B 00 00 80\e[0m"
            f.seek(ind - 17, 1); f.write("\xeb"); f.seek(16 - ind, 1)
        when "\x0c\x00\x00\x80"
            ind = d.index("\x75")
            next if ind.nil?
            pat = f.read(17); f.seek(-17, 1)
            next unless pat.include?("\x0c\x00\x00\x80")
            puts "\e[1;32mFound pattern\e[0m, JNZ -> JMP: \e[7m75 ..\e[0m .* \e[7m0C 00 00 80\e[0m .* \e[7m0C 00 00 80\e[0m"
            f.seek(ind - 17, 1); f.write("\xeb"); f.seek(16 - ind, 1)
        when "\x06\x00\x09\x80"
            ind = d.index("\x0f\x85")
            next if ind.nil?
            puts "\e[1;32mFound pattern\e[0m, JNZ -> JMP: \e[7m0F 85 .. .. .. ..\e[0m .* \e[7m06 00 09 80\e[0m .."
            f.seek(ind - 17, 1); f.write("\x90\xe9"); f.seek(15 - ind, 1)
        else
            next # not a to-be-patched pattern; roll back
        end
        @times += 1
    end
    if @times.zero?
        # not applicable
        File.delete(filename + ".bak"); puts "\e[1;33mNo to-be-patched pattern found in this file.\e[0m"
        return false
    else
        puts "\e[1;33mPatched #{@times} place(s) in this file.\e[0m"
        @total[1] += 1
        return true
    end
rescue # error
    puts "\e[1;31mError occurred:\e[0m"
    puts $!.inspect
    puts $@.inspect
    return false
end

alias :_exit :exit
def exit(code=0) # to pause before exiting
    print "\n\e[1;33mEND OF OPERATION.\e[0m "
    system "pause"
    _exit(code)
end

# ------------------------------------------------------------------------------

listVer = [nil] * 5 # Five vacant positions should suffice
listDir = [nil] * 5
listNum = []
num = 0

['/reg:64', '/reg:32'].each do |i|
    list = ''
    ['HKLM', 'HKCU'].each {|j| list +=  `reg query #{j}\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall /s /t REG_SZ /f MestReNova #{i} 2>nul`}
    for k in list.split("\n\n")
        next unless k.include?('DisplayName')
        key = k.strip.split("\n")[0]
        listVer[num] = `reg query \"#{key}\" /v Comments #{i} 2>nul`.strip.split('  ')[-1]
        listDir[num] = `reg query \"#{key}\" /v InstallLocation #{i} 2>nul`.strip.split('  ')[-1]
        num += 1
    end
end

if num.zero? then puts "\n\e[1;31mSeems that MestReNova is not installed..."; exit end
puts "\nPlease check the following installation information:"
listVer.each_with_index {|i, x| unless i.nil? then puts "\e[1;33m[#{x+1}] #{i}\n\t\e[0mInstalled at: \e[4m#{listDir[x]}\e[0m"; listNum << x end}
print "\nPlease choose the desired program to be patched by entering the number before it, or directly press ENTER to patch all of them by default: "
l = STDIN.gets.to_i
listNum = [l - 1] unless l.zero?

for i in listNum
    filename = File.join(listDir[i], "MestReNova.exe")
    patch(filename)

# ------------------------------------------------------------------------------

licenseDir = File.join(listDir[i], 'licenses')
Dir.mkdir(licenseDir) unless File.exists?(licenseDir)
puts "\n\e[1;33mReleasing .LIC files in\e[0m #{licenseDir}..."

begin
d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>AFFINImeter-NMR</product>
<version>1.0</version>
<uuid>{0ba83ece-335c-404a-8226-070838ee6157}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'AFFINImeter-NMR.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Database</product>
<version>1.8</version>
<uuid>{533B0BF3-4CE1-4f28-A8F8-E2403AF97030}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Database.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mass</product>
<version>1.8</version>
<uuid>{5c1895eb-0054-40b1-bd42-192ef6589f83}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mass.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mbinding</product>
<version>1.0</version>
<uuid>{0514d764-3d21-464b-bd67-9cca55af6510}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mbinding_v1.0.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Alpha Acid Glycoprotein Affinity Constant</product>
<version>1.2</version>
<uuid>{A989C2D7-2DD3-4F27-ABDE-B144BF89CB05}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Alpha Acid Glycoprotein Affinity Constant.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Blood-Brain-Partition Coefficient</product>
<version>1.2</version>
<uuid>{AD2E2594-012D-48AC-8A80-399F3C4A9BB7}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Blood-Brain-Partition Coefficient.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Free Brain Fraction</product>
<version>1.2</version>
<uuid>{AEFF80F9-4D8F-4DD4-90BE-7F28DC1A3478}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Free Brain Fraction.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Free Plasma Fraction</product>
<version>1.2</version>
<uuid>{AC885539-E620-4DB1-BA8C-A44A50E897A0}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Free Plasma Fraction.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Human Serum Albumin Affinity Constant</product>
<version>1.2</version>
<uuid>{A8C4492C-FE86-47A2-83FF-0838868B6FEE}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Human Serum Albumin Affinity Constant.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Membrane Affinity Constant</product>
<version>1.2</version>
<uuid>{AA4BCD25-4337-42C2-834D-A8E14C0B614C}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Membrane Affinity Constant.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem: Per cent Plasma Protein Binding</product>
<version>1.2</version>
<uuid>{AB6F7B48-834B-40AB-B54B-DC2F0CB1CE74}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem - Per cent Plasma Protein Binding.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch PhysChem Basic</product>
<version>1.2</version>
<uuid>{A7258B80-DF87-4C99-81EA-E44EC6468271}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Batch PhysChem Basic.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch qNMR</product>
<version>1.2.1.1740</version>
<uuid>{B4A1DA63-354D-4B59-82DD-3266D4775F85}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mnova Batch qNMR.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch SMA</product>
<version>1.0.0.1926</version>
<uuid>{08832918-A60B-11E4-89D3-123B93F75CBA}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mnova Batch SMA.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{00000000-0000-0000-0000-00000000000}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Batch Verify</product>
<version>2.0</version>
<uuid>{7161B159-6AC7-41de-B3EA-7D703BA222C9}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova batch verify.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Gears</product>
<version>1.0</version>
<uuid>{3b25f857-8861-490f-8072-e1577a9fb350}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Gears_v1.0.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova IUPAC Name</product>
<version>1.0</version>
<uuid>{c3d1d7c0-a78f-44a0-ace7-28ea5ea41cbc}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova IUPAC Name_v1.0.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova qNMR</product>
<version>1.2.1.1740</version>
<uuid>{5A01D4B0-7E6C-4C09-BF56-0DFCD96AFEFA}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mnova qNMR.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Screen</product>
<version>1.2</version>
<uuid>{462E9690-D602-4857-A113-3E4B48DBF296}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mnova Screen.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova SMA</product>
<version>1.0.0.1937</version>
<uuid>{F657C1C0-6675-11E3-949A-0800200C9A66}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Mnova SMA.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Mnova Verify</product>
<version>1.5</version>
<uuid>{6f96fbd7-e418-4013-a9fa-b588f305c21e}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Mnova Verify.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>NMR</product>
<version>1.8</version>
<uuid>{5b0a2812-8ee2-406f-8030-84f5f6ac4a4b}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'NMR.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>NMRPredict Desktop</product>
<version>1.8</version>
<uuid>{1c479dd8-9a31-4016-ae56-dee522080b06}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'NMRPredict Desktop.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>PhysChem Properties</product>
<version>1.8</version>
<uuid>{63CA247B-FA1D-43cb-AAEE-AC0EF2448B9C}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'PhysChem Properties.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Random Forest NMR Predictor</product>
<version>1.0</version>
<uuid>{233c512f-83ab-4c4d-93e8-e8f31ceeff5e}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Random Forest NMR Predictor.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Reaction Monitoring</product>
<version>1.1.0.1443</version>
<uuid>{F8559B7C-1F28-4D3C-8F0B-FAE1E87CB364}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
open(File.join(licenseDir, 'Reaction Monitoring.lic'), 'w') {|f| f.write(d)}

d = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>foss@ru-board</purchaser>
<product>Structure Elucidation</product>
<version>1.0</version>
<uuid>{6475debf-ab41-4fed-ae06-7996a427201c}</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>)
open(File.join(licenseDir, 'Structure Elucidation_v1.0.lic'), 'w') {|f| f.write(d)}

puts "\e[1;32mAll .LIC files have been created.\e[0m"
rescue
    puts "\e[1;31mError occurred:\e[0m"
    puts $!.inspect
    puts $@.inspect
end

end
exit
