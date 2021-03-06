require 'rspec_helper'

RSpec.describe Tainers::Specification do
  it 'requires a name' do
    expect { Tainers::Specification.new 'Image' => 'foo/image:latest' }.to raise_error(/name is required/)
  end

  it 'requires an image' do
    expect { Tainers::Specification.new 'name' => 'something' }.to raise_error(/Image is required/)
  end

  context 'for a container' do
    let(:name) { "something-#{object_id.to_s}-foo" }
    let(:image) { "some.#{object_id.to_s}.repo:5000/some-image/#{object_id.to_s[0..5]}" }
    let(:container_args) { {'Image' => image, double.to_s => double.to_s } }
    let(:specification_args) { container_args.merge('name' => name) }

    subject do
      Tainers::Specification.new specification_args
    end

    context 'that does not exist' do
      it 'indicates non-existence' do
        expect(Docker::Container).to receive(:get).with(name).and_raise(Docker::Error::NotFoundError)
        expect(subject.exists?).to be false
      end

      context '#ensure' do
        before do
          expect(subject).to receive(:exists?).and_return(false)
        end

        it 'uses Docker::Container for creation' do
          expect(Docker::Container).to receive(:create).with(specification_args).and_return(container = double)
          expect(subject.ensure).to be(subject)
        end

        it 'is okay with a conflict result' do
          expect(Docker::Container).to receive(:create).with(specification_args).and_raise(Excon::Errors::Conflict, "Pickles")
          expect(subject.ensure).to be(subject)
        end

        it 'does not handle other exceptions' do
          expect(Docker::Container).to receive(:create).with(specification_args).and_raise(Exception, "You suck.")
          expect { subject.ensure }.to raise_error("You suck.")
        end
      end
    end

    context 'that exists' do
      it 'indicates existence' do
        expect(Docker::Container).to receive(:get).with(name).and_return(double)
        expect(subject.exists?).to be true
      end

      it 'does a no-op for #ensure' do
        expect(subject).to receive(:exists?).and_return(true)
        expect(Docker::Container).to receive(:create).never
        expect(subject.ensure).to be(subject)
      end
    end
  end
end
