#!/usr/bin/env ruby

require 'set'

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

  def spill(amount)
    if @water_amount - amount > 0
      @water_amount -= amount
    else
      @water_amount = 0
    end
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

  def ==(bucket)
    @capacity == bucket.capacity &&
    @water_amount == bucket.water_amount
  end
end

class GoalBucket  < Bucket
  def initialize(capacity)
    @capacity = capacity
    @water_amount = 0
  end

  def fill(amount)
    @water_amount += amount
  end

end

class Action
  attr_reader :action_name, :arguments

  def initialize(action, argument_list)
    @action_name = action
    @arguments = argument_list
  end

  def to_s
    "#{@action_name}(#{arguments.join(", ")})"
  end

  def ==(action)
    action_name == action.action_name &&
    arguments == action.arguments
  end

  def invert
    case @action_name
      when :fill
        Action.new(:empty, [@arguments[0]])
      when :pour
        Action.new(:pour, [@arguments[1], @arguments[0]])
      when :empty
        Action.new(:fill, [@arguments[0]])
      when :take # from pool filling bucket indexed by first arg with the amount - second arg
        Action.new(:give, [@arguments[0]])
    
    end
  end
end


# used by two_way_search
class Array
  def intersects?(array)
    self.each do |element|
      array.each do |array_element|
        if element.equals(array_element)
          return true 
        end
      end
    end
    false
  end

  def intersection(array)
    self.each do |element|
      array.each do |array_element|
        if element.equals(array_element)
          return [element, array_element]
        end
      end
    end
    nil
  end
end

class Solver
  # explored_states used by dfs
  attr_reader :buckets, :goal, :explored_states
  def initialize
    @buckets = []
    @explored_states = []
  end

  def read_input_data
    STDIN.read.chomp.split.each_with_index do |line, index|
      if index == 0 
        @goal = GoalBucket.new(line.to_i)
      else
        @buckets[index-1] = Bucket.new(line.to_i)
      end
    end
  end

  def bfs(depth_limit)
    start_state = State.new(@buckets, [], @goal)
    fringe_states = [start_state]
    depth = 0

    while (not fringe_states.empty?) 
      state = fringe_states.delete_at(0)
      break if state.actions.count >= depth_limit

      state.generate_possible_actions.each do |action|
        # warn "applying #{action} to #{state}: "
        new_state = state.clone.apply_action(action)
        warn new_state
        if new_state.end_state?
          warn "Success! Last state follows: "
          warn new_state
          warn new_state.actions.join(", ")
          return new_state
        end

        fringe_states << new_state
      end
    end
  end

  def iterative_dfs(max_depth)
    start_state = State.new(@buckets, [], @goal)

    depth = 1
    while depth <= max_depth
      # warn "depth: #{depth}/#{max_depth}"
      @explored_states = []
      result = dfs(start_state, 0, depth)
      if result
        warn "Success! Last state follows: "
        warn result
        warn result.actions.join(", ")
        return result
      end
      depth += 1
    end

    nil
  end

  def dfs(state, depth, max_depth)
    # warn state
    return nil if depth > max_depth
    @explored_states << state

    state.generate_possible_actions.each do |action|
      new_state = state.clone.apply_action(action)
      return new_state if new_state.end_state?

      unless explored_states.include?(new_state)
        result = dfs(new_state, depth+1, max_depth)
        return result if result
      end
    end

    nil
  end

  # hint: start_state is to the left
  # end_state is to the right
  def two_way_search(max_depth)
    start_state = State.new(@buckets, [], @goal)
    end_goal = @goal.clone
    end_goal.fill(@goal.capacity)
    end_state = State.new(@buckets, [], end_goal)

    left_fringe_states = [start_state]
    right_fringe_states = [end_state]

    depth = 0
    # until fringes intersect
    while not (left_fringe_states.intersects?(right_fringe_states)) and depth <= max_depth do
      depth += 1
      # step right
      # puts "left_fringe: #{left_fringe_states}"
      left_state = left_fringe_states.delete_at(0)
      left_state.generate_possible_actions.each do |action|
        left_fringe_states << left_state.clone.apply_action(action)
      end


      # step left
      # puts "right_fringe: #{right_fringe_states}"
      right_state = right_fringe_states.delete_at(0)
      right_state.generate_possible_reverse_actions.each do |action|
        right_fringe_states << right_state.clone.apply_action(action)
      end

    end

    if (left_fringe_states.intersects?(right_fringe_states))
      # return left_fringe_states.intersection(right_fringe_states)
      state1, state2 = left_fringe_states.intersection(right_fringe_states)
      puts state1
      puts state2
      action_list = state1.actions + state2.actions.reverse.map(&:invert)
      puts action_list.join(", ")
      return action_list
    else
      nil
    end
  end

end

class State
  attr_reader :buckets, :actions, :goal
  def initialize(buckets, actions, goal)
    @buckets = buckets
    @actions = actions
    @goal = goal
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

  def bucket_of_capacity_one_present?
    @buckets.each {|b| true if b.capacity == 1}
    false
  end

  def possible_water_amounts_for_bucket(bucket_index)
    bucket = @buckets[bucket_index] 
    return (1...bucket.capacity).to_a if bucket_of_capacity_one_present?

    set = Set.new([bucket.capacity])
    @buckets.each do |other_bucket|
      if bucket != other_bucket
        water_amount = bucket.capacity - other_bucket.capacity 
        while water_amount > 0 
          set << water_amount
          water_amount -= other_bucket.capacity
        end
      end
    end

    set.to_a
  end

  def generate_possible_reverse_actions
    possible_actions = []

    @buckets.each_with_index do |bucket, index|
      possible_actions << Action.new(:empty, [index]) unless bucket.empty?

      # TODO: which reverse actions are allowed, really?
      # space_left = bucket.capacity - bucket.water_amount
      # if space_left <= goal.water_amount
      #   possible_actions << Action.new(:take, [index, space_left])
      # end

      possible_water_amounts_for_bucket(index).each do |amount|
        possible_actions << Action.new(:take, [index, amount])
      end

      # space_left = bucket.capacity - bucket.water_amount
      # (1...space_left).each do |amount|
      #   possible_actions << Action.new(:take, [index, amount])
      # end

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
        # warn "goal water_amount is #{goal.water_amount}"
        goal.fill(bucket.empty)
        # warn "new goal water_amount is #{goal.water_amount}"
      when :take # from pool filling bucket indexed by first arg with the amount - second arg
        bucket = @buckets[action.arguments[0]]
        bucket.fill(action.arguments[1])
        @goal.spill(action.arguments[1])
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

  # full equality, used in bfs & iterative dfs
  def ==(state)
    @buckets == state.buckets &&
    @actions == state.actions &&
    @goal == state.goal
  end

  # partial equality, equality of buckets suffices
  def equals(state)
    @buckets == state.buckets &&
    @goal == state.goal
  end
end

solver = Solver.new
solver.read_input_data

case ARGV.first
  when "bfs"
    solver.bfs(4)
  when "dfs"
    solver.iterative_dfs(4)
  when "two-way"
    solver.two_way_search(8)
end
