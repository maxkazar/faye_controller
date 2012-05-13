require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'FayeController' do
  let(:faye) { double(:faye).as_null_object }

  before :all do
    class Test1Controller < Faye::Controller
      def index; end
      def create
       respond '/channel1', :index
      end
    end

    class Test2Controller < Faye::Controller
      channel '/channel1'
    end

    @controllers = Faye::Controller.controllers
  end

  after :each do
    Faye::Controller.stub(:controllers).and_return @controllers.dup
    Faye::Controller.init faye
  end

  it 'should initialize all controllers' do
    Test1Controller.should_receive(:new)
    Test2Controller.should_receive(:new)
  end

  it 'should subscribe to channel like class name when initialize' do
    faye.should_receive(:subscribe).with('/test1')
  end

  it 'should allow change default channel name like class name' do
    faye.should_receive(:subscribe).with('/channel1')
  end

  it 'should call method with name like action' do
    Test1Controller.any_instance.should_receive :index
    faye.stub(:subscribe) { |channel, &callback| callback.call({:action => :index}) if channel == '/test1' }
  end

  it 'should respond to action call' do
    faye.should_receive(:publish).with('/channel1', anything)
    faye.stub(:subscribe) { |channel, &callback| callback.call({:action => :create}) if channel == '/test1' }
  end
end
