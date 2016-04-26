require_relative '../spec_helper'

describe Octo::Stats do

    describe '#instrument' do
     let(:dummy_class) { Class.new { extend Octo::Stats } }

      it 'yields the given block' do
        block = Proc.new { puts 'hello world' }
        name = :hello_world

        expect(dummy_class).to receive(:instrument).
            with(name, &block).
            and_yield(&block)

        dummy_class.instrument(name, &block)
      end
    end

end