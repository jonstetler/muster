require 'spec_helper'

describe Muster::Strategies::ActiveRecord do
  let(:options) { {} }
  subject { Muster::Strategies::ActiveRecord.new(options) }

  describe '#parse' do
    it 'returns a Muster::Results instance' do
      result = {
        'select' => [],
        'order' => [],
        'limit' => 30,
        'offset' => nil,
        'where' => {},
        'joins' => {},
        'includes' => {},
        'pagination' => { :page => 1, :per_page => 30 }
      }
      subject.parse('').should eq(result)
      subject.parse('').should be_an_instance_of(Muster::Results)
    end

    context 'selects' do
      it 'returns single value as Array' do
        subject.parse('select=id')[:select].should == ['id']
      end

      it 'returns values in Array' do
        subject.parse('select=id&select=name')[:select].should == ['id', 'name']
      end

      it 'supports comma separated values' do
        subject.parse('select=id&select=guid,name')[:select].should == ['id', 'guid', 'name']
      end
    end

    context 'orders' do
      it 'returns single value as Array' do
        subject.parse('order=id')[:order].should == ['id asc']
      end

      context 'with direction' do
        it 'supports asc' do
          subject.parse('order=id:asc')[:order].should == ['id asc']
        end

        it 'supports desc' do
          subject.parse('order=id:desc')[:order].should == ['id desc']
        end

        it 'supports ascending' do
          subject.parse('order=id:ascending')[:order].should == ['id asc']
        end

        it 'supports desc' do
          subject.parse('order=id:descending')[:order].should == ['id desc']
        end
      end
    end

    context 'joins' do
      it 'returns single value in Array' do
        subject.parse('joins=author')[:joins].should eq ['author']
      end

      it 'returns multiple values in Array' do
        subject.parse('joins=author,voter')[:joins].should eq ['author', 'voter']
      end

      it 'returns a nested hash of separated values' do
        subject.parse('joins=author.country.name')[:joins].should eq [{ 'author' => { 'country' => 'name' } }]
      end

      it 'returns an array of nested hashes' do
        subject.parse('joins=author.country.name,activity.rule')[:joins].should eq [{ 'author' => { 'country' => 'name' } }, { 'activity' => 'rule' }]
      end
    end

    context 'includes' do
      it 'returns single value in Array' do
        subject.parse('includes=author')[:includes].should eq ['author']
      end

      it 'returns multiple values in Array' do
        subject.parse('includes=author,voter')[:includes].should eq ['author', 'voter']
      end

      it 'returns a nested hash of separated values' do
        subject.parse('includes=author.country.name')[:includes].should eq [{ 'author' => { 'country' => 'name' } }]
      end

      it 'returns an array of nested hashes' do
        results = [{ 'author' => { 'country' => 'name' } }, { 'activity' => 'rule' }]
        subject.parse('includes=author.country.name,activity.rule')[:includes].should eq results
      end
    end

    context 'pagination' do
      it 'returns default will paginate compatible pagination' do
        subject.parse('')[:pagination].should eq(:page => 1, :per_page => 30)
      end

      it 'returns default limit options' do
        subject.parse('')[:limit].should eq 30
      end

      it 'returns default offset options' do
        subject.parse('')[:offset].should eq nil
      end

      it 'accepts per_page option' do
        results = subject.parse('per_page=10')
        results[:pagination].should eq(:page => 1, :per_page => 10)
        results[:limit].should eq 10
        results[:offset].should eq nil
      end

      it 'ensures per_page is positive integer' do
        results = subject.parse('per_page=-10')
        results[:pagination].should eq(:page => 1, :per_page => 30)
        results[:limit].should eq 30
        results[:offset].should eq nil
      end

      it 'accepts page_size option' do
        results = subject.parse('page_size=10')
        results[:pagination].should eq(:page => 1, :per_page => 10)
        results[:limit].should eq 10
        results[:offset].should eq nil
      end

      it 'accepts page option' do
        results = subject.parse('page=2')
        results[:pagination].should eq(:page => 2, :per_page => 30)
        results[:limit].should eq 30
        results[:offset].should eq 30
      end

      it 'ensures page is positive integer' do
        results = subject.parse('page=a')
        results[:pagination].should eq(:page => 1, :per_page => 30)
        results[:limit].should eq 30
        results[:offset].should eq nil
      end
    end

    context 'wheres' do
      it 'returns a single value as a string in a hash' do
        subject.parse('where=id:1')[:where].should eq('id' => '1')
      end

      it 'returns a single value as nil in a hash' do
        subject.parse('where=id:null')[:where].should eq('id' => nil)
        subject.parse('where=id:NULL')[:where].should eq('id' => nil)
        subject.parse('where=id:Null')[:where].should eq('id' => nil)
        subject.parse('where=id:nil')[:where].should eq('id' => nil)
        subject.parse('where=id:NIL')[:where].should eq('id' => nil)
        subject.parse('where=id:Nil')[:where].should eq('id' => nil)
      end

      it 'returns values as an Array in a hash' do
        subject.parse('where=id:1&where=id:2')[:where].should eq('id' => ['1', '2'])
      end

      it 'supports pipe for multiple values' do
        subject.parse('where=id:1|2')[:where].should eq('id' => ['1', '2'])
      end
    end

    context 'the full monty' do
      it 'returns a hash of all options' do
        query_string = 'select=id,guid,name&where=name:foop&order=id:desc&order=name&page=3&page_size=5&includes=author.country,comments&joins=activity' # rubocop:disable Metrics/LineLength
        results = subject.parse(query_string)

        results[:select].should eq ['id', 'guid', 'name']
        results[:where].should eq('name' => 'foop')
        results[:order].should eq ['id desc', 'name asc']
        results[:includes].should eq [{ 'author' => 'country' }, 'comments']
        results[:joins].should eq ['activity']
        results[:pagination].should eq(:page => 3, :per_page => 5)
        results[:offset].should eq 10
        results[:limit].should eq 5
      end

      it 'supports indifferent access' do
        query_string = 'select=id,guid,name&where=name:foop&order=id:desc&order=name&page=3&page_size=5&includes=author.country,comments&joins=activity' # rubocop:disable Metrics/LineLength
        results = subject.parse(query_string)

        results['select'].should eq ['id', 'guid', 'name']
        results['where'].should eq('name' => 'foop')
        results['order'].should eq ['id desc', 'name asc']
        results['includes'].should eq [{ 'author' => 'country' }, 'comments']
        results['joins'].should eq ['activity']
        results['pagination'].should eq(:page => 3, :per_page => 5)
        results['offset'].should eq 10
        results['limit'].should eq 5
      end
    end
  end
end
