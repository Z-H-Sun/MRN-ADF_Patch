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

contents = %Q(<mlic version="1.0">
<licid>{0-0-0-0-0}</licid>
<type>single</type>
<hostid>0-0-0-0</hostid>
<vendor>Mestrelab Research S.L.</vendor>
<purchaser>cs@ccme</purchaser>
<product>%s</product>
<version>%s</version>
<uuid>%s</uuid>
<count>unlimited</count>
<issued>2000-01-01</issued>
<expires>never</expires>
<update>forever</update>
<sign>cnUtYm9hcmQ=</sign>
</mlic>
)
data = {'AFFINImeter-NMR.lic' => ['AFFINImeter-NMR', '1.0', '{0BA83ECE-335C-404A-8226-070838EE6157}'],
'Database.lic' => ['Database', '1.8', '{533B0BF3-4CE1-4f28-A8F8-E2403AF97030}'],
'ElViS.lic' => ['ElViS', '1.3', '{D1956E14-B9AE-4B39-A507-A139A58688E3}'],
'Mass.lic' => ['Mass', '1.8', '{5C1895EB-0054-40B1-BD42-192EF6589F83}'],
'MBioHOS.lic' => ['MBioHOS', '1.0', '{F65FD237-2DC6-48DC-A5C4-653294F80B78}'],
'Mbinding.lic' => ['Mbinding', '1.0', '{0514D764-3D21-464B-BD67-9CCA55AF6510}'],
'MestrelabPredictor.lic' => ['Mestrelab Predictor', '1.8', '{FFB9B818-9D6B-4202-9C7E-B591E0C5C007}'],
'MnovaBatchPhysChem-AAGAC.lic' => ['Mnova Batch PhysChem: Alpha Acid Glycoprotein Affinity Constant', '1.2', '{A989C2D7-2DD3-4F27-ABDE-B144BF89CB05}'],
'MnovaBatchPhysChem-BBPC.lic' => ['Mnova Batch PhysChem: Blood-Brain-Partition Coefficient', '1.2', '{AD2E2594-012D-48AC-8A80-399F3C4A9BB7}'],
'MnovaBatchPhysChem-FBF.lic' => ['Mnova Batch PhysChem: Free Brain Fraction', '1.2', '{AEFF80F9-4D8F-4DD4-90BE-7F28DC1A3478}'],
'MnovaBatchPhysChem-FPF.lic' => ['Mnova Batch PhysChem: Free Plasma Fraction', '1.2', '{AC885539-E620-4DB1-BA8C-A44A50E897A0}'],
'MnovaBatchPhysChem-HSAAC.lic' => ['Mnova Batch PhysChem: Human Serum Albumin Affinity Constant', '1.2', '{A8C4492C-FE86-47A2-83FF-0838868B6FEE}'],
'MnovaBatchPhysChem-MAC.lic' => ['Mnova Batch PhysChem: Membrane Affinity Constant', '1.2', '{AA4BCD25-4337-42C2-834D-A8E14C0B614C}'],
'MnovaBatchPhysChem-PPPB.lic' => ['Mnova Batch PhysChem: Per cent Plasma Protein Binding', '1.2', '{AB6F7B48-834B-40AB-B54B-DC2F0CB1CE74}'],
'MnovaBatchPhysChem-Basic.lic' => ['Mnova Batch PhysChem Basic', '1.2', '{A7258B80-DF87-4C99-81EA-E44EC6468271}'],
'MnovaBatchqNMR.lic' => ['Mnova Batch qNMR', '1.2.1.1740', '{B4A1DA63-354D-4B59-82DD-3266D4775F85}'],
'MnovaBatchSMA.lic' => ['Mnova Batch SMA', '1.0.0.1926', '{08832918-A60B-11E4-89D3-123B93F75CBA}'],
'MnovaBatchVerify.lic' => ['Mnova Batch Verify', '2.0', '{7161B159-6AC7-41DE-B3EA-7D703BA222C9}'],
'MnovaGears.lic' => ['Mnova Gears', '1.0', '{3B25F857-8861-490F-8072-E1577A9FB350}'],
'MnovaIUPACNameV1.0.lic' => ['Mnova IUPAC Name', '1.0', '{C3D1D7C0-A78F-44A0-ACE7-28EA5EA41CBC}'],
'MnovaIUPACNameV1.14.lic' => ['Mnova IUPAC Name', '1.14', '{67AA7320-4992-433B-9EA3-4418C887E779}'],
'MnovaqNMR.lic' => ['Mnova qNMR', '1.2.1.1740', '{5A01D4B0-7E6C-4C09-BF56-0DFCD96AFEFA}'],
'MnovaScreen.lic' => ['Mnova Screen', '1.2', '{462E9690-D602-4857-A113-3E4B48DBF296}'],
'MnovaSMA.lic' => ['Mnova SMA', '1.0.0.1937', '{F657C1C0-6675-11E3-949A-0800200C9A66}'],
'MnovaStereoFitter.lic' => ['Mnova StereoFitter', '1.1', '{A4059C2F-E6C1-4F39-8AD3-89CA17966E9A}'],
'MnovaVerify.lic' => ['Mnova Verify', '1.5', '{6F96FBD7-E418-4013-A9FA-B588F305C21E}'],
'NMR.lic' => ['NMR', '1.8', '{5B0A2812-8EE2-406F-8030-84F5F6AC4A4B}'],
'NMRPredictDesktop.lic' => ['NMRPredict Desktop', '1.8', '{1C479DD8-9A31-4016-AE56-DEE522080B06}'],
'PhysChemProperties.lic' => ['PhysChem Properties', '1.8', '{63CA247B-FA1D-43cb-AAEE-AC0EF2448B9C}'],
'RandomForestNMRPredictor.lic' => ['Random Forest NMR Predictor', '1.0', '{233C512F-83AB-4C4D-93E8-E8F31CEEFF5E}'],
'ReactionMonitoring.lic' => ['Reaction Monitoring', '1.1.0.1443', '{F8559B7C-1F28-4D3C-8F0B-FAE1E87CB364}'],
'StructureElucidation.lic' => ['Structure Elucidation', '1.0', '{6475DEBF-AB41-4FED-AE06-7996A427201C}']}

for i in listNum
    filename = File.join(listDir[i], "MestReNova.exe")
    patch(filename)

    licenseDir = File.join(listDir[i], 'licenses')
    Dir.mkdir(licenseDir) unless File.exists?(licenseDir)
    puts "\n\e[1;33mReleasing .LIC files in\e[0m #{licenseDir}..."

    begin
        data.keys.each {|i| open(File.join(licenseDir, i), 'w') {|f| f.write(contents % data[i])}}
        puts "\e[1;32mAll .LIC files have been created.\e[0m"
    rescue
        puts "\e[1;31mError occurred:\e[0m"
        puts $!.inspect
        puts $@.inspect
    end

end
exit
