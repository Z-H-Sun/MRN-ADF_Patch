# encoding: ASCII-8Bit
# ruby 2.0.0
print "\033]0;MestReNova 12.0 (Mac) Patcher by Zack\007"

def patch(filename)
    puts "\n\e[1;33mProcessing\e[0m #{filename}..."
    # do not patch patched ones
    if File.exist?(filename + ".bak") then puts("This file might have already been patched. \e[1;33mNo operation performed.\e[0m"); return false end
    f = open(filename, "r+b") # read and write, binary
    g = open(filename + ".bak", "wb")
    @times = @byte = 0 # number of to-be-patched patterns, processed length
    loop do
        b = f.gets(sep="\x80") # read until met with 0x80
        if b.nil? then f.close; g.close; break end # EOF
        len = b.size # read length
        g.write(b) # copy
        byte = (f.pos / 104857.6).to_i
        print "\r\e[1;33mProcessed %.1f MB.\e[0m " % (byte/10.0) if byte != @byte
        @byte = byte
        
        next if len < 4
        if b[-4, 4] == "\x0b\x00\x00\x80"
            pat = f.read(10); f.seek(-10, 1)
            next unless pat.include?("\x0b\x00\x00\x80")
            f.seek(-128, 1); pat = f.read(128);
            ind = pat.rindex("\x75")
            next if ind.nil?
            ind2 = pat.rindex("\x74")
            next if ind2.nil?
            puts "\e[1;32m\rFound pattern\e[0m, JNZ -> JMP: \e[7m74 ..\e[0m .* \e[7m75 ..\e[0m .* \e[7m0B 00 00 80\e[0m .* \e[7m0B 00 00 80\e[0m"
            f.seek(ind - 128, 1); f.write("\x90\x90")
            f.seek(ind2 - 2 - ind, 1); f.write("\x90\x90"); f.seek(126 - ind2, 1)
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
    print "\n\e[1;33mEND OF OPERATION.\e[0m Press Enter to continue."
    STDIN.gets
    _exit(code)
end

# ------------------------------------------------------------------------------

dir = '/Applications/MestReNova.app/Contents/MacOS'
unless Dir.exists?(dir) then puts "\n\e[1;31mSeems that MestReNova is not installed..."; exit end
print "\n\e[1;33mPress Enter to patch MestReNova at \e[0m#{dir}"
STDIN.gets

Dir.chdir(dir)
patch('MestReNova')

# ------------------------------------------------------------------------------

licenseDir = File.join(dir, 'licenses')
Dir.mkdir('licenses') unless Dir.exists?(licenseDir)
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

exit
