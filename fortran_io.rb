#! /usr/bin/ruby 
#
#Fortran Unformatted �̃t�@�C������f�[�^����荞�ށD
#
#Unformatted�Ȃ̂ŁC���R�[�h�T�C�Y�������͕ۑ�����Ă��Ȃ����C
#���R�[�h�Ƃ���1�̉�Ńf�[�^�̓��o�͂��Ȃ���Ă���̂ŁC
#�������Ƃ��ē��o�͂����{����D

class FortranUnformattedFile
  # �t�@�C������^���č쐬
  #
  # �����͂��̂܂�open�֐��ɓn�����D
  def initialize(filename, mode="rb")
    @filename = filename
    unless mode =~ /b/
      mode += "b"   # binary mode �K�{
    end
    @io = File.open(@filename,mode)
    @writable = mode =~ /w/
    @readable = mode =~ /r/
  end
  attr_reader :filename
  def mode() @io.mode end


  # ���R�[�h�T�C�Y��ǂݎ��
  #
  # 4Byte�̐�����ǂݍ���ł��邾��
  def record_size
    @io.read(4).unpack("V")[0]  # V: ���g���G���f�B�A���� long
  end
  private :record_size
  # ���݂̃��R�[�h�̓��e
  #
  # ���f�[�^
  attr_reader :record
  # ���̃��R�[�h��ǂݍ���ŕԂ�
  def next_record
    raise "Mode error" unless @readable
    # �f�[�^�̓ǂݍ���
    size = record_size
    @record = @io.read(size)
    check_size = record_size
    # �f�[�^�̐������`�F�b�N
    unless check_size == size
      raise "Data file may be collapsed. #{size} is expected but #{check_size}"
    end
    # ���ʂ�Ԃ�
    return record
  end
  # ���R�[�h�̃T�C�Y���������ރ��[�e�B���e�B���[�`��
  def write_size
    @io.write( [@record.size].pack("V") )
  end
  private :write_size
  # �����̕���������R�[�h�Ƃ��ď������ށD
  # �������񂾕������ FortranFile#record �Ŋm�F�ł���D
  def write_record(dat)
    raise "Mode Error" unless @writable
    #raise ArgumentError, "dat must be String" unless String === dat
    @record = dat.to_s
    write_size
    @io.write @record
    write_size
    nil
  end
  # �t�H�[�}�b�g���w�肵�ă��R�[�h��ǂݎ��
  def get(fmt)
    next_record.unpack(fmt)
  end
  # �����̔z���ǂݍ���
  def get_int_arr
    get("V*") #V: little endian long
  end
  def get_real_arr
    get "e*"  # e: little endian float
  end
  # �t�H�[�}�b�g���w�肵�ĒP��̃��R�[�h�Ƃ��ď�������
  # ������̏ꍇ��write_record�̂ق����y�ő����D
  def put(fmt, *dat)
    write_record dat.pack(fmt)
  end
  # �����̔z���P��̃��R�[�h�Ƃ��ď�������
  def put_int_arr(arr)
    put("V*",*arr)
  end
  # Fortran��Real�̔z��Ƃ��ăf�[�^����������
  def put_real_arr(arr)
    put("e*",*arr)
  end
  # Fortran��Real*8�̔z��Ƃ��ăf�[�^����������
  def put_real8_arr(arr)
    put("E*",*arr) # E: little endian double
  end
  # Fortran��Double Precition(=real*8)�̔z��Ƃ��ăf�[�^����������
  alias :put_double_arr :put_real8_arr

  # �t�@�C���̏I�[�ɓ��B���Ă��邩�ǂ���
  def eof?
    @io.eof?
  end

  def close
    @io.close unless @io.closed?
  end

  # Record��ǂݔ�΂�
  #
  # self��Ԃ�
  def skip(n=1)
    n.times do
      next_record
    end
    self
  end


  # ���݂̃t�@�C���|�C���^�̈ʒu��Ԃ�
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
