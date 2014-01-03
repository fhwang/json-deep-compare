module JsonDeepCompare
  VERSION = '0.0.1'

  class NodeComparison
    ExcerptPadding = 15
    attr_reader :left_value, :right_value, :selector

    def initialize(left_value, right_value, options = {})
      @left_value, @right_value = left_value, right_value             
      @selector = options[:selector] || ':root'
      @exclusions = options[:exclusions]
      @exclusions = [@exclusions] unless @exclusions.is_a?(Array)
      @children = []
      if left_value.is_a?(Hash)
        if right_value.is_a?(Hash)
          left_value.each do |key, left_sub_value|
            @children << NodeComparison.new(
              left_sub_value, right_value[key], 
              selector: "#{selector} > .#{key}", exclusions: @exclusions
            )
          end
        end
      elsif left_value.is_a?(Array)
        if right_value.is_a?(Array)
          left_value.each_with_index do |left_sub_value, i|
            @children << NodeComparison.new(
              left_sub_value, right_value[i], 
              selector: "#{selector} :nth-child(#{i+1})", 
              exclusions: @exclusions
            )
          end
        end
      end
    end

    def value_inspect(value)
      str = value.inspect
      if str.length >= 40
        "#{value.class.name} #{str[0..37]}..."
      else
        str
      end
    end

    def difference_message
      unless equal?
        if leaf?
          if excerptable_difference?
            excerpted_difference
          else
            "#{@selector.inspect} expected to be #{value_inspect(@left_value)} but was #{value_inspect(@right_value)}"
          end
        else
          @children.reject(&:equal?).map(&:difference_message).join("\n")
        end
      end
    end

    def equal?
      if leaf?
        @exclusions.include?(@selector) || @left_value == @right_value
      else
        @children.all?(&:equal?)
      end
    end

    def excerptable_difference?
      @left_value.is_a?(String) and @right_value.is_a?(String) && (
        @left_value.size > ExcerptPadding * 2 || 
        @right_value.size > ExcerptPadding * 2
      )
    end

    def excerpted_difference
      difference_start = (0..@left_value.length).detect { |i| 
        @left_value[i] != @right_value[i]
      }
      range_start = if difference_start > ExcerptPadding
        difference_start - ExcerptPadding
      else
        0
      end
      left_excerpt = @left_value[
        range_start..difference_start+ExcerptPadding
      ]
      right_excerpt = @right_value[
        range_start..difference_start+ExcerptPadding
      ]
      if difference_start - ExcerptPadding > 0
        left_excerpt = "..." + left_excerpt
        right_excerpt = "..." + right_excerpt
      end
      if difference_start + ExcerptPadding < @left_value.length
        left_excerpt = left_excerpt + '...'
      end
      if difference_start + ExcerptPadding < @right_value.length
        right_excerpt = right_excerpt + '...'
      end
      "#{@selector.inspect} differs starting at char #{difference_start}: #{left_excerpt.inspect} differs from #{right_excerpt.inspect}"
    end

    def leaf?
      @children.empty?
    end
  end

  module Assertions
    def assert_json_equal(expected, actual, exclusions = nil)
      comparison = NodeComparison.new(expected, actual, exclusions: exclusions)
      unless comparison.equal?
        fail comparison.difference_message
      end
    end
  end
end
