
module TradeBot::Math
  # Implementation of the SAR has been a little bit open to interpretation
  # since Wilder (the original author) did not define a precise algorithm on
  # how to bootstrap the algorithm. Take any existing software application and
  # you will see slight variation on how the algorithm was adapted.
  #
  # What is the initial trade direction? Long or short?
  # ===================================================
  # The interpretation of what should be the initial SAR values is open to
  # interpretation, particularly since the caller to the function does not
  # specify the initial direction of the trade.
  #
  # In this instance, the following logic is used:
  #
  #  * Calculate +DM and -DM between the first and second sets of values. The
  #    highest directional indication will indicate the assumed direction of the
  #    trade for the second price bar.
  #  * In the case of a tie between +DM and -DM, the direction is LONG by
  #    default.
  #
  # What is the initial "extreme point" and thus SAR?
  # =================================================
  # The following shows how different people took different approach:
  #  - Metastock use the first price bar high/low depending of the direction.
  #    No SAR is calculated for the first price bar.
  #  - Tradestation use the closing price of the second bar. No SAR are
  #    calculated for the first price bar.
  #  - Wilder (the original author) use the SIP from the previous trade (cannot
  #    be implement here since the direction and length of the previous trade is
  #    unknonw).
  #  - The Magazine TASC seems to follow Wilder approach which is not practical
  #    here.
  #
  # This implementation "consumes" the first price bar and use its high/low as
  # the initial SAR of the second price bar. This approach seems to be the
  # closest to Wilders idea of having the first entry day use the previous
  # extreme point, except that here the extreme point is derived solely from
  # the first price bar.
  #
  def psar(inHigh, inLow, startIdx, endIdx, optInAcceleration = 0.02, optInMaximum = 0.2)
    # Temporary stand in variables, only initialized here to ease the porting of
    # the C code.
    isLong, todayIdx, outIdx = [nil] * 3
    newHigh, newLow, prevHigh, prevLow = [nil] * 4
    ep, sar = [nil] * 2

    raise "Variable out of range" if optInAcceleration < 0 || optInMaximum < 0
    raise "Index out of range" if startIdx < 0 || endIdx < 0 || endIdx < startIdx

    # Move up the start index if it's 0 to allow a historical value to
    # bootstrap the algorithm.
    startIdx = 1 if startIdx < 1

    # Make sure there is still something to evaluate
    raise "Not enough data" if startIdx > endIdx

    # Make sure the acceleration and maximum are coherent. If not, correct the
    # acceleration.
    optInAcceleration = optInMaximum if (optInAcceleration > optInMaximum)
    af = optInAcceleration

    # Identify if the initial direction is long or short.
  end

  module_function :psar
end

