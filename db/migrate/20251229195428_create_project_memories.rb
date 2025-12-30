class CreateProjectMemories < ActiveRecord::Migration[8.0]
  def change
    create_table :project_memories do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :memory_type, null: false, default: "fact"
      t.text :content, null: false
      t.string :key  # for conventions only
      t.text :rationale  # for conventions only
      t.jsonb :tags, default: []
      t.jsonb :references, default: {}  # links to files, commits, etc.
      t.string :external_id  # UUID from flukebase_connect
      t.datetime :synced_at

      t.timestamps

      t.index %i[project_id memory_type]
      t.index %i[project_id key], unique: true, where: "key IS NOT NULL"
      t.index :external_id, unique: true, where: "external_id IS NOT NULL"
    end

    # Add check constraint for memory_type
    execute <<~SQL
      ALTER TABLE project_memories
      ADD CONSTRAINT project_memories_memory_type_check
      CHECK (memory_type IN ('fact', 'convention', 'gotcha', 'decision'))
    SQL
  end
end
