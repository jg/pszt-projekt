class Bucket
  attr_reader :capacity, :water_amount
  
  def initialize(capacity)
    @capacity     = capacity
    @water_amount = 0
  end

  def fill(amount)
    x = (@water_amount + amount)
    if x >= @capacity
      @water_amount = @capacity
    else
      @water_amount = x
    end
  end

  def empty
    tmp = @water_amount
    @water_amount = 0

    tmp
  end

  def empty?
    @water_amount == 0
  end

  def full?
    @water_amount == @capacity
  end

  def to_s
    "#{@water_amount}/#{@capacity}"
  end
end

class GoalBucket < Bucket
  def fill(amount)
    @water_amount += amount
  end

end

class Action
  attr_reader :action_name, :arguments

  def initialize(action, argument_list)
    unless [:fill, :pour, :empty, :give].include?(action)
      raise
    end

    @action_name = action
    @arguments = argument_list
  end

  def to_s
    "#{@action_name}(#{arguments.join(", ")})"
  end
end

class Solver
  attr_reader :buckets, :goal
  def initialize
    @buckets = []
  end

  def read_input_data
    STDIN.read.chomp.split.each_with_index do |line, index|
      if index == 0 
        @goal = line.to_i
      else
        @buckets[index-1] = Bucket.new(line.to_i)
      end
    end
  end

  def bfs(start_state, depth_limit)
    fringe_states = [start_state]
    depth = 0
    puts start_state

    while (not fringe_states.empty?) and (depth < depth_limit)
      state = fringe_states.delete_at(0)
      depth += 1

      state.generate_possible_actions.each do |action|
        # puts "applying #{action} to #{state}: "
        new_state = state.clone.apply_action(action)
        puts new_state
        if new_state.end_state?
          "Success! Last state follows: "
          puts new_state
          return new_state
        end

        fringe_states << new_state
        # puts "fringe states count: #{fringe_states.count}"
      end
    end

  end
end

class State
  attr_reader :buckets, :actions, :goal
  def initialize(buckets, actions, goal)
    @buckets = buckets
    @actions = actions
    @goal = GoalBucket.new(goal)
  end

  def generate_possible_actions
    possible_actions = []

    @buckets.each_with_index do |bucket, index|
      possible_actions << Action.new(:empty, [index]) unless bucket.empty?
      possible_actions << Action.new(:give, [index]) unless bucket.empty?
      possible_actions << Action.new(:fill, [index]) unless bucket.full?
    end

    @buckets.each_with_index do |bucket1, index1|
      @buckets.each_with_index do |bucket2, index2|
        possible_actions << Action.new(:pour, [index1, index2]) if index1 != index2
      end
    end

    possible_actions
  end

  def apply_action(action)
    @actions << action
    case action.action_name
      when :fill
        bucket = @buckets[action.arguments[0]]
        bucket.fill(bucket.capacity)
      when :pour
        bucket1 = @buckets[action.arguments[0]]
        bucket2 = @buckets[action.arguments[1]]
        bucket2.fill(bucket1.empty)
      when :empty
        @buckets[action.arguments[0]].empty
      when :give
        bucket = @buckets[action.arguments[0]]
        goal.fill(bucket.empty)
    end

    self
  end

  def end_state?
    @goal.full?
  end

  def to_s
    "[(#{actions.join(", ")}), (#{buckets.join(", ")}), #{goal}]"
  end

  def clone
    cloned_buckets = []
    @buckets.each do |bucket|
      cloned_buckets << bucket.clone
    end

    cloned_actions = []
    @actions.each do |action|
      cloned_actions << action.clone
    end

    cloned_goal = @goal.clone

    State.new(cloned_buckets, cloned_actions, cloned_goal)
  end
end
