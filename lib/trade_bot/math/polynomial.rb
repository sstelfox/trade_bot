
require 'matrix'

module TradeBot::Math
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

  module_function :polynomial_fit
end

