# ruby 1.8.7
$paramComment = ["S_12^h [eV]", "H_11^h [eV]", "H_22^h [eV]", "J_12^h [eV]", "V_h [eV]", "|V_h| [meV]", "S_12^e [eV]", "H_11^e [eV]", "H_22^e [eV]", "J_12^e [eV]", "V_e [eV]", "|V_e| [meV]"]
$paramComment_2 = ["\e[1;32mS_12^h\t[eV]\e[0m", "\e[1;32mH_11^h\t[eV]\e[0m", "\e[1;32mH_22^h\t[eV]\e[0m", "\e[1;32mJ_12^h\t[eV]\e[0m", "\e[1;32mV_h\t[eV]\e[0m", "\e[1;32m|V_h|\t[meV]", "\e[1;36mS_12^e\t[eV]\e[0m", "\e[1;36mH_11^e\t[eV]\e[0m", "\e[1;36mH_22^e\t[eV]\e[0m", "\e[1;36mJ_12^e\t[eV]\e[0m", "\e[1;36mV_e\t[eV]\e[0m", "\e[1;36m|V_e|\t[meV]"]
system('Title View CTI Output by Zack')

def readout(filename, fileout)
    f = open(filename)
    puts; puts "\e[1;33m#{filename}\e[0m"; fileout.print(filename+',')
    param = ([nil] * 4 << 0 << 0) * 2
    while not f.eof
        l = f.readline; ind = nil
        if l.include?('Overlap integral')
            if l.include?('(hole)') then ind = 0
            elsif l.include?('(electron)') then ind = 6
            end
        elsif l.include?('Site energy')
            n = l[/\d./].to_i
            next if n.zero?
            if l.include?('(hole)') then ind = n
            elsif l.include?('(electron)') then ind = n+6
            end
        elsif l.include?('Charge transfer integral')
            if l.include?('(hole)') then ind = 3
            elsif l.include?('(electron)') then ind = 9
            end
        end
        param[ind] = l.split(':')[1].strip unless ind.nil?
    end
    param.each_with_index {|j, x| raise("Error: No \"#{$paramComment[x]}\" entry can be read") if j.nil?}
    2.times {|i| ec = (param[6*i+3].to_f-param[6*i].to_f*(param[6*i+1].to_f+param[6*i+2].to_f)/2)/(1-param[6*i].to_f**2); param[6*i+4] = '%.12f' % ec; param[6*i+5] = '%.12f' % (ec.abs*1000)}
    param.each_with_index {|j, x| print "#{$paramComment_2[x]}\t:\t#{j}#{(x%2).zero? ? "\t\t" : "\n"}"}
    fileout.puts(param.join(','))
    return param
rescue RuntimeError
    puts "\e[1;31m#{$!}\e[0m"; fileout.puts $!
    return nil
rescue
    puts "\e[1;31m#{$!.inspect}\t#{$@.inspect}\e[0m"; fileout.puts $!.inspect+','+$@.inspect
ensure
    f.close
end

begin
    d = Dir.entries('.'); fs = []
    d.each {|i| fs << i if File.extname(i)=='.out'}
    puts "\n\e[1;33mFound \e[1;32m#{fs.size}\e[1;33m .out file(s) in this folder: \e[0m" + File.expand_path('.')
    fs.each_with_index {|i, x| puts "[#{x+1}]\t#{i}"}
    print "\n\e[1;33mSelect the output of interest by entering the corresponding number, or otherwise read all of them by default: \e[0m"
    l = STDIN.gets.to_i
    fSum = open('outSummary.csv', 'w')
    fSum.puts("Entry," + $paramComment.join(","))
    if l.zero? then fs.each{|k|readout(k, fSum)}
    else f = readout(fs[l-1], fSum)
    end
    fSum.close
    raise("\e[1;33mEnd reading.\e[0m (S_12: overlap integrals; H_11, H_22: site energies; J_12: charge transfer integrals; V = [J_12 - S_12(H_11 + H_22) / 2] / (1 - S_12 ^ 2): electronic couplings)")
rescue RuntimeError
    puts "\e[1;31m"
    puts $!; print "\e[0m"
    system('pause')
    system('start outSummary.csv')
    system('cls')
    retry
rescue
    puts "\e[1;31m"
    puts $!.inspect
    puts $@.inspect; print "\e[0m"
    system('pause')
    system('cls')
    retry
end
