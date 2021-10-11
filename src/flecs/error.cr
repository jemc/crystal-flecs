class ECS::Error < Exception
  property message : String?
  def initialize(@message)
  end
end
