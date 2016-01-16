#! /usr/bin/ruby
# encoding: sjis
#
# f22 �t�@�C���̃f�[�^���o�͂���
#
# usage:
#    $0 [options] file1.f22 [file2.f22 ...]
#
#  �����F f22�t�@�C���̃��X�g


require 'optparse'
require 'soilplus/results/ft22'
require 'narray'

ARGV.each do |arg|
  base = File.basename(arg,".f22")

  f22 = base + ".f22"
  unless File.file?(f22)
    puts "���ʃt�@�C��(#{f22})��������Ȃ����ߏ����ł��܂���D"
    gets
    exit 1
  end

  res = SoilPlus::Results::SSCurves.new(f22)
  t = res.time

  out_file = base + "-f22.csv"
  open(out_file, "wb") do |out|
    out.puts <<-"NNN"
���ʃt�@�C��:,#{f22}
�W���u�ԍ�:,#{res.jobn}
�n�k�g���ʔԍ�:,#{res.idnt}
�׏d���R�x:,#{res.lfd}
�X�e�b�v��:,#{res.nstp}
�ϕ����ԊԊu:,#{res.dt}
�p������:,#{res.tmax}
���͔g�̍ő�l:,#{res.galo}
���i�Ȑ���:,#{res.nmsc}
��̓^�C�g��:,#{res.itle}
�׏d�^�C�g��:,#{res.itld}

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


