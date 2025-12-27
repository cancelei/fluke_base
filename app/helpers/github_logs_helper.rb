module GithubLogsHelper
  # Formats a Git patch string to look like GitHub's diff display
  # @param patch [String] The raw patch from GitHub API
  # @return [String] HTML-formatted diff with proper styling
  def format_github_diff(patch)
    return "" if patch.blank?
    
    # Convert escaped newlines to actual newlines
    formatted_patch = patch.gsub('\n', "\n")
    
    # Split into lines and process each line
    lines = formatted_patch.split("\n")
    html_lines = []
    
    current_block = []
    current_block_type = nil
    
    lines.each do |line|
      cleaned_line = line.strip.gsub(" ", "")
      next if cleaned_line.length == 0
      
      css_class = case line
                  when /^\+\+\+/
                    "diff-header"
                  when /^---/
                    "diff-header"
                  when /^@@/
                    "diff-hunk"
                  when /^\+/
                    "diff-added"
                  when /^-/
                    "diff-removed"
                  when /^ /
                    "diff-unchanged"
                  else
                    "diff-neutral"
                  end
      
      # Handle block grouping for added/removed lines
      if css_class == "diff-added" || css_class == "diff-removed"
        if current_block_type == css_class
          # Same type as current block, add to it
          current_block << line
        else
          # Different type, flush previous block and start new one
          if current_block.any?
            html_lines << "<div class=\"#{current_block_type}\">#{current_block.map { |l| h(l) }.join("\n")}</div>"
          end
          current_block = [line]
          current_block_type = css_class
        end
      else
        # Not an added/removed line, flush any existing block
        if current_block.any?
          html_lines << "<div class=\"#{current_block_type}\">#{current_block.map { |l| h(l) }.join("\n")}</div>"
          current_block = []
          current_block_type = nil
        end
        
        # Handle other line types normally
        escaped_line = h(line)
        html_lines << "<div class=\"#{css_class}\">#{escaped_line}</div>"
      end
    end
    
    # Flush any remaining block
    if current_block.any?
      html_lines << "<div class=\"#{current_block_type}\">#{current_block.map { |l| h(l) }.join("\n")}</div>"
    end
    
    html_lines.join("\n")
  end
end
