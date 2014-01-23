require 'test/unit'
$: << '.'
require 'lib/json-deep-compare'

class DocumentComparisonTestCase < Test::Unit::TestCase
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
    comparison = JsonDeepCompare::DocumentComparison.new(
      left_value, right_value
    )
    assert !comparison.equal?
    assert_equal(
      "\":root > .rows :nth-child(1) > .doc > .sub_document > .one\" expected to be \"two\" but was \"1\"", 
      comparison.difference_message
    )
  end

  def test_detects_differences_in_keys
    left_value = {"doc" => {"foo" => "bar"}}
    right_value = {"doc" => {"biz" => "bang", "bing" => nil}}
    comparison = JsonDeepCompare::DocumentComparison.new(
      left_value, right_value
    )
    assert !comparison.equal?
  end

  def test_detects_difference_in_type
    lval = {"foo" => {'bar' => 'bang'}}
    rval = {"foo" => [3,4,5]}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .foo\" expected to be {\"bar\"=>\"bang\"} but was [3, 4, 5]",
      comparison.difference_message
    )
  end

  def test_detects_difference_in_type_and_truncates
    lval_hash = {}
    'A'.upto('Z').each do |letter|
      lval_hash[letter] = letter
    end
    lval = {"foo" => lval_hash}
    rval = {"foo" => [3,4,5]}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .foo\" expected to be Hash {\"A\"=>\"A\", \"B\"=>\"B\", \"C\"=>\"C\", \"D\"=>\"D... but was [3, 4, 5]",
      comparison.difference_message
    )
  end

  def test_lists_multliple_differences
    lval = {'one' => {'two' => 'three', 'four' => 'five'}, 'six' => 'seven'}
    rval = {'one' => {'two' => 'TWO', 'four' => 'five'}, 'six' => 'SIX'}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .one > .two\" expected to be \"three\" but was \"TWO\"\n\":root > .six\" expected to be \"seven\" but was \"SIX\"",
      comparison.difference_message
    )
  end

  def test_detects_difference_between_array_and_nil
    lval = {'one' => [1,2,3]}
    rval = {'one' => nil}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .one\" expected to be [1, 2, 3] but was nil",
      comparison.difference_message
    )
  end

  def test_shows_first_string_difference
    lval = {'body' => "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in Liberty, and dedicated to the proposition that all men are created equal."}
    rval = {'body' => "Four score and seven years ago our fathers brought forth on this continent, a new nation, conceived in liberty, and dedicated to the proposition that all men are created equal."}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .body\" differs starting at char 103: \"..., conceived in Liberty, and ded...\" differs from \"..., conceived in liberty, and ded...\"",
      comparison.difference_message
    )
  end

  def test_shows_string_difference_start
    lval = {'rev' => "22-23c92a95665bb692313229c8224b7088"}
    rval = {'rev' => "23-54a5106f8c522a57d6d4c6963bc36611"}
    comparison = JsonDeepCompare::DocumentComparison.new(lval, rval)
    assert !comparison.equal?
    assert_equal(
      "\":root > .rev\" differs starting at char 1: \"22-23c92a95665bb6...\" differs from \"23-54a5106f8c522a...\"",
      comparison.difference_message
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
end
