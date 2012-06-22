require 'spec_helper'

describe Muster::Strategies::ActiveRecord do
  let(:options) { {} }
  subject { Muster::Strategies::ActiveRecord.new(options) }

  describe '#parse' do
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

    context 'wheres' do
      it 'returns a single value as a string in a hash' do
        subject.parse('where=id:1')[:where].should == {'id' => '1'}
      end

      it 'returns values as an Array in a hash' do
        subject.parse('where=id:1&where=id:2')[:where].should == {'id' => ['1', '2']}
      end

      it 'supports pipe for multiple values' do
        subject.parse('where=id:1|2')[:where].should == {'id' => ['1', '2']}
      end
    end

    context 'the full monty' do
      it 'returns a hash of all options' do
        query_string = 'select=id,guid,name&where=name:foop&order=id:desc&order=name'
        results = subject.parse(query_string)

        results[:select].should == ['id', 'guid', 'name']
        results[:where].should  == {'name' => 'foop'}
        results[:order].should  == ['id desc', 'name asc']
      end

      it 'supports indifferent access' do
        query_string = 'select=id,guid,name&where=name:foop&order=id:desc&order=name'
        results = subject.parse(query_string)

        results['select'].should == ['id', 'guid', 'name']
        results['where'].should  == {'name' => 'foop'}
        results['order'].should  == ['id desc', 'name asc']
      end
    end
  end
end