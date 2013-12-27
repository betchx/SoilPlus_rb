#! /usr/bin/ruby
# encoding: utf-8
#
# ４節点シェル要素の応力出力から断面力を算出
#
# usage:
#    $0 file1.f21 [file2.f21 ...]
#
#  引数： f21ファイルのリスト


require 'soilplus/results/ft21'
require 'narray'

ELEMENT_SEP = ", elm "  # ヘッダのセパレータ for Element
NODE_SEP = ", node "    # ヘッダのセパレータ for Node

def is_node?(key)
  %w(a v u).include?(key[0,1])
end

ARGV.each do |arg|
  base = File.basename(arg,".f21")

  f21 = base + ".f21"
  unless File.file?(f21)
    puts "結果ファイル(#{f21})が見つからないため処理できません．"
    gets
    exit 1
  end

  res = SoilPlus::Results::Dynamic.new(f21)

  dt = res.dt
  xs = (0...res.nstep).map{|x| x*dt}

  SoilPlus::Results::Dynamic::PAIRS.keys.each do |key|
    ids = res.send(key)
    unless ids.empty?
      ids.sort!
      data = ids.map{|i| res.send(key,i)}
      fname = "#{base}-#{key}.csv"
      separator = is_node?(key) ? NODE_SEP : ELEMENT_SEP
      open(fname, "wb"){|out|
        out.puts ["time",*ids].join(separator)
        xs.each_with_index do |tm,i|
          vals = data.map{|wave| wave[i]}
          out.puts [tm,*vals].join(",")
        end
      }
    end
  end
end


