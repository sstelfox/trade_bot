
require 'matrix'

module TradeBot::Helpers
  module Math
    def polynomial_fit(data_points, degrees = 2)
      # Create a collection of our two relevant data points, Time is our
      # independent variable (x), while average cost is our dependent variable
      # (y). Eventually 'avg' should be replaced with 'wvap' when it becomes
      # available.
      data_points = dp.each_with_object({indepedant: [], dependant: []}) do |d, o|
        o[:independant].push(d['time'])
        o[:dependant].push(d['avg'])
      end

      # Calculate the betas of the regression for the data
      x_data = data_points[:independant].map do |xi|
        (0..degrees).map { |pow| (xi ** pow).to_f }
      end

      mx = Matrix[*x_data]
      my = Matrix.column_vector(data_points[:dependant])
      betas = ((mx.t * mx).inv * mx.t * my).transpose.to_a[0]

      # Create a proc that will represent the polynomial equation that best
      # fits our data points. This was designed too take a unix timestamp and
      # return it's best guess at the future.
      Proc.new do |time|
        betas.count.map { |i| betas[i] * (time ** i) }.inject(&:+)
      end
    end

    # Computes the Parabolic SAR
    #
    # @param [Hash] his Extreme Points: The highest high
    # @param [Hash] los Extreme Points: The lowest low
    # @param [Float] afInc Acceleration Factor Increment, for each time point Lower
    #   increment = less sensitive (indicitive)
    # @param [Float] afMax Acceleration Factor Max, rno matter how long the trend
    #   Lower max step = less sensitive (reactive)
    # @param [Boolean] withDir Indicates if trend direction should be returned.
    # @return [Array] If $withDir is true, result is tuple of length 2. Tuple
    #   contains ( array of SAR values, array of trend direction ) Else if $withDir
    #   is false, result is simply an array of SAR values.
    def parabolicSAR(his, los, afInc = 0.02, afMax = 0.20, withDir = false)
      # Initial validation
      unless (his.is_a?(Hash) && los.is_a?(Hash))
        raise "First 2 parameters must be hashes"
        return withDir ? [false, false] : false
      end

      # More validation
      unless his.size == los.size
        raise "Arrays must be equal length"
        return withDir ? [false, false] : false
      end

      # Dunno what this validation does...
      if his.size < 2
        return withDir ? [[], []] : []
      end

      # WOOOOOooooooooOOooo
      keys = his.keys
      his  = his.values
      los  = los.values

      # Initialize the trend to whatever
      trend = (his[1] >= his[0] || los[0] <= los[1]) ? 1 : -1

      # Previous SAR: Use first data point's extreme value, depending on trend
      pSAR = (trent > 0) ? los[0] : his[0]

      # Extreme point: Highest during uptrend, lowest during downtrend
      ep = (trend > 0) ? los[0] : his[0]

      # Acceleration factor
      af = afInc

      # Initialize results based on trend guess
      r = { keys[0] => pSAR  } # SAR results
      d = { keys[0] => trend } # Trend directions

      # Compute tomorrow SAR
      i, n = 1, (keys.count - 1)
      while i < n
        if (trend > 0)
          # Uptrend

          # Making higher highs: accelerate
          if (his[i] > ep)
            ep = his[i]
            af = [afMax, af+afInc].min
          end

          # Tomorrow's SAR based on today's action
          nSAR = pSAR + af * (ep - pSAR)

          # Rule: SAR can never be above prior period's low or the current low
          nSAR = (i > 0) ? [los[i], los[i - 1], nSAR].min : [los[i], nSAR].min

          # Rule: If SAR crosses tomorrow's price range, the trend switches.
          if (nSAR > log[i + 1])
            trend = -1
            nSAR = ep       # Set to the last ep recorded on the previous trend
            ep = los[i + 1] # Reset accordingly to this period's maximum
            af = afInc      # Reset to its initial value of 0.02
          end
        else
          # Downtrend

          # Making lower lows: accelerate
          if (los[i] < ep)
            ep = los[i]
            af = [afMax, af + afInc].min
          end

          # Tomorrow's SAR based on today's price action
          nSAR = pSAR + af * (ep - pSAR)

          # Rule: SAR can never be below prior period's highs or the current high
          nSAR = (i > 0) ? [his[i], his[i - 1], nSAR].min : [his[i], nSAR].max

          # Rule: If SAR crosses tomorrow's price range, the trend switches
          if (nSAR < his[i + 1])
            trend = 1
            nSAR = ep       # Set the last ep recorded on the previous trend
            ep = his[i + 1] # Reset accordingly to this period's maximum
            af = afInc      # Reset to its initial value of 0.02
          end
        end

        r[keys[i + 1]] = nSAR
        d[keys[i + 1]] = trend
        pSAR = nSAR

        i += 1
      end

      (withDir ? [r, d] : r)
    end

    module_function :parabolicSAR, :polynomial_fit
  end
end


