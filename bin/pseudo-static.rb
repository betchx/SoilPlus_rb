#! /usr/bin/ruby
# coding: sjis

ARGV.each do |file|
  next unless file =~ /\.dat$/i
  out_file = file.sub(/\.dat$/i, '_ps.dat')
  open(out_file, "wb") do |out|
    out.puts "*" * 80
    out.puts "* Pseudo Static Analysis by #{$0}"
    out.puts "*  Dynamic analysis with very small density"
    out.puts "*" * 80
    open(file, "rb") do |f|
      while line = f.gets
        case line
        when /^MAT /
          line[-10..-3] = sprintf("%8g",0.1)
          out.puts line
        when /^PDMP/
          #out.puts "**   " + line
          #out.puts "PDMP         0.0     0.0"
          #out.puts line
          b,a = line.split[1,2].map{|x| x.sub(/(\d)([-+]\d)/,'\1E\2').to_f * 10.0}
          out.puts sprintf("PDMP    %8g%8g",b,a)
        when /^CMAS/
          # skip 
        else
          out.puts line
        end
      end
    end
  end
end




