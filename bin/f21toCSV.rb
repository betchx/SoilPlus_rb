#! /usr/bin/ruby
# encoding: utf-8
#
# f21 ファイルのデータを出力する
#
# usage:
#    $0 [options] file1.f21 [file2.f21 ...]
#
#  引数： f21ファイルのリスト


require 'optparse'
require 'soilplus/results/ft21'
require 'narray'

ELEMENT_SEP = ", elm "  # ヘッダのセパレータ for Element
NODE_SEP = ", node "    # ヘッダのセパレータ for Node

def is_node?(key)
  %w(a v u).include?(key[0,1])
end

$tags = []

OptionParser.new do |opt|
  all_key = SoilPlus::Results::Dynamic::PAIRS.keys
  # nodes
  opt.on('-a', '--acc', "Output Acceleration") do
    $tags.concat all_key.select{|k| k =~ /^a/}
  end
  opt.on('-v', "--vel", "Output Velocity") do
    $tags.concat all_key.select{|k| k =~ /^v/}
  end

  opt.on('-u', "--dis", "Output Displacement") do
    $tags.concat all_key.select{|k| k =~ /^u/}
  end

  opt.on('-N', "--node","Output Node results (ACC, Vel, Dis)") do
    $tags.concat all_key.select{|k| k =~ /^[avu]/}
  end

  #elements
  opt.on('-E', '--element', "Output Element Results")do
    $tags.concat all_key.select{|k| k !~ /^[avu]/}
  end
  opt.on('-s', '--stress', "Output Stresses") do
    $tags.concat all_key.select{|k| k =~ /^s/}
  end
  opt.on('-e', '--strain', "Output Strains") do
    $tags.concat all_key.select{|k| k =~/^e/}
  end
  opt.on('-f', '--force', "Output Section Forces and Moments") do
    $tags.concat all_key.select{|k| k =~/^[FM]/}
  end
  opt.parse!(ARGV)
  if $tags.empty?
    $tags = SoilPlus::Results::Dynamic::PAIRS.keys
  end
end


ARGV.each do |arg|
  base = File.basename(arg,".f21")

  f21 = base + ".f21"
  unless File.file?(f21)
    puts "結果ファイル(#{f21})が見つからないため処理できません．"
    gets
    exit 1
  end

  Dir.mkdir(base) unless File.directory?(base)

  res = SoilPlus::Results::Dynamic.new(f21)

  dt = res.dt
  # 時刻ゼロのデータは出力されないので，1からスタート
  xs = (1..res.nstep).map{|x| x*dt}

  $tags.each do |key|
    ids = res.send(key)
    unless ids.empty?
      ids.sort!
      data = ids.map{|i| res.send(key,i)}
      fname = "#{base}/#{base}-#{key}.csv"
      separator = is_node?(key) ? NODE_SEP : ELEMENT_SEP
      open(fname, "wb"){|out|
        out.puts ["time",*ids].join(separator)
        xs.each_with_index do |tm,i|
          vals = data.map{|wave| sprintf("%g",wave[i])}
          out.puts [sprintf("%g",tm),*vals].join(",")
        end
      }
    end
  end
end


