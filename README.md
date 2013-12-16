# JsonDeepCompare

For quickly finding differences between two large JSON documents.

Currently JsonDeepCompare is test-oriented.  Its utility might be
expanded in the future.

## Installation

To use in a Test::Unit test case, include `JsonDeepCompare::Assertions`:

    class MyTest < Test::Unit::TestCase
      include JsonDeepCompare::Assertions

If you're using Rails, put this in `test/test_helper.rb`:

    class ActiveSupport::TestCase
      include JsonDeepCompare::Assertions

## Usage

`JsonDeepCompare::Assertions` provides the `assert_json_equal` method:

    class MyTest
      include JsonDeepCompare::Assertions

      def test_comparison
        left_value = {
          'total_rows' => 2,
          'rows' => [
            {
              'id' => 'foo',
              'doc' => {
                '_id' => 'foo', 'title' => 'Foo', 'sub_document' => { 'one' => 'two' }
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
                '_id' => 'foo', 'title' => 'Foo', 'sub_document' => { 'one' => '1' }
              }
            }
          ]
        }
        assert_json_equal(left_value, right_value)
      end
    end
  
Running this test will yield this error:

    RuntimeError: ":root > .rows :nth-child(1) > .doc > .sub_document > .one" expected to be "two" but was "1"

The selector syntax uses a limited subset of
[JSONSelect](http://jsonselect.org/) to describe where to find the
differences.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
