#! /usr/bin/ruby
# encoding: utf-8
# SoilPlusの解析結果FT22 (*.f22) （応力ひずみ関係）のデータを読み込むクラス
#

require 'fortran_io'
require 'narray'

module SoilPlus
  module Results
    class SSCurve
      XTITLES = [ "Filler",
                  "Axial Strain",    #1
                  "Rotation",        #2
                  "Shear Strain",    #3
                  "Bending Strain",  #4
                  "Torsion",         #5
                  "Shear Strain",    #6
                  "Effective Stress",#7
                  "Displacement"]    #8
      YTITLES = [ "Filler",
                  "Axial Force",     #1
                  "Moment",          #2
                  "Shear Force",     #3
                  "Bending Moment",  #4
                  "Torque",          #5
                  "Shear Stress",    #6
                  "Shear Stress",    #7
                  "Force"]           #8
      COMPONENTS = %w(Filler X Y Z RX RY RZ)
      def initialize(line,nstp)
        @nstp = nstp
        arr = line.unpack("VVVVa*")
        @iel = arr.shift
        @icmp = arr.shift
        @ktyp = arr.shift
        @jtyp = arr.shift
        @data = NArray.to_na(arr.shift, NArray::DFLOAT, 2,@nstp)
        @disp = @data[0,true]
        @force = @data[1,true]
        @length = @disp.size
        @x_title = XTITLES[@jtyp]
        @y_title = YTITLES[@jtyp]
      end
      attr_reader :iel, :icmp, :ktyp, :jtyp, :disp, :force, :length
      attr_reader :x_title, :y_title
      def component
        COMPONENTS[@icmp]
      end
      def each
        @length.times{|i| yield self[i]}
      end
      extend Enumerable
      def [](i)
        return @disp[i],@force[i]
      end
    end
    class SSCurves
      NAME = "FT22"
      EXT = ".f22"

      def initialize(basename = nil)
        @io = nil
        @data = {}
        open(basename) if basename
      end

      def open(basename)
        @filename = basename + EXT
        @filename.sub!(EXT+EXT,EXT)
        @io = FortranUnformattedFile.new(@filename)
        line = @io.next_record
        arr = line.unpack("VVVVEEEVa40a40")
        @jobn = arr.shift
        @idnt = arr.shift
        @lfd = arr.shift
        @nstp = arr.shift
        @dt = arr.shift
        @tmax = arr.shift
        @galo = arr.shift
        @nmsc = arr.shift
        @itle = arr.shift
        @itld = arr.shift
        @time = @io.next_record.unpack("E*")

        @data = []
        while line = @io.next_record
          @data << SSCurve.new(line, @nstp)
        end
      end
      attr_reader :dt, :nstp, :jobn, :idnt, :lfd, :tmax, :galo, :nmsc
      attr_reader :itle, :itld, :time

      def size
        return [@nmsc, @nstp]
      end

      def length
        @time.length
      end

      alias :num_curves :nmsc
      alias :analysis_title :itle
      alias :load_title :itld

      def [](i)
        @data[i]
      end

      def each
        @data.each{|v| yield v}
      end
      extend Enumerable
    end
  end
end


