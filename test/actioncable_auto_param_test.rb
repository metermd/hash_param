require 'test_helper'

class ActioncableAutoParamTest < Minitest::Test
  class MockChannel
    extend ActioncableAutoParam::ClassMethods
    prepend ActioncableAutoParam

    attr_accessor :log

    def initialize
      @log = []
    end

    def clear!
      @log = []
    end

    def normal_data_method(data)
      @log.push [__method__, data]
    end

    auto_param \
    def f_one_required_arg(a)
      @log.push [__method__, a]
    end

    auto_param \
    def f_opt_arg(a = nil)
      @log.push [__method__, a]
    end

    auto_param \
    def f_rest_middle(a, *b, c)
      @log.push [__method__, a, b, c]
    end

    auto_param \
    def f_kwrest(a, **b)
      @log.push [__method__, a, b]
    end

    auto_param \
    def f_rest_kwrest(a, *b, **c)
      @log.push [__method__, a, b, c]
    end
  end

  def setup
    @m = MockChannel.new
  end

  def test_mock_channel_can_instantiate
    refute_nil @m
  end

  def test_doesnt_interfere_by_default
    @m.normal_data_method({a: 1, b: 2})
    assert_equal([:normal_data_method, {a: 1, b: 2}], @m.log.last)
  end

  def test_one_required_arg
    @m.dispatch_action 'f_one_required_arg', {'a' => 1}
    assert_equal [:f_one_required_arg, 1], @m.log.last

    @m.dispatch_action 'f_one_required_arg', {'a' => 2, 'b' => 3}
    assert_equal [:f_one_required_arg, 2], @m.log.last

    assert_raises ArgumentError do
      @m.dispatch_action 'f_one_required_arg', {}
    end

    assert_raises ArgumentError do
      @m.dispatch_action 'f_one_required_arg', {'b' => 3}
    end
  end

  def test_opt_arg
    @m.dispatch_action 'f_opt_arg', {'a' => 1}
    assert_equal [:f_opt_arg, 1], @m.log.last

    @m.clear!
    @m.dispatch_action 'f_opt_arg', {}
    assert_equal [:f_opt_arg, nil], @m.log.last

    @m.clear!
    @m.dispatch_action 'f_opt_arg', {'b' => 1}
    assert_equal [:f_opt_arg, nil], @m.log.last
  end

  def test_rest_middle
    # Remember: *args get a hash with STRING keys.
    @m.dispatch_action 'f_rest_middle', {'a' => 1, 'c' => 2, 'd' => 3}
    assert_equal [:f_rest_middle, 1, [{'d' => 3}], 2], @m.log.last

    @m.dispatch_action 'f_rest_middle', {'a' => 1, 'c' => 2}
    assert_equal [:f_rest_middle, 1, [], 2], @m.log.last

    @m.dispatch_action 'f_rest_middle', {'a' => 1, 'b' => 2, 'c' => 3}
    assert_equal [:f_rest_middle, 1, [{'b' => 2}], 3], @m.log.last
  end

  def test_kwrest
    @m.dispatch_action 'f_kwrest', {'a' => 1, 'b' => 2, 'c' => 3}
    assert_equal [:f_kwrest, 1, {b: 2, c: 3}], @m.log.last
  end

  def test_rest_kwrest
    @m.dispatch_action 'f_rest_kwrest', {'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4}
    # Notice, the rest argument name is 'b', but that shouldn't have an effect
    # on it ending up in the kwrest argument, c
    assert_equal [:f_rest_kwrest, 1, [], {b: 2, c: 3, d: 4}], @m.log.last
  end
end
