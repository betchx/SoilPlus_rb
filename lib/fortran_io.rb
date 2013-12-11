#! /usr/bin/ruby 
# encoding: utf-8
# 
#Fortran Unformatted のファイルからデータを取り込む．
#
#Unformattedなので，レコードサイズしか情報は保存されていないが，
#レコードという1つの塊でデータの入出力がなされているので，
#これを基準として入出力を実施する．

class FortranUnformattedFile
  # ファイル名を与えて作成
  #
  # 引数はそのままopen関数に渡される．
  def initialize(filename, mode="rb")
    @filename = filename
    unless mode =~ /b/
      mode += "b"   # binary mode 必須
    end
    @io = File.open(@filename,mode)
    @writable = mode =~ /w/
    @readable = mode =~ /r/
  end
  attr_reader :filename
  def mode() @io.mode end


  # レコードサイズを読み取る
  #
  # 4Byteの整数を読み込んでいるだけ
  def record_size
    v = @io.read(4)
    puts "v is nil" if v.nil?
    if v
      v.unpack("V")[0]  # V: リトルエンディアンの long
    else
      nil
    end
  end
  private :record_size
  # 現在のレコードの内容
  #
  # 生データ
  attr_reader :record
  # 次のレコードを読み込んで返す
  def next_record
    raise "Mode error" unless @readable
    # データの読み込み
    size = record_size or return nil
    @record = @io.read(size)
    check_size = record_size
    # データの整合性チェック
    unless check_size == size
      raise "Data file may be collapsed. #{size} is expected but #{check_size}"
    end
    # 結果を返す
    return record
  end
  # レコードのサイズを書きこむユーティリティルーチン
  def write_size
    @io.write( [@record.size].pack("V") )
  end
  private :write_size
  # 引数の文字列をレコードとして書き込む．
  # 書き込んだ文字列は FortranFile#record で確認できる．
  def write_record(dat)
    raise "Mode Error" unless @writable
    #raise ArgumentError, "dat must be String" unless String === dat
    @record = dat.to_s
    write_size
    @io.write @record
    write_size
    nil
  end
  # フォーマットを指定してレコードを読み取る
  def get(fmt)
    next_record.unpack(fmt)
  end
  # 整数の配列を読み込む
  def get_int_arr
    get("V*") #V: little endian long
  end
  def get_real_arr
    get "e*"  # e: little endian float
  end
  # フォーマットを指定して単一のレコードとして書き込む
  # 文字列の場合はwrite_recordのほうが楽で速い．
  def put(fmt, *dat)
    write_record dat.pack(fmt)
  end
  # 整数の配列を単一のレコードとして書き込む
  def put_int_arr(arr)
    put("V*",*arr)
  end
  # FortranのRealの配列としてデータを書き込む
  def put_real_arr(arr)
    put("e*",*arr)
  end
  # FortranのReal*8の配列としてデータを書き込む
  def put_real8_arr(arr)
    put("E*",*arr) # E: little endian double
  end
  # FortranのDouble Precition(=real*8)の配列としてデータを書き込む
  alias :put_double_arr :put_real8_arr

  # ファイルの終端に到達しているかどうか
  def eof?
    @io.eof?
  end

  def close
    @io.close unless @io.closed?
  end

  # Recordを読み飛ばす
  #
  # selfを返す
  def skip(n=1)
    n.times do
      next_record
    end
    self
  end


  # 現在のファイルポインタの位置を返す
  def pos
    @io.pos
    return  @io.pos
  end
end


if $0 == __FILE__
  require 'test/unit'

  class FRTest < Test::Unit::TestCase

    def setup
      @fname = ".fio-test.bin"
      @fio = nil
      @f = nil
    end
    def teardown
      File.delete @fname if File.exist? @fname
      @fio.close if @fio
      @f.close if @f
    end

    def test_write_int
      @fio = FortranUnformattedFile.new(@fname,"w")
      @fio.put "I", 10
      @fio.close

      @f = open(@fname)

      assert_equal("\x04\x00\x00\x00\x0a\x00\x00\x00\x04\x00\x00\x00",@f.read)
    end

    def test_write_int_arr
      @fio = FortranUnformattedFile.new(@fname,"w")
      @fio.put_int_arr [5, 10]
      @fio.close

      @f = open(@fname)

      assert_equal("\x08\x00\x00\x00\x05\x00\x00\x00\x0a\x00\x00\x00\x08\x00\x00\x00",@f.read)
    end
    def test_write_real_arr
      @fio = FortranUnformattedFile.new(@fname,"w")
      arr = [1.04, 3.5]
      @fio.put_real_arr arr
      @fio.close

      assert_equal(8,arr.pack("ff").size)

      @f=open(@fname)
      r = [8,1.04, 3.5,8].pack("iffi")
      assert_equal(r, @f.read)
    end

    def test_write_read
      @fio = FortranUnformattedFile.new(@fname,"w")
      v =342
      @fio.put "I",v
      @fio.close
      @fio = FortranUnformattedFile.new(@fname)
      r = @fio.get_int_arr[0]
      assert_equal(v,r)
    end

    def test_write_read_text
      @fio = FortranUnformattedFile.new(@fname,"w")
      v = "hogehogeWrite"
      assert_nil(@fio.write_record(v) )
      assert_equal(v, @fio.record)
      @fio.close
      assert_equal(v, @fio.record)
      @fio = FortranUnformattedFile.new(@fname)
      assert_nil(@fio.record)
      r = @fio.next_record
      assert_equal(v,r)
    end
  end
end
