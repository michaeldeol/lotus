require 'test_helper'

describe Lotus::Loader do
  before do
    @application = CoffeeShop::Application.new
  end

  describe '.load!' do
    before do
      Reviews::Application.load!
    end

    # Bug: https://github.com/lotus/lotus/issues/187
    it 'generates per application routes' do
      assert defined?(Reviews::Routes), 'expected Reviews::Routes'
    end
  end

  describe '#load!' do
    describe 'frameworks' do
      it 'generates per application frameworks' do
        assert defined?(CoffeeShop::Controller), 'expected CoffeeShop::Controller'
        assert defined?(CoffeeShop::Action),     'expected CoffeeShop::Action'
        assert defined?(CoffeeShop::View),       'expected CoffeeShop::View'
        assert defined?(CoffeeShop::Model),      'expected CoffeeShop::Model'
        assert defined?(CoffeeShop::Entity),     'expected CoffeeShop::Entity'
        assert defined?(CoffeeShop::Repository), 'expected CoffeeShop::Repository'
        assert defined?(CoffeeShop::Presenter),  'expected CoffeeShop::Presenter'
        assert defined?(CoffeeShop::Logger),     'expected CoffeeShop::Logger'
      end

      it 'generates per application routes' do
        assert defined?(CoffeeShop::Routes), 'expected CoffeeShop::Routes'
      end

      it 'configures controller to use custom action module' do
        CoffeeShop::Controller.configuration.action_module.must_equal(CoffeeShop::Action)
      end

      it 'configures controller to use default request format' do
        CoffeeShop::Controller.configuration.default_request_format.must_equal(:html)
      end

      it 'configures controller to use default response format' do
        CoffeeShop::Controller.configuration.default_response_format.must_equal(:html)
      end

      it 'generates controllers namespace' do
        assert defined?(CoffeeShop::Controllers), 'expected CoffeeShop::Controllers'
      end

      it 'generates views namespace' do
        assert defined?(CoffeeShop::Views), 'expected CoffeeShop::Views'
      end

      it 'assigns root to CoffeeShop::View' do
        CoffeeShop::View.configuration.root.must_equal @application.configuration.root.join('app/templates')
      end

      it 'assigns layout to CoffeeShop::View' do
        CoffeeShop::View.configuration.layout.must_equal Lotus::View::Rendering::NullLayout
      end
    end

    describe 'application' do
      describe 'routing' do
        it 'assigns routes' do
          expected = Lotus::Router.new(&@application.configuration.routes)
          @application.routes.path(:root).must_equal expected.path(:root)
        end

        it 'assigns custom endpoint resolver' do
          resolver = @application.routes.instance_variable_get(:@router).instance_variable_get(:@resolver)
          resolver.instance_variable_get(:@namespace).must_equal CoffeeShop
        end

        it 'assigns custom default app' do
          default_app = @application.routes.instance_variable_get(:@router).instance_variable_get(:@default_app)
          default_app.must_be_kind_of(Lotus::Routing::Default)
        end

        it 'assigns scheme, host and port configuration' do
          routes = @application.routes
          routes.url(:root).must_equal 'https://lotus-coffeeshop.org:2300/'
        end
      end

      describe 'middleware' do
        it 'preloads the middleware' do
          @application.middleware.must_be_kind_of(Lotus::Middleware)
        end
      end

      describe 'logger' do

        describe 'when not configured' do
          before do
            @output = stub_stdout_constant do
              module BeerShop
                class Application < Lotus::Application; load!; end
              end
            end
          end
          after do
            Object.__send__(:remove_const, :BeerShop)
          end

          it 'load a default logger' do
            BeerShop::Logger.must_be_instance_of Lotus::Logger
          end
          it 'has app module name along with log output' do
            BeerShop::Logger.info 'foo'
            @output.must_match(/BeerShop/)
          end
        end

        describe 'when explicitly configured' do
          before do
            class MyLogger < Logger; end
            module DrinkShop
              class Application < Lotus::Application
                configure { logger MyLogger.new(STDOUT) }
                load!
              end
            end
          end
          after do
            Object.__send__(:remove_const, :MyLogger)
            Object.__send__(:remove_const, :DrinkShop)
          end

          it 'load the configured logger' do
            DrinkShop::Logger.must_be_instance_of MyLogger
          end
        end
      end
    end

    describe 'initializers' do

      it 'loads all the initializers' do
        assert_equal defined?(CollaborationInitializer1), 'constant'
        assert_equal defined?(CollaborationInitializer2), 'constant'
      end

    end

    # describe 'finalization' do
    #   it 'freeze CoffeeShop::View' do
    #     CoffeeShop::View.configuration.root.must_be :frozen?
    #   end
    # end
  end
end
