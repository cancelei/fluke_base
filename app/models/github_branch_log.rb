class GithubBranchLog < ApplicationRecord
    belongs_to :github_branch
    belongs_to :github_log
end
