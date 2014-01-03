
module TradeBot
  class Ichimoku
    # Perform the ichimoku computation on the last count number of elements.
    # This primarily involved taking the average of the highest high and lowest
    # low out of the previous count elements.
    #
    # @param [Fixnum] count
    # @return [Float]
    def calc(count)
      negative = (count > @dataset.size) ? 0 : -count

      hh = (@dataset.map { |d| d['high'] }).max
      ll = (@dataset.map { |d| d['low']  }).min

      ((hh + ll) / 2)
    end

    # The results of this need to be confirmed against some official
    # documentation. I believe the lags aren't real, and the numerics are
    # probably wrong.
    #
    # @return [Hash]
    def current
      return false unless has_enough_data?

      {
        'tenkan'   => @tenkan.last,
        'kijun'    => @kijun.last,
        'senkou_a' => @senkou_a[-@kijun_n],
        'senkou_b' => @senkou_b[-@kijun_n],
        'chikou'   => @chikou.last,
        'lag_chikou'   => @chikou[-@kijun_n],
        'lag_senkou_a' => @senkou_a[-@senkou_n],
        'lag_senkou_b' => @senkou_b[-@senkou_n]
      }
    end

    # Checks whether there is enough data in the instance of this class to
    # perform a calculation.
    #
    # @return [Boolean]
    def has_enough_data?
      (@dataset.size >= [@tenkan_n, @kijun_n, @senkou_n].max)
    end

    # Setup the ichimoku instance and set the various length parameters to
    # calculate how far back to look.
    #
    # @param [Fixnum] tenkan_n
    # @param [Fixnum] kijun_n
    # @param [Fixnum] senkou_n
    def initialize(tenkan_n = 9, kijun_n = 26, senkou_n = 52)
      @tenkan_n = tenkan_n
      @kijun_n  = kijun_n
      @senkou_n = senkou_n

      @dataset = []
      @tenkan = []
      @kijun = []
      @senkou_a = []
      @senkou_b = []
      @chikou = []
    end

    # Add another candle object to the calculations.
    #
    # @param [Hash] candle
    def push(candle)
      @dataset.push(candle)
      max = -([@tenkan_n, @kijun_n, @senkou_n].max)
      @dataset = @dataset.slice(max..-1) if @dataset.size > max

      @tenkan.push(calc(@tenkan_n))
      @kijun.push(calc(@kijun_n))

      @senkou_a.push((@tenkan.last + @kijun.last) / 2)
      @senkou_b.push(calc(@senkou_n))

      @chikou.push(@dataset[-2]['close']) unless @dataset.size < 2
    end
  end
end
