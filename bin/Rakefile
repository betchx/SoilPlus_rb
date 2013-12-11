


task :default => ["qplr-sf.exe"]

rule 'exe' => '.exy' do |t|
  sh "exerb #{t.source}"
end

rule '.exy' => ['.rb', '.ver'] do |t|
  rb,ver = *t.sources
  puts rb
  puts ver
  sh "ruby -r exerb/mkexy #{rb}"
  exy = t.name
  tmp = exy + ".tmp"
  File.rename(exy, tmp)
  open(exy, "wb") do |out|
    open(tmp,"rb")do |f|
      while line = f.gets
        if line =~ /^file:/
          out.print open(ver,"rb").read
          out.puts
        end
        out.puts line
      end
    end
  end
  File.unlink(tmp)
end


