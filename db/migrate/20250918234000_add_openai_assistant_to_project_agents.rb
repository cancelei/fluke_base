class AddOpenaiAssistantToProjectAgents < ActiveRecord::Migration[8.0]
  def change
    return unless table_exists?(:project_agents)

    add_column :project_agents, :openai_assistant_id, :string
    add_index  :project_agents, :openai_assistant_id, unique: true, where: "openai_assistant_id IS NOT NULL"
  end
end
