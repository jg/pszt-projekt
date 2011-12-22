PSZT-Projekt
-------------

Install bundler
    ```gem install bundler```

Prepare environment
    ```bundle```

Run tests 
    ```bundle exec rspec test.rb```

Play with the code.

1. Run irb
2. ```require './main'```
3. Sample code snippets:
4. Uncomment puts methods in code for the full experience :-)

## Snippet-1
```
require './main'
buckets = [Bucket.new(1), Bucket.new(2), Bucket.new(5)]
actions = []
goal = GoalBucket.new(9)
start_state = State.new(buckets, actions, goal)
end_state = Solver.new.bfs(start_state, 7)
```


## Snippet-2
```
require './main'
buckets = [Bucket.new(1), Bucket.new(2), Bucket.new(5)]
actions = []
goal = GoalBucket.new(4)
start_state = State.new(buckets, actions, goal)
end_state = Solver.new.iterative_dfs(start_state, 3)
```


