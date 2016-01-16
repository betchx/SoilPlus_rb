#! /usr/bin/ruby
# encoding: sjis
#
# f22 ファイルのデータを出力する
#
# usage:
#    $0 [options] file1.f22 [file2.f22 ...]
#
#  引数： f22ファイルのリスト


require 'optparse'
require 'soilplus/results/ft22'
require 'narray'

ARGV.each do |arg|
  base = File.basename(arg,".f22")

  f22 = base + ".f22"
  unless File.file?(f22)
    puts "結果ファイル(#{f22})が見つからないため処理できません．"
    gets
    exit 1
  end

  res = SoilPlus::Results::SSCurves.new(f22)
  t = res.time

  out_file = base + "-f22.csv"
  open(out_file, "wb") do |out|
    out.puts <<-"NNN"
結果ファイル:,#{f22}
ジョブ番号:,#{res.jobn}
地震波識別番号:,#{res.idnt}
荷重自由度:,#{res.lfd}
ステップ数:,#{res.nstp}
積分時間間隔:,#{res.dt}
継続時間:,#{res.tmax}
入力波の最大値:,#{res.galo}
骨格曲線数:,#{res.nmsc}
解析タイトル:,#{res.itle}
荷重タイトル:,#{res.itld}

    NNN

    out.print "time"
    res.each do |curve|
      out.print ",Elm#{curve.iel}-#{curve.component}-#{curve.x_title}"
      out.print ",Elm#{curve.iel}-#{curve.component}-#{curve.y_title}"
    end
    out.puts

    res.length.times do |i|
      arr = [ t[i] ]
      res.each do |curve|
        arr << curve[i]
      end
      out.puts arr.flatten.join(",")
    end
  end
end


