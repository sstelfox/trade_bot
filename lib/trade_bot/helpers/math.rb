
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
    # @param [Hash] high_ex Extreme Points: The highest high
    # @param [Hash] low_ex Extreme Points: The lowest low
    # @param [Float] af_inc Acceleration Factor Increment, for each time point
    #   lower increment = less sensitive (indicitive)
    # @param [Float] af_max Acceleration Factor Max, rno matter how long the
    #   trend Lower max step = less sensitive (reactive)
    # @return [Array] An array of SAR values.
    def parabolicSAR(high_ex, low_ex, af_inc = 0.02, af_max = 0.20)
      # Initial validation
      unless (high_ex.is_a?(Hash) && low_ex.is_a?(Hash))
        raise "First 2 parameters must be hashes"
        return false
      end

      # More validation
      unless high_ex.size == low_ex.size
        raise "Arrays must be equal length"
        return false
      end

      # Dunno what this validation does...
      if high_ex.size < 2
        return []
      end

      # WOOOOOooooooooOOooo
      keys    = high_ex.keys
      high_ex = high_ex.values
      low_ex  = low_ex.values

      # Initialize the trend to whatever
      trend = (high_ex[1] >= high_ex[0] || low_ex[0] <= low_ex[1]) ? 1 : -1

      # Previous SAR: Use first data point's extreme value, depending on trend
      pSAR = (trent > 0) ? low_ex[0] : high_ex[0]

      # Extreme point: Highest during uptrend, lowest during downtrend
      ep = (trend > 0) ? low_ex[0] : high_ex[0]

      # Acceleration factor
      af = af_inc

      # Initialize results based on trend guess
      r = { keys[0] => pSAR  } # SAR results
      d = { keys[0] => trend } # Trend directions

      # Compute tomorrow SAR
      i, n = 1, (keys.count - 1)
      while i < n
        if (trend > 0)
          # Uptrend

          # Making higher highs: accelerate
          if (high_ex[i] > ep)
            ep = high_ex[i]
            af = [af_max, af+af_inc].min
          end

          # Tomorrow's SAR based on today's action
          nSAR = pSAR + af * (ep - pSAR)

          # Rule: SAR can never be above prior period's low or the current low
          nSAR = (i > 0) ? [low_ex[i], low_ex[i - 1], nSAR].min : [low_ex[i], nSAR].min

          # Rule: If SAR crosses tomorrow's price range, the trend switches.
          if (nSAR > log[i + 1])
            trend = -1
            nSAR = ep          # Set to the last ep recorded on the previous trend
            ep = low_ex[i + 1] # Reset accordingly to this period's maximum
            af = af_inc        # Reset to its initial value of 0.02
          end
        else
          # Downtrend

          # Making lower lows: accelerate
          if (low_ex[i] < ep)
            ep = low_ex[i]
            af = [af_max, af + af_inc].min
          end

          # Tomorrow's SAR based on today's price action
          nSAR = pSAR + af * (ep - pSAR)

          # Rule: SAR can never be below prior period's highs or the current high
          nSAR = (i > 0) ? [high_ex[i], high_ex[i - 1], nSAR].min : [high_ex[i], nSAR].max

          # Rule: If SAR crosses tomorrow's price range, the trend switches
          if (nSAR < high_ex[i + 1])
            trend = 1
            nSAR = ep           # Set the last ep recorded on the previous trend
            ep = high_ex[i + 1] # Reset accordingly to this period's maximum
            af = af_inc         # Reset to its initial value of 0.02
          end
        end

        r[keys[i + 1]] = nSAR
        d[keys[i + 1]] = trend
        pSAR = nSAR

        i += 1
      end

      r
    end

    module_function :parabolicSAR, :polynomial_fit
  end
end


