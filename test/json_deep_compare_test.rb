require 'test/unit'
$: << 'lib'
require 'json-deep-compare'

class DocumentComparisonTestCase < Test::Unit::TestCase
  def assert_symmetrically_different(
    lval, rval, message_template = nil, sub_pairs = nil
  )
    sub_pairs = [sub_pairs] if sub_pairs and sub_pairs.first.is_a?(String)
    comparison1 = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert(
      !comparison1.equal?, 
      "Comparison of #{lval.inspect} to #{rval.inspect} should not have been equal"
    )
    if message_template
      message1 = message_template
      sub_pairs.each_with_index do |sub_pair, i|
        message1 = message1.
          sub(/:left#{i}/, sub_pair.first).
          sub(/:right#{i}/, sub_pair.last)
      end
      assert_equal(message1, comparison1.difference_messages)
    end
    comparison2 = JsonDeepCompare::DocumentComparison.new(rval, lval)
    assert(
      !comparison2.equal?, 
      "Comparison of #{rval.inspect} to #{lval.inspect} should not have been equal"
    )
    if message_template
      message2 = message_template
      sub_pairs.each_with_index do |sub_pair, i|
        message2 = message2.
          sub(/:left#{i}/, sub_pair.last).
          sub(/:right#{i}/, sub_pair.first)
      end
      assert_equal(message2, comparison2.difference_messages)
    end
  end

  def test_detects_difference_in_atoms
    left_value = {
      'total_rows' => 2,
      'rows' => [
        {
          'id' => 'foo',
          'doc' => {
            '_id' => 'foo',
            'title' => 'Foo',
            'sub_document' => { 'one' => 'two' }
          }
        }
      ]
    }
    right_value = {
      'total_rows' => 2,
      'rows' => [
        {
          'id' => 'foo',
          'doc' => {
            '_id' => 'foo',
            'title' => 'Foo',
            'sub_document' => { 'one' => '1' }
          }
        }
      ]
    }
    assert_symmetrically_different(
      left_value, right_value, 
      "\":root > .rows :nth-child(1) > .doc > .sub_document > .one\" expected to be :left0 but was :right0",
      ["two".inspect, "1".inspect]
    )
  end

  def test_detects_differences_in_keys
    left_value = {"doc" => {"foo" => "bar"}}
    right_value = {"doc" => {"biz" => "bang", "bing" => nil}}
    assert_symmetrically_different(left_value, right_value)
  end

  def test_missing_keys
    lval = {"outer" => {"key1" => "value1"}}
    rval = {"outer" => {"key1" => "value1", "key2" => {"foo" => "bar"}}}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .outer > .key2\" expected to be :left0 but was :right0",
      ["nil", {"foo" => "bar"}.inspect]
    )
  end

  def test_detects_difference_in_type
    lval = {"foo" => {'bar' => 'bang'}}
    rval = {"foo" => [3,4,5]}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .foo\" expected to be :left0 but was :right0",
      [{"bar" => "bang"}.inspect, [3,4,5].inspect]
    )
  end

  def test_detects_difference_in_type_and_truncates
    lval_hash = {}
    'A'.upto('Z').each do |letter|
      lval_hash[letter] = letter
    end
    lval = {"foo" => lval_hash}
    rval = {"foo" => [3,4,5]}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .foo\" expected to be :left0 but was :right0",
      [
        "Hash {\"A\"=>\"A\", \"B\"=>\"B\", \"C\"=>\"C\", \"D\"=>\"D...", 
        [3,4,5].inspect
      ]
    )
  end

  def test_lists_multliple_differences
    lval = {'one' => {'two' => 'three', 'four' => 'five'}, 'six' => 'seven'}
    rval = {'one' => {'two' => 'TWO', 'four' => 'five'}, 'six' => 'SIX'}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .one > .two\" expected to be :left0 but was :right0\n\":root > .six\" expected to be :left1 but was :right1",
      [["three".inspect, "TWO".inspect], ["seven".inspect, "SIX".inspect]]
    )
  end

  def test_detects_difference_between_array_and_nil
    lval = {'one' => [1,2,3]}
    rval = {'one' => nil}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .one\" expected to be :left0 but was :right0",
      [[1,2,3].inspect, 'nil']
    )
  end

  def test_shows_first_string_difference
    lval = {'body' => "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal."}
    rval = {'body' => "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal."}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .body\" differs starting at char 103: :left0 differs from :right0",
      [
        "..., conceived in Liberty, and ded...".inspect,
        "..., conceived in liberty, and ded...".inspect
      ]
    )
  end

  def test_shows_string_difference_start
    lval = {'rev' => "22-23c92a95665bb692313229c8224b7088"}
    rval = {'rev' => "23-54a5106f8c522a57d6d4c6963bc36611"}
    assert_symmetrically_different(
      lval, rval,
      "\":root > .rev\" differs starting at char 1: :left0 differs from :right0",
      ["22-23c92a95665bb6...".inspect, "23-54a5106f8c522a...".inspect]
    )
  end

  def test_simple_exclusion
    lval = {'one' => 'two', 'three' => 'four'}
    rval = {'one' => 'two', 'three' => 'THREE'}
    comparison = JsonDeepCompare::DocumentComparison.new(
      lval, rval, exclusions: [":root > .three"]
    )
    assert comparison.equal?
  end

  def test_exclusion_regexp
    lval = {'one' => 'two', 'three' => 'four'}
    rval = {'one' => 'two', 'three' => 'THREE'}
    comparison = JsonDeepCompare::DocumentComparison.new(
      lval, rval, exclusions: [/> \.three$/]
    )
    assert comparison.equal?
  end

  def test_blank_equality_option
    lval = {'one' => 'two', 'three' => ''}
    rval = {'one' => 'two', 'three' => nil}
    comparison = JsonDeepCompare::DocumentComparison.new(
      lval, rval, blank_equality: true
    )
    assert comparison.equal?
  end

  def test_equality_proc_option
    lval = {'one' => 2, 'three' => "He says 'hi'"}
    rval = {'one' => 2, 'three' => "He says \"hi\""}
    comparison = JsonDeepCompare::DocumentComparison.new(
      lval, rval, equality: Proc.new { |lval, rval|
        if lval.is_a?(String) && rval.is_a?(String)
          lval.gsub(/"/, "'") == rval.gsub(/"/, "'")
        else
          lval == rval
        end
      }
    )
    assert comparison.equal?
  end

  def test_substitutions
    lval = {'one' => 'two', 'three' => 'four'}
    rval = {'one' => 'two', 'three' => 'THREE'}
    comparison = JsonDeepCompare::DocumentComparison.new(
      lval, rval, substitutions: {":root > .three" => 'THREE'}
    )
    assert comparison.equal?
  end
end
