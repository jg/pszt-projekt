require './main'

describe Solver do 
  it "should read the goal & bucket volumes from stdin" do
    data = [
    100,
    5,
    8,
    3
    ]
    STDIN.should_receive(:read).and_return(data.join("\n"))

    subject.read_input_data()
    subject.buckets[0].capacity.should == 5
    subject.buckets[1].capacity.should == 8
    subject.buckets[2].capacity.should == 3
    subject.goal.capacity.should == 100
  end


  context "#bfs" do
    it "should return the end state of bfs solution search when given start state and depth limit" do
      buckets = [Bucket.new(1), Bucket.new(2), Bucket.new(5)]
      actions = []
      goal = GoalBucket.new(9)

      # start_state = State.new(buckets, actions, goal)
      # end_state = subject.bfs(start_state, 7)

      # end_state.end_state?.should be_true
      # end_state.actions.should_not be_empty
    end
  end

  context "#dfs" do
    it "should return the end state of dfs search when given start state, initial depth and depth limit" do
      buckets = [Bucket.new(1), Bucket.new(2), Bucket.new(5)]
      actions = []
      goal = GoalBucket.new(5)
      start_state = State.new(buckets, actions, goal)
      end_state = subject.iterative_dfs(start_state, 3)

      end_state.to_s.should == "[(fill(2), give(2)), (0/1, 0/2, 0/5), 5/5]"

    end
  end
end

describe GoalBucket do
  subject do 
    GoalBucket.new(150)
  end

  context "#water_amount" do
    it "should return the amount of water contained in the bucket" do
      subject.fill(10)
      subject.water_amount.should == 10
    end
  end

  it "should not be contrained by capacity" do
    bucket = GoalBucket.new(150)
    bucket.fill(160)
    bucket.water_amount.should == 160
  end

  context "#to_s" do
    it "should return a string representation of object" do
      bucket = GoalBucket.new(160)
      bucket.fill(170)
      bucket.to_s.should == "170/160"
    end
  end
end

describe Bucket do
  subject do
    Bucket.new(12)
  end
    
  it "should intialize with capacity" do
    subject.capacity.should == 12
  end

  context "#fill" do
    it "should fill the bucket with given amount of water" do
      subject.fill(4)
      subject.water_amount.should == 4

      subject.empty
      bucket = subject
      bucket.fill(subject.capacity)
      bucket.full?.should be_true
    end

  end

  context "#empty" do
    it "should empty the bucket and return the amount of water spilled" do
      subject.fill(4)
      subject.empty().should == 4
      subject.water_amount.should == 0
    end
  end

  context "#empty?" do
    it "should be true if the bucket is empty" do
      subject.empty()
      subject.empty?.should be_true
    end
  end

  context "#full?" do
    it "should be true if the bucket is full" do
      subject.fill(1000)
      subject.full?.should be_true
    end
  end

  context "#to_s" do
    it "should return the textual representation of a bucket" do
      bucket = Bucket.new(12)
      bucket.fill(4)
      bucket.to_s.should == "4/12"
    end
  end

  context "#==" do
    it "should return true if the buckets are equal" do
      bucket1 = Bucket.new(12)
      bucket2 = Bucket.new(12)
      (bucket1 == bucket2).should be_true
    end
  end
end

describe Action do
  subject do
    action = Action.new(:fill, [1])
  end

  it "should initialize with the name of the action and a list of its arguments" do
    subject.action_name.should == :fill
    subject.arguments[0].should == 1
  end

  it "should allow only certain names of actions" do
    Action.new(:fill, [1])
    Action.new(:empty, [1])
    Action.new(:pour, [1, 2])
    Action.new(:give, [1])
    expect {Action.new(:nonexistent, [1])}.to raise_error
  end

  it "#to_s" do
    Action.new(:fill, [1]).to_s.should == "fill(1)"
    Action.new(:empty, [1]).to_s.should == "empty(1)"
  end

  context "#==" do
    it "should return true if both actions are equal" do
      action1 = Action.new(:fill, [1])
      action2 = Action.new(:fill, [1])
      (action1 == action2).should be_true
    end
  end

end

describe State do
  subject do
    buckets = [Bucket.new(12), Bucket.new(7)]
    actions = [Action.new(:fill, [1, 2])]
    goal = GoalBucket.new(150)
    State.new(buckets, actions, goal)
  end

  it "should contain amount of water in buckets and a list of actions" do
    subject.actions.should_not be_empty
    subject.buckets.should_not be_empty
    subject.goal.capacity.should_not be_nil
  end

  context "#generate_possible_actions" do
    it "should return a list of actions" do
      list = subject.generate_possible_actions
      list.should_not be_empty
      list.to_s.should == "[fill(0), fill(1), pour(0, 1), pour(1, 0)]"
    end
  end

  context "#apply_action" do
    it "should apply action to itself" do
      buckets = [Bucket.new(12), Bucket.new(7)]
      actions = [Action.new(:fill, [1, 2])]
      goal = 150
      state = State.new(buckets, actions, goal)

      state.apply_action(Action.new(:fill, [0]))
      state.buckets[0].water_amount.should == 12

      state.apply_action(Action.new(:pour, [0, 1]))
      state.buckets[1].water_amount.should == 7

      state.apply_action(Action.new(:empty, [0]))
      state.buckets[0].empty?.should be_true

      subject.actions.should_not be_empty
    end
  end

  context "#end_state?" do
    it "should return true if we successfully reached the our goal" do
      subject
    end
  end

  context "to_s" do
    it "should output a list comprised of actions, buckets and goal" do
      subject.to_s.should == "[(fill(1, 2)), (0/12, 0/7), 0/150]"
    end
  end

  context "#clone" do
    it "should deep-clone the State object" do
      buckets = [Bucket.new(12), Bucket.new(7)]
      actions = [Action.new(:fill, [1, 2])]
      goal = GoalBucket.new(150)
      state = State.new(buckets, actions, goal)

      cloned_state = state.clone
      cloned_state.buckets[0].__id__.should_not == buckets[0].__id__
      cloned_state.buckets[1].__id__.should_not == buckets[1].__id__
      cloned_state.actions[0].__id__.should_not == actions[0].__id__
      cloned_state.goal.__id__.should_not == state.goal.__id__
      cloned_state.goal.capacity.should == state.goal.capacity
    end
  end

  context "#==" do
    it "should return true if both states are equal" do
      buckets = [Bucket.new(12), Bucket.new(7)]
      actions = [Action.new(:fill, [1, 2])]
      goal = GoalBucket.new(150)
      state1 = State.new(buckets, actions, goal)
      state2 = State.new(buckets, actions, goal)
      (state1 == state2).should be_true
    end
  end
end
