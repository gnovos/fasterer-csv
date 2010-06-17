require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FastererCSV" do

  describe "fiddly bits" do
    describe "Table" do
      it "works" do

      end
    end

    describe "Row" do
      it "works" do

      end
    end
  end

  describe "Converters" do
    describe "NumericConverters" do
      it "works" do

        conv = FastererCSV::NumericConversion.new
        conv << ?1
        conv.convert(true).class.should == String
        conv.convert(true).should == "1"

        conv.convert(false).class.should == Fixnum
        conv.convert(false).should == 1

        conv.clear
        conv << ?-
        conv << ?1
        conv.convert(false).class.should == Fixnum
        conv.convert(false).should == -1

        conv.clear
        conv << ?1
        conv << ?.
        conv << ?1
        conv.convert(false).class.should == Float
        conv.convert(false).should == 1.1

        conv.clear
        conv << ?-
        conv << ?1
        conv << ?.
        conv << ?1
        conv.convert(false).class.should == Float
        conv.convert(false).should == -1.1

        conv.clear
        conv << ?1
        conv << ?.
        conv << ?1
        conv << ?.
        conv << ?1
        conv.convert(false).class.should == String
        conv.convert(false).should == "1.1.1"

        conv.clear
        conv << ?a
        conv.convert(false).class.should == String
        conv.convert(false).should == "a"

        conv.clear
        conv.should be_empty
        conv.convert(false).should be_nil
        conv.convert(true).should == ""

      end
    end
    describe "NoConverter" do
      it "works" do

        conv = FastererCSV::NoConversion.new
        conv << ?1
        conv.convert(true).class.should == String
        conv.convert(false).class.should == String

        conv.convert(true).should == "1"
        conv.convert(false).should == "1"

        conv.clear
        conv.should be_empty
        conv.convert(false).should be_nil
        conv.convert(true).should == ""

      end
    end
  end

  describe "important stuff" do

    before do
      @data = <<-CSV
a,b,c,d,e,f,g,h,i,j,k,l,m,n
,,1,1.1,-1,-1.1,1.1.1,~1~,a,~a~,~a~~a~,~a
~~a~,~,~,

0,1,2,3,4,5,6,7,8,9,10,11,12,14
      CSV
    end

    describe "parse" do
      it "works" do
        table = FastererCSV.parse(@data)
        table.headers.should == [:a, :b, :c,:d,:e,:f,:g,:h,:i,:j,:k,:l,:m,:n]
        table.lines.should == 2

        table[0].should == [nil, nil, "1", "1.1", "-1", "-1.1", "1.1.1", "1", "a", "a", "a~a", "a\n~a", ",", nil]
        table[1].should == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "14"]

      end
    end

    describe "read" do
      it "" do

      end
    end

    describe "read_converted" do
      it "" do

      end
    end

    describe "headers" do
      it "" do

      end
    end

    describe "parse_headers" do
      it "" do

      end
    end

    describe "quot_row" do
      it "" do

      end
    end

    describe "generate" do
      it "" do

      end
    end

    describe "write" do
      it "" do

      end
    end

  end

end
