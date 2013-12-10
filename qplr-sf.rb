#! /usr/bin/ruby
# encoding: utf-8
#
# ４節点シェル要素の応力出力から断面力を算出
#
# usage:
#    $0 file1.f21 [file2.f21 ...]
#
#  引数： f21ファイルのリスト


require 'ft21'
require 'narray'

HSEP = ", elm "  # ヘッダのセパレータ

# シェル要素の情報をパースし保持するためのクラス
class QPLR
  def initialize(line)
    @i = line[8,8].to_i
    @mat = line[16,8].to_i
    @prop = line[24,8].to_i
    @nodes = line[40,8*4].unpack("a8"*4).map{|x| x.to_i}
  end
  attr_reader :i, :mat, :prop, :nodes
  def [](n) @nodes[n] end
end

# 出力の下請け関数
def output_data(out, xs, ids, data)
  out.puts ["time",*ids].join(HSEP)
  xs.each_with_index do |i,tm|
    vals = ids.map{|eid| data[eid][i]}
    out.puts [tm,*vals].join(",")
  end
end


ARGV.each do |arg|

  base = File.basename(arg,".f21")

  f21 = base + ".f21"
  unless File.file?(f21)
    puts "結果ファイル(#{f21})が見つからないため処理できません．"
    exit 1
  end

  dat = open(base+".dat","rb").readlines



  # obtain eid list of QPLR   シェル要素の要素ID一覧を取得
  qplr_list = dat.select{|line| line =~ /^QPLR/}.map{|line| QPLR.new(line)}
  qplr_ids = qplr_list.map{|x| x.i}
  qplr_map = {}
  qplr_list.each do |q|
    qplr_map[q.i] = q
  end

  # 板厚と単位幅当り断面係数のリストを作成
  t_list = []
  z_list = []
  dat.select{|line| line =~ /^PROP/}.each do |x|
    i = x[8,8].to_i
    t = x[16,16].to_f
    t_list[i] = t
    # I = BT^3/12  y = T/2   Z=I/y = BT^3/12 × 2/T = BT^2/6
    z_list[i] = t*t/6.0
  end

=begin
# 結果からフィルタできるので，不要と考えられるため，無効化
# scan and get eids with MKEL / MKE2
candidate = dat.select{|line| line =~ /^MKE[L2]/ }.map{|line|
  line.unpack("@16"+"a8"*8).map{|x| x.strip}.reject{|x| x.empty?}
}.flatten.sort.uniq & qplr_list
=end

  res = SoilPlus::Results::Dynamic.new(f21)

  # 計算可能なIDを取得する．

  # SoilPlus2011r1b2の場合
  #  上面応力(sxx) と 下面応力(Fx_2)
  fx_eid = (res.sxx & res.Fx_2 & qplr_ids).sort
  fy_eid = (res.syy & res.Fy_2 & qplr_ids).sort
  ## fz_eid = res.szz & res.Fz_2 & qplr_ids # Z方向は基本使わないので無視
  sx_eid = (res.szx & res.Mz_2 & qplr_ids).sort
  sy_eid = (res.syz & res.My_2 & qplr_ids).sort

  # 断面力の計算．
  # 要素幅の計算も不可能ではないが，バグの要因となりうるため，
  # ひとまず単位幅あたりで計算する．

  # X direction
  fx = []
  sx = []
  mx = []
  fx_eid.each do |eid|
    s1 = NArray[*res.sxx(eid)]
    s2 = NArray[*res.Fx_2(eid)]
    pid = qplr_map[eid].prop
    t = t_list[pid]
    z = z_list[pid]
    fx[eid] = (s1+s2)*0.5*t
    mx[eid] = (s1-s2)*0.5*z    # sigma = M/Z => M = siga * Z
  end
  sx_eid.each do |eid|
    s1 = NArray[*res.szx(eid)]
    s2 = NArray[*res.Mz_2(eid)]
    pid = qplr_map[eid].prop
    t = t_list[pid]
    sx[eid] = (s1+s2)*0.5*t
  end

  # Y direction
  fy = []
  my = []
  fy_eid.each do |eid|
    s1 = NArray[*res.syy(eid)]
    s2 = NArray[*res.Fy_2(eid)]
    pid = qplr_map[eid].prop
    t = t_list[pid]
    z = z_list[pid]
    fy[i] = (s1+s2)*0.5*t
    my[i] = (s1-s2)*0.5*z    # sigma = M/Z => M = siga * Z
  end
  sy_eid.each do |eid|
    s1 = NArray[*res.syz(eid)]
    s2 = NArray[*res.My_2(eid)]
    pid = qplr_map[eid].prop
    t = t_list[pid]
    sy[eid] = (s1+s2)*0.5*t
  end


  dt = res.dt
  xs = (0...res.nstep).map{|x| x*dt}

  # output
  unless fx_eid.empty?
    #Fx
    open(base+"-Fx.csv","wb"){|out|
      output_data(out, xs, fx_eid, fx)
    }
    #Mx
    open(base+"-Mx.csv","wb"){|out|
      output_data(out, xs, fx_eid, mx)
    }
  end
  unless sx_eid.empty?
    #Sx
    open(base+"-Sx.csv","wb"){|out|
      output_data(out, xs, sx_eid, sx)
    }
  end
  unless fy_eid.empty?
    #Fy
    open(base+"-Fy.csv","wb"){|out|
      output_data(out, xs, fy_eid, fy)
    }
    #My
    open(base+"-My.csv","wb"){|out|
      output_data(out, xs, fy_eid, my)
    }
  end
  unless sy_eid.empty?
    #Sy
    open(base+"-Sy.csv","wb"){|out|
      output_data(out, xs, sy_eid, sy)
    }
  end

end
