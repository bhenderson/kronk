require 'test/test_helper'
require 'lib/kronk/test/core_ext'

class TestCoreExt < Test::Unit::TestCase

  def setup
    @array = [:a, :b, {:foo => "bar", :bar => [:a, :b, {:foo => "other"}]}, :c]
    @hash  = {:foo => "bar", :bar => [:a, :b, {:foo => "other"}], :a => [1,2,3]}
  end


  def test_has_path_array
    assert_equal [2, :foo], @array.has_path?("**/foo")
    assert_equal [2, :bar, 2, :foo], @array.has_path?("**/foo=other")
    assert_nil @array.has_path?("**/foobar")
  end


  def test_has_path_hash
    assert_equal [:foo], @hash.has_path?("**/foo")
    assert_equal [:bar, 2, :foo], @hash.has_path?("**/foo=other")
    assert_nil @hash.has_path?("**/foobar")
  end


  def test_find_data_array
    out = @array.find_data "**/foo"
    assert_equal({[2, :foo] => "bar", [2, :bar, 2, :foo] => "other"}, out)
  end


  def test_find_data_array_empty
    out = @array.find_data "**/foobar"
    assert_equal({}, out)
  end


  def test_find_data_array_block
    collected = []

    @array.find_data "**/foo" do |data, key, path|
      collected << [data, key, path]
    end

    assert_equal([@array[2], :foo, [2, :foo]], collected[0])
    assert_equal([@array[2][:bar][2], :foo, [2, :bar, 2, :foo]], collected[1])
  end


  def test_find_data_hash
    out = @hash.find_data "**/foo"
    assert_equal({[:foo] => "bar", [:bar, 2, :foo] => "other"}, out)
  end


  def test_find_data_hash_empty
    out = @hash.find_data "**/foobar"
    assert_equal({}, out)
  end


  def test_find_data_hash_block
    collected = []

    @hash.find_data "**/foo" do |data, key, path|
      collected << [data, key, path]
    end

    assert_equal([@hash, :foo, [:foo]], collected[0])
    assert_equal([@hash[:bar][2], :foo, [:bar, 2, :foo]], collected[1])
  end
end
