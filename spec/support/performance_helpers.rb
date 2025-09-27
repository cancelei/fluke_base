# Performance testing helpers
module PerformanceHelpers
  # N+1 query detection
  def expect_no_n_plus_one_queries
    expect do
      yield
    end.not_to exceed_query_limit(5)
  end

  # Query limit matcher (requires bullet gem or similar)
  def exceed_query_limit(limit)
    QueryLimitMatcher.new(limit)
  end

  # Time execution of a block
  def time_execution(&block)
    start_time = Time.current
    result = yield
    end_time = Time.current
    {
      result: result,
      duration: end_time - start_time
    }
  end

  # Expect operation to complete within time limit
  def expect_fast_execution(max_seconds = 1, &block)
    execution = time_execution(&block)
    expect(execution[:duration]).to be < max_seconds.seconds
    execution[:result]
  end

  # Memory usage tracking (simplified)
  def track_memory_usage(&block)
    GC.start
    memory_before = `ps -o rss= -p #{Process.pid}`.to_i
    result = yield
    GC.start
    memory_after = `ps -o rss= -p #{Process.pid}`.to_i
    {
      result: result,
      memory_used: memory_after - memory_before
    }
  end

  # Database query counting
  def count_queries(&block)
    query_count = 0
    callback = lambda do |*args|
      query_count += 1 unless args[0] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      yield
    end

    query_count
  end

  # Expect specific number of database queries
  def expect_query_count(expected_count, &block)
    actual_count = count_queries(&block)
    expect(actual_count).to eq(expected_count)
  end

  # Load testing helper for creating many records
  def create_load_test_data(factory_name, count = 100, **attributes)
    created_records = []
    count.times do |i|
      created_records << create(factory_name, attributes.merge(sequence_suffix: i))
    end
    created_records
  end

  # Performance benchmark helper
  def benchmark_operation(name, iterations = 10, &block)
    times = []
    iterations.times do
      execution = time_execution(&block)
      times << execution[:duration]
    end

    average_time = times.sum / times.size
    puts "\n=== Performance Benchmark: #{name} ==="
    puts "Iterations: #{iterations}"
    puts "Average time: #{average_time.round(4)}s"
    puts "Min time: #{times.min.round(4)}s"
    puts "Max time: #{times.max.round(4)}s"
    puts "================================\n"

    average_time
  end
end

# Custom query limit matcher
class QueryLimitMatcher
  def initialize(limit)
    @limit = limit
  end

  def matches?(block)
    @query_count = count_queries_for_block(block)
    @query_count <= @limit
  end

  def failure_message
    "expected at most #{@limit} queries, but #{@query_count} were executed"
  end

  def failure_message_when_negated
    "expected more than #{@limit} queries, but only #{@query_count} were executed"
  end

  def supports_block_expectations?
    true
  end

  private

  def count_queries_for_block(block)
    query_count = 0
    callback = lambda do |*args|
      query_count += 1 unless args[0] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      block.call
    end

    query_count
  end
end

RSpec.configure do |config|
  config.include PerformanceHelpers
end
