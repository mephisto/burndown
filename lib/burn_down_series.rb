class BurnDownSeries
  attr_reader :total_effort, :dates, :label
  def initialize(start_date, end_date, conditions, parameters, project)
    @start_date = start_date
    @end_date = end_date
    @conditions = conditions

    @parameters = parameters
    self.check_parameters

    @project = project
    @label = @parameters['label']
    self.get_data
  end

  def colour
    @parameters.fetch('colour', '0000ff')
  end

  def check_parameters
    required = ['data', 'down-from', 'label']
    required.each do |property|
      if not @parameters.has_key?(property)
        raise "missing series parameter. required #{required.join(',')}"
      end
    end
  end

  def get_data
    # run's mql's in order to get total effort and how many points convered on each date
    # get total points

    @total_effort = @project.execute_mql(self.down_from_mql).first.values.sum

    # get completed ammount of points for given date
    rows = @project.execute_mql(self.data_mql)

    dates = rows.collect {|r| r.values } # get just the values, assumes first column is date, second is value
    dates = dates.sort {|a,b| Date.parse(a[0]) <=> Date.parse(b[0])}

    @dates = {}
    dates.each do |d|
      @dates[Date.parse(d[0])] = d[1].to_f
    end
  end

  def data_mql
    mql = @parameters['data']
    if @parameters['data'].match(/WHERE/)
      mql += " AND #{@conditions}"
    else
      mql += "WHERE #{@conditions}"
    end
    mql
  end

  def down_from_mql
    mql = @parameters['down-from']
    if @parameters['down-from'].match(/WHERE/)
      mql += " AND #{@conditions}"
    else
      mql += "WHERE #{@conditions}"
    end
    mql
  end

  def to_s
    "total effort: #{self.total_effort} dates:" + self.dates.to_s
  end
end
