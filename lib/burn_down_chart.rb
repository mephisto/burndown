# Okay some of this is nicked from gchartrb module code,
# but I couldn't get it to produce a chart how
# we needed, so ended up creating this class instead
class BurnDownChart
  attr_reader :url
  attr_accessor :params

  BASE_URL="http://chart.apis.google.com/chart?"

  def initialize(data, start_date, end_date, parameters, extras={})
    @data = data
    @start_date = start_date
    @end_date = end_date

    self.params = {}
    @parameters = parameters
    self.check_parameters

    self.generate_chart
    @url = self.to_url(extras)
  end

  def generate_chart
    self.params.merge!({:cht => 'lxy'})

    if (self.width * self.height) > 300000
      raise 'Chart may contain at most 300000, pixels'
    end

    self.params.merge!({:chs => "#{self.width}x#{self.height}"})

    # add in sprint lines
    days = @end_date-@start_date
    dataSeries = []
    lineStyles = []
    colours = []
    labels = []

    dataSetIndex = 0
    maxEffort = @data.collect{|d| d.total_effort}.sort.last

    @data.each do |d|
      dataSeries.push( self.encode_data( [0,days], days ) )
      dataSeries.push( self.encode_data( [d.total_effort,0], maxEffort ) )

      lineStyles.push('1,6,3')
      colours.push(d.colour + '88')
      labels.push("#{d.label} target")

      dataSetIndex += 1

      data = self.build_series(d)

      dataSeries.push( self.encode_data( data['x'], days ) )
      dataSeries.push( self.encode_data( data['y'], maxEffort ) )

      lineStyles.push('1,1,0')
      colours.push(d.colour)
      labels.push(d.label)

      dataSetIndex += 1
    end
    
    
    # chart data
    self.params.merge!({:chd => self.url_data(dataSeries)})
    self.params.merge!({:chds => "0,100,0,100"})

    # chart line styles and colours
    self.params.merge!({:chls => lineStyles.join('|')})
    self.params.merge!({:chco => colours.join(',')})

    # chart legend
    if self.show_legend
      self.params.merge!({:chdl => labels.join('|')})
    end

    # chart title
    if self.title != nil
      self.params.merge!({:chtt => self.title})
      self.params.merge!({:chts => "#{self.title_colour},#{self.title_size}"})
    end

    # chart axis
    axis = ['x', 'y', 'x'] # dates, units, months
    axisStyles = []
    tickLengths = []
    
    currentMonth = @start_date.strftime('%b')
    dates = []
    datePositions = []
    months = [currentMonth]
    monthPositions = [0]
              
    i = 0
    (@start_date..@end_date).each do |d|
      if (i % self.x_step) == 0
        dates.push(d.mday.to_s)
        position = (((d-@start_date).to_f / days.to_f) * 100.00).to_i
        
        datePositions.push(position)
        
        if currentMonth != d.strftime('%b')
          currentMonth = d.strftime('%b')
          months.push(currentMonth)
          monthPositions.push(position)
        end
      end
      
      i += 1
    end
    
    labels = ["0:|#{dates.join('|')}", "2:|#{months.join('|')}"]
    labelPositions = [
      "0,#{datePositions.join(',')}",
      "2,#{monthPositions.join(',')}"
    ]
    
    if self.show_today
      axis.push('x') # today (bottom)
      
      todayPosition = (((Date.today-@start_date).to_f / days.to_f) * 100.00).to_i
      
      labels.push("3:|today")
      labelPositions.push("3,#{todayPosition}")
      axisStyles.push("3,000000,10,0,t,#{self.today_colour}")
      tickLengths.push("3,#{-1 * self.height}") # draw red
    end
    
    self.params.merge!({:chxt => axis.join(',')})
    self.params.merge!({:chxr => "1,0,#{maxEffort},#{self.y_step}"})
    self.params.merge!({:chxl => labels.join('|')})
    self.params.merge!({:chxp => labelPositions.join('|')})
    self.params.merge!({:chxs => axisStyles.join('|')})
    self.params.merge!({:chxtc => tickLengths.join('|')})
    
    # chart grid
    if self.show_grid
      grid = [
        ((self.x_step.to_f / days.to_f) * 100.00).to_i,
        ((self.y_step.to_f / maxEffort.to_f) * 100.00).to_i
      ] + self.grid_style
      self.params.merge!({:chg => grid.join(',')})
    end
  end

  def to_url(extras={})
    self.params.merge!(extras)
    query_string = self.params.map { |k,v| "#{k}=#{URI.escape(v.to_s).gsub(/%20/,'+').gsub(/%7C/,'|')}" }.join('&')
    BASE_URL + query_string
  end

  def url_data(dataSeries)    
    't:' + self.join_encoded_data(dataSeries)
  end

  def encode_data(values, max_value=nil)
    # put value into the scale of 0 to 100
    max_value = values.sort.last unless max_value
    scale = (100.00 / max_value.to_f).to_f
    values.collect{|v| "#{(v.to_f * scale).to_i}"}.join(',')
  end

  def join_encoded_data(encoded_data)
    joined = encoded_data.join('|')
  end

  def build_series(series)
    effort_remaining = series.total_effort.to_f
    data = {'x' => [], 'y' => []}

    if not self.strict_sprint
      # if series starts before start_date take off total complete from effort_remaining
      completed = series.dates.select {|d,v| d < @start_date}.collect {|p| p[1].to_f}
      completed.each do |v|
        effort_remaining -= v
      end
    end

    (@start_date..@end_date).each do |date|
      if series.dates.has_key?(date)
        effort_remaining -= series.dates[date].to_f
      end

      if date <= Date.today && effort_remaining >= 0.0
        data['x'].push(date-@start_date)
        data['y'].push(effort_remaining)

        # make it so that we get to zero, but then push off
        if effort_remaining == 0.0
          effort_remaining = -1.0
        end
      end
    end

    data
  end

  def check_parameters
    # add required parameters as array of strings
    required = []
    required.each do |property|
      if not @parameters.has_key?(property)
        raise "missing parameter. required #{required.join(',')}"
      end
    end
  end

  def data_encoding
    case @parameters.fetch('encoding', 'extended')
      when 'text' then :text
      when 'simple' then :simple
      when 'extended' then :extended
      else raise "invalid encoding, only text, simple or extended allowed"
    end
  end

  def x_step
    @parameters.fetch('x-axis-step', '1').to_i
  end

  def y_step
    @parameters.fetch('y-axis-step', '1').to_i
  end

  def title
    @parameters.fetch('title', nil)
  end

  def title_colour
    @parameters.fetch('title-colour', '000000')
  end

  def title_size
    @parameters.fetch('title-size', '16')
  end

  def width
    @parameters.fetch('chart-width', '480').to_i
  end

  def height
    @parameters.fetch('chart-height', '320').to_i
  end

  def show_legend
    @parameters.fetch('show-legend', true)
  end

  def show_today
    @parameters.fetch('show-today', true)
  end

  def today_colour
    @parameters.fetch('today-colour', 'ff0000')
  end

  def show_grid
    @parameters.fetch('show-grid', true)
  end

  def strict_sprint
    @parameters.fetch('strict-sprint', false)
  end

  def grid_style
    case @parameters.fetch('grid-style', 'dashed')
      when 'dashed' then []
      when 'dotted' then [1,5]
      when 'solid' then [1,0]
    end
  end
end
