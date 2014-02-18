#! /usr/bin/ruby
# coding: SHIFT_JIS

require 'fortran_io'

HEADER = "a4i3d"
RECORD = "iia4i4d*"

need_pause = false

name = {
'STRE' => "各ステップの応力・断面力の認識（板要素は各ステップ応力）",
'FORC' => "板要素の各ステップ断面力の認識",
'STRN' => "各ステップのひずみの認識",
'EFCT' => "各ステップの有効応力の認識",
'EVNT' => "非線形状態の認識"
}


ARGV.each do |file|
  unless file =~ /\.f57$/
    $stderr.puts "f57ファイルではありません： #{file}"
    need_pause = true
    next
  end

  f = FortranUnformattedFile.new(file)

  out = open(file+".csv","wb")

  until f.eof?
    idnt, nelem, istep =  f.get(HEADER)
    out.puts "type, #{idnt}, #{name[idnt]}"
    out.puts "要素数, #{nelem}"
    out.puts "ステップ, #{istep}"
    out.print %w(要素番号 要素タイプ番号 要素タイプ 材料番号 特性番号 応力成分数 ダミー).join(',')
    12.times{ |i| out.print ",結果#{i+1}"}
    out.puts
    nelem.times do |i|
      out.puts f.get(RECORD).join(',')
    end
    out.puts
  end
  out.close
  f.close
end

if need_pause
  $stderr.puts "Press Enter to exit"
  $stdin.gets
end

