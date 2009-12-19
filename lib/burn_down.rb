class BurnDown
  def initialize(parameters, project, current_user)
    @parameters = parameters
    @project = project
    @current_user = current_user
  end

  def execute
    self.check_parameters

    data = self.series.collect{|parameters| BurnDownSeries.new(self.start_date, self.end_date, self.conditions, parameters, @project)}
    chart = BurnDownChart.new(data, self.start_date, self.end_date, @parameters)
    %Q{ <img src='#{chart.url}' /> }
  end

  def can_be_cached?
    false  # if appropriate, switch to true once you move your macro to production
  end

  def check_parameters
    required = ['sprint-start', 'sprint-end', 'series']
    required.each do |property|
      if not @parameters.has_key?(property)
        raise "missing parameter. required #{required.join(',')}"
      end
    end
  end

  def start_date
    if not self.instance_variable_defined?(:@start_date)
      sprint_start = @parameters['sprint-start'].trim
      if sprint_start.match(/^SELECT/)
        sprint_start = @project.execute_mql(sprint_start).first.values[0]
      end

      @start_date = Date.parse(sprint_start)
    end
    @start_date
  end

  def end_date
    if not self.instance_variable_defined?(:@end_date)
      sprint_end = @parameters['sprint-end'].trim
      if sprint_end.match(/^SELECT/)
        sprint_end = @project.execute_mql(sprint_end).first.values[0]
      end

      @end_date = Date.parse(sprint_end)
    end
    @end_date
  end

  def title
    @parameters.fetch('title', '')
  end

  def series
    @parameters.fetch('series', [])
  end

  def conditions
    @parameters.fetch('conditions', '')
  end
end

