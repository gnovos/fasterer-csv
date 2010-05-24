# Say hi to Rex for me!

require 'rubygems'
require 'stringio'

module FastererCSV

  class Table < Array

    class << self
      def format_headers(unformatted)
        unformatted.map { |header| Row.to_key(header) }
      end
    end

    attr_reader :headers, :lines


    def initialize(headers, fail_on_malformed_columns = true)
      @headers = Table.format_headers(headers)
      @fail_on_malformed_columns = fail_on_malformed_columns
      @lines = 0
    end

    def <<(row)
      @lines += 1
      if row.class != Row
        row = Row.new(self, row, @lines)
      end
      if @headers.length != row.length
        error = "*** WARNING - COLUMN COUNT MISMATCH - WARNING ***\n*** ROW #{size} : EXPECTED #{@headers.length} : FOUND #{row.length}\n\n"
        len = 0
        headers.each do |header|
          len = header.to_s.length if header.to_s.length > len
        end
        headers.each_with_index do |header, i|
           error << sprintf("%-32s : %s\n", header, row[i])
        end
        puts error
        raise error if @fail_on_malformed_columns
      end
      super(row)
    end

  end

  class Row < Array

    class << self
      def to_key(key)
        key = "#{key}".downcase.gsub(/\s+/, '_')
        key.empty? ? :_ : key.to_sym
      end
    end

    def headers
      @table.headers
    end

    attr_reader :line

    def initialize(table, array, line=-1)
      @table = table
      @line = line
      super(array)
    end

    def [](*is)
      is.each do |i|
        val = if i.class == Fixnum
          super
        else
          found = headers.index(Row::to_key(i))
          found ? super(found) : nil
        end
        return val unless val.nil?
      end
      nil
    end

    def []=(key, val)
      if key.class == Fixnum
        super
      else
        key = Row::to_key(key)
        headers << key unless headers.include? key
        found = headers.index(key)
        super(found, val)
      end
    end

    def in_order(columns)
      columns.map do |column_name|
        self[column_name].nil? ? '\N' : self[column_name]
      end
    end

    def merge(hsh)
      hsh.each do |key, value|
        self[key] = value
      end
      self
    end

    def to_hash
      headers.inject({}) do |memo, h|
        memo[h] = self[h]
        memo
      end
    end
  end

  class << self

    def headers(file, quot = '~', sep = ',', &block)
      parse_headers(File.open(file, 'r') {|io| io.gets }, quot, sep, &block)
    end

    def read(file, quot = '~', sep = ',', &block)
      parse(File.open(file, 'r') { |io| io.sysread(File.size(file)) }, quot, sep, &block)
    end

    def parse_headers(data, quot = '~', sep = ',', &block)
      parse(data, quot, sep, &block).headers
    end

    def parse(data, quot = '~', sep = ',')
      q, s, row, column, inquot, clean, maybe, table, field, endline = quot[0], sep[0], [], [], false, true, false, nil, true, false

      data.each_byte do |c|
        next if c == ?\r

        if maybe && c == s
          row << column.join
          column.clear
          clean, inquot, maybe, field, endline = true, false, false, true, false
        elsif maybe && c == ?\n && table.nil?
          row << column.join unless (column.empty? && endline)
          column.clear
          table = Table.new(row) unless row.empty?
          row, clean, inquot, maybe, field, endline = [], true, false, false, false, true
        elsif maybe && c == ?\n
          row << column.join unless (column.empty? && endline)
          column.clear
          table << row unless row.empty?
          row, clean, inquot, maybe, field, endline = [], true, false, false, false, true
        elsif clean && c == q
          inquot, clean, endline = true, false, false
        elsif maybe && c == q
          column << c.chr
          clean, maybe, endline = false, false, false
        elsif c == q
          maybe, endline = true, false
        elsif inquot
          column << c.chr
          clean, endline = false, false
        elsif c == s
          row << (column.empty? ? nil : column.join)
          column.clear
          clean, field, endline = true, true, false
        elsif c == ?\n && table.nil?

          if column.empty? && !endline
            row << nil
          elsif !column.empty?
            row << column.join
          end

          column.clear
          table = Table.new(row) unless row.empty?
          row, clean, inquot, field, endline = [], true, false, false, true
        elsif c == ?\n

          if column.empty? && !endline
            row << nil
          elsif !column.empty?
            row << column.join
          end

          column.clear
          table << row unless row.empty?
          row, clean, inquot, field, endline = [], true, false, false, true
        else
          column << c.chr
          clean, endline = false, false
        end
      end

      if !clean
        if maybe
          row << column.join
        else
          row << (column.empty? ? nil :column.join)
        end
        if table
          table << row unless row.empty?
        else
          table = Table.new(row) unless row.empty?
        end
      elsif field
        row << (column.empty? ? nil : column.join)
      end

      table.each do |line|
        yield(line)
      end if table && block_given?

      table
    end

    def quot_row(row, q = '~', s = ',')
      row.map do |val|
        if val.nil?
          ""
        else
          val = String(val)
          if val.length == 0
            q * 2
          else
            val[/[#{q}#{s}\n]/] ? q + val.gsub(q, q * 2) + q : val
          end
        end
      end.join(s) + "\n"
    end

    class IOWriter
      def initialize(file, quot = '~', sep = ',') @io = file; @quot = quot; @sep = sep end
      def <<(row)
        raise "can only write arrays! #{row.class} #{row.inspect}" unless row.class == Array || row.class == Row
        @io.syswrite FastererCSV::quot_row(row, @quot, @sep);
        row
      end
    end

    def generate(quot = '~', sep = ',', &block)
      builder = StringIO.new
      write(builder, quot, sep, &block)
      builder.string
    end

    def write(out, quot = '~', sep = ',', &block)
      if out.class == String
        File.open(out, "w") do |io|
          write(io, quot, sep, &block)
        end
      else
        yield(IOWriter.new(out, quot, sep))
      end
    end
  end
end
