class CreateAiProductivityStats < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW ai_productivity_stats AS
      SELECT
        project_id,
        COALESCE(SUM((metric_data->>'time_saved_minutes')::numeric), 0) as total_time_saved_minutes,
        COALESCE(SUM((metric_data->>'lines_added')::integer), 0) as total_lines_added,
        COALESCE(SUM((metric_data->>'lines_removed')::integer), 0) as total_lines_removed,
        COALESCE(SUM((metric_data->>'files_changed')::integer), 0) as total_files_changed,
        COALESCE(SUM((metric_data->>'total_commits')::integer), 0) as total_commits,
        COALESCE(AVG((metric_data->>'completion_rate')::numeric), 0) as avg_task_completion_rate,
        COALESCE(SUM((metric_data->>'completed_count')::integer), 0) as total_tasks_completed,
        COALESCE(SUM((metric_data->>'total_tokens')::integer), 0) as total_tokens_used,
        COALESCE(SUM((metric_data->>'estimated_cost_usd')::numeric), 0) as total_estimated_cost,
        COUNT(DISTINCT DATE(period_start)) as active_days,
        MIN(period_start) as first_activity_at,
        MAX(period_end) as last_activity_at,
        NOW() as calculated_at
      FROM ai_productivity_metrics
      GROUP BY project_id;
    SQL

    execute <<-SQL
      CREATE UNIQUE INDEX idx_ai_productivity_stats_project
      ON ai_productivity_stats(project_id);
    SQL
  end

  def down
    execute "DROP MATERIALIZED VIEW IF EXISTS ai_productivity_stats"
  end
end
