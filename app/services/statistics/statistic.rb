class Statistic
  def initialize
    validate!
  end

  def compute
    raise NotImplementedError, "#{self.class.name} does not implement statistic compution"
  end

  protected

  def validate!
    true
  end

  def apply_filter(query)
    query
  end
end
