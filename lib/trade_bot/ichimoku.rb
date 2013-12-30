
module TradeBot
  class Ichimoku
    def calc(count)
      negative = (count > @dataset.size) ? 0 : -count

      hh = @dataset.map { |d| d['high'] }.max
      ll = @dataset.map { |d| d['low']  }.low

      ((hh + ll) / 2)
    end

    def initialize(dataset = [], tenkan_n = 9, kijun_n = 26, senkou_n = 52)
      @dataset = dataset

      @tenkan_n = 9
      @kijun_n  = 26
      @senkou_n = 52

      @tenkan = @kijun = @senkou_a = @senkou_b = @chikou = []
    end

    def push(candle)
      @dataset.push(candle)

      @tenkan.push(calc(@tenkan_n))
      @kijun.push(calc(@kijun_n))

      @senkou_a.push((@tenkan.last + @kijun.last) / 2)
      @senkou_b.push(calc(@senkou_n))

      @chikou.push(@dataset[-2]['close']) unless @dataset.size < 2
    end

    # The results of this need to be confirmed against some official
    # documentation. I believe the lags aren't real, and the numerics are
    # probably wrong.
    def current
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
  end
end
