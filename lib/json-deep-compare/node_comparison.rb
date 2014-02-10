module JsonDeepCompare
  class NodeComparison
    ExcerptPadding = 15
    attr_reader :lval, :rval, :selector

    def initialize(lval, rval, selector, options = {})
      @lval, @rval, @selector, @options = lval, rval, selector, options
      @children = []
      if lval.is_a?(Hash)
        if rval.is_a?(Hash)
          lval.each do |key, left_sub_value|
            @children << NodeComparison.new(
              left_sub_value, 
              rval[key], 
              "#{selector} > .#{key}", 
              options
            )
          end
        end
      elsif lval.is_a?(Array)
        if rval.is_a?(Array)
          lval.each_with_index do |left_sub_value, i|
            @children << NodeComparison.new(
              left_sub_value, 
              rval[i], 
              "#{selector} :nth-child(#{i+1})",
              options
            )
          end
        end
      end
    end

    def blank?(value)
      value.respond_to?(:empty?) ? value.empty? : !value
    end

    def blank_equality?
      @options[:blank_equality]
    end

    def differences
      if equal?
        []
      else
        if leaf?
          if excerptable_difference?
            [excerpted_difference]
          else
            [Difference.new(
              @selector, "expected to be :lval but was :rval",
              lval: value_inspect(@lval), rval: value_inspect(@rval)
            )]
          end
        else
          @children.map(&:differences).compact.flatten
        end
      end
    end

    def equal?
      if leaf?
        if selector_excluded?
          true
        elsif equality_proc
          equality_proc.call(lval_for_equality, rval_for_equality)
        elsif blank_equality? && blank?(lval_for_equality) && blank?(rval_for_equality)
          true
        else
          lval_for_equality == rval_for_equality
        end
      else
        @children.all?(&:equal?)
      end
    end

    def equality_proc
      @options[:equality]
    end

    def excerptable_difference?
      @lval.is_a?(String) and @rval.is_a?(String) && (
        @lval.size > ExcerptPadding * 2 || @rval.size > ExcerptPadding * 2
      )
    end

    def excerpted_difference
      difference_start = (0..@lval.length).detect { |i| @lval[i] != @rval[i] }
      range_start = if difference_start > ExcerptPadding
        difference_start - ExcerptPadding
      else
        0
      end
      left_excerpt = @lval[range_start..difference_start+ExcerptPadding]
      right_excerpt = @rval[range_start..difference_start+ExcerptPadding]
      if difference_start - ExcerptPadding > 0
        left_excerpt = "..." + left_excerpt
        right_excerpt = "..." + right_excerpt
      end
      if difference_start + ExcerptPadding < @lval.length
        left_excerpt = left_excerpt + '...'
      end
      if difference_start + ExcerptPadding < @rval.length
        right_excerpt = right_excerpt + '...'
      end
      Difference.new(
        @selector,
        "differs starting at char :difference_start: :lval differs from :rval",
        difference_start: difference_start.to_s,
        lval: left_excerpt.inspect, rval: right_excerpt.inspect
      )
    end

    def has_substitution?
      @options[:substitutions] && @options[:substitutions].has_key?(selector)
    end

    def leaf?
      @children.empty?
    end

    def left_to_right?
      @options[:direction] == :left
    end

    def lval_for_equality
      @_lval_for_equality ||= begin
        if left_to_right? && has_substitution?
          substitution
        else
          lval
        end
      end
    end

    def right_to_left?
      @options[:direction] == :right
    end

    def rval_for_equality
      @_rval_for_equality ||= begin
        if right_to_left? && has_substitution?
          substitution
        else
          rval
        end
      end
    end

    def selector_excluded?
      @options[:exclusions].any? { |exclusion|
        if exclusion.is_a?(String)
          exclusion == @selector
        else
          @selector =~ exclusion
        end
      }
    end

    def substitution
      @options[:substitutions][selector]
    end

    def value_inspect(value)
      str = value.inspect
      if str.length >= 40
        "#{value.class.name} #{str[0..37]}..."
      else
        str
      end
    end

    class Difference
      attr_reader :selector

      def initialize(selector, msg_template, variables)
        @selector, @msg_template, @variables = 
          selector, msg_template, variables
      end

      def message
        msg = @msg_template
        @variables.each do |name, value|
          msg = msg.gsub(/#{name.inspect}/, value)
        end
        "#{@selector.inspect} #{msg}"
      end

      def reverse
        reversed_variables = {lval: @variables[:rval], rval: @variables[:lval]}
        (@variables.keys - [:lval, :rval]).each do |other_var|
          reversed_variables[other_var] = @variables[other_var]
        end
        Difference.new(@selector, @msg_template, reversed_variables)
      end
    end
  end
end
