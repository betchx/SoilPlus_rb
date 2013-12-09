#! /usr/bin/ruby
# encoding: utf-8
# SoilPlusの解析結果FT21 (*.f21) のデータを読み込むクラス
#

require 'fortran_io'

module SoilPlus
  module Results
    class Dynamic
      NAME = "FT21"
      EXT = ".f21"

      def initialize(basename = nil)
        @io = nil
        @data = {}
        open(basename) if basename
      end

      def open(basename)
        @filename = basename + EXT
        @filename.sub!(EXT+EXT,EXT)
        @io = FortranUnformattedFile.new(@filename)
        while line = @io.next_record
          arr = line.unpack("a4VVVa4a4EEEE*")
          idnt = arr.shift   # データ種別
          nstp = arr.shift   # ステップ数
          idummy = arr.shift # 等価線形解析の収束回数
          ige = arr.shift    # 節点番号，要素番号
          ifd1 = arr.shift   # 成分 その１
          ifd2 = arr.shift   # 成分 その２ （応力や断面力で使用）
          dt   = arr.shift   # 積分時間間隔 もしくは 解析周波数間隔
          smax = arr.shift   # 最大応答値
          stim = arr.shift   # 最大応答値発生時刻
          # arrののこりは時刻暦毎の応答値

          tag = idnt+ifd1+ifd2+"@#{ige}"
          @data[tag] = arr

        end
        # 保存
        @dt = dt
        @nstep = nstp

      end

      PAIRS = {}
      %w(x y z).each do |k|
        u = k.upcase
        kk = k + k
        PAIRS["s#{kk}"]  = "HSTRSIG  #{u}  "
        PAIRS["E#{kk}"]  = "HSRNEPS  #{u}  "
        PAIRS["F#{k}_1"] = "HFRCFRC  #{u}  "
        PAIRS["F#{k}_2"] = "HFRCFRC2 #{u}  "
        PAIRS["M#{k}_1"] = "HFRCMOM  #{u}  "
        PAIRS["M#{k}_2"] = "HFRCMOM2 #{u}  "
        PAIRS["a#{k}"]   = "HACC #{u}      "
        PAIRS["v#{k}"]   = "HVEL #{u}      "
        PAIRS["u#{k}"]   = "HDSP #{u}      "
      end
      %w(xy yz zx).each do |k|
        rev = k.reverse
        PAIRS["s#{k}"]   = "HSTRTAU #{k.upcase}  "
        PAIRS["s#{rev}"] = "HSTRTAU #{k.upcase}  "
        PAIRS["e#{k}"]   = "HSRNEPS #{k.upcase}  "
        PAIRS["e#{rev}"] = "HSRNEPS #{k.upcase}  "
      end
      PAIRS.each do |key, val|
        define_method(key){|*args|
          unless args.empty?
            ige = args[0]
            @data["#{val}@#{ige}"]
          else
            $stderr.puts "key:#{key} ==> val: #{val.inspect}" if defined?(IRB)
            @data.keys.select{|k| k[0...12] == val}.map{|x| x[13..-1]}
          end
        }
      end
      def keys
        @data.keys
      end
    end
  end
end


