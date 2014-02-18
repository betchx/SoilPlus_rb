#! /usr/bin/ruby
# coding: SHIFT_JIS

require 'fortran_io'

HEADER = "a4i3d"
RECORD = "iia4i4d*"

need_pause = false

name = {
'STRE' => "�e�X�e�b�v�̉��́E�f�ʗ͂̔F���i�v�f�͊e�X�e�b�v���́j",
'FORC' => "�v�f�̊e�X�e�b�v�f�ʗ͂̔F��",
'STRN' => "�e�X�e�b�v�̂Ђ��݂̔F��",
'EFCT' => "�e�X�e�b�v�̗L�����͂̔F��",
'EVNT' => "����`��Ԃ̔F��"
}


ARGV.each do |file|
  unless file =~ /\.f57$/
    $stderr.puts "f57�t�@�C���ł͂���܂���F #{file}"
    need_pause = true
    next
  end

  f = FortranUnformattedFile.new(file)

  out = open(file+".csv","wb")

  until f.eof?
    idnt, nelem, istep =  f.get(HEADER)
    out.puts "type, #{idnt}, #{name[idnt]}"
    out.puts "�v�f��, #{nelem}"
    out.puts "�X�e�b�v, #{istep}"
    out.print %w(�v�f�ԍ� �v�f�^�C�v�ԍ� �v�f�^�C�v �ޗ��ԍ� �����ԍ� ���͐����� �_�~�[).join(',')
    12.times{ |i| out.print ",����#{i+1}"}
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

