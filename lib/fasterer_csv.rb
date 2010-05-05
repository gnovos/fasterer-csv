require 'rubygems'
require 'stringio'

module FastererCSV

  class Table < Array

    class << self
      def format_headers(unformatted)
        unformatted.map { |header| Row.to_key(header) }
      end
    end

    attr_reader :headers

    def initialize(headers, fail_on_malformed_columns = true)
      @headers = Table.format_headers(headers)
      @fail_on_malformed_columns = fail_on_malformed_columns
    end

    def <<(row)
      if row.class != Row
        row = Row.new(self, row)
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

    def initialize(table, array)
      @table = table
      super(array)
    end

    def [](i)
      if i.class == Fixnum
        super
      else
        found = headers.index(Row::to_key(i))
        found ? super(found) : nil
      end
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
      q, s, row, column, inquot, clean, maybe, table, field = quot[0], sep[0], [], [], false, true, false, nil, true

      data.each_byte do |c|
        next if c == ?\r

        if maybe && c == s
          row << column.join
          column.clear
          clean, inquot, maybe, field = true, false, false, true
        elsif maybe && c == ?\n && table.nil?
          row << column.join
          column.clear
          table = Table.new(row)
          row, clean, inquot, maybe, field = [], true, false, false, false
        elsif maybe && c == ?\n
          row << column.join
          column.clear
          table << row
          row, clean, inquot, maybe, field = [], true, false, false, false
        elsif clean && c == q
          inquot, clean = true, false
        elsif maybe && c == q
          column << c.chr
          clean, maybe = false, false
        elsif c == q
          maybe = true
        elsif inquot
          column << c.chr
          clean = false
        elsif c == s
          row << (column.empty? ? nil : column.join)
          column.clear
          clean, field = true, true
        elsif c == ?\n && table.nil?
          row << (column.empty? ? nil : column.join)
          column.clear
          table = Table.new(row)
          row, clean, inquot, field = [], true, false, false
        elsif c == ?\n
          row << (column.empty? ? nil : column.join)
          column.clear
          table << row
          row, clean, inquot, field = [], true, false, false
        else
          column << c.chr
          clean = false
        end
      end

      if !clean
        if maybe
          row << column.join
        else
          row << (column.empty? ? nil :column.join)
        end
        table << row
      elsif field
        row << (column.empty? ? nil : column.join)        
      end

      table.each do |line|
        yield(line)
      end if block_given?

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
