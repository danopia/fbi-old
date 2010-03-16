class ReposController < Mustache
  attr_reader :project, :repo, :repos, :commits, :pages, :debug, :files
  
  def list captures, params, env
    @project = Project.from_slug captures.first
    @repos = @project.repos
  end
  
  def show captures, params, env
    @project = Project.from_slug captures.first
    @repo = @project.repo_by_id captures[1].to_i
		@repo_path = File.join(File.dirname(__FILE__), '..', 'repos', @repo.id.to_s)
    
    captures += ['tree', ''] if captures.size == 2
    
    if captures[2] == 'tree'
      @files = `cd #{@repo_path}; git ls-tree master:#{captures[3]}`.scan(/^(\d+)\s+([a-z]+)\s+([a-f0-9]+)\s+(.+)/).map do |parts|
        {:modes => parts[0], :type => parts[1], :hash => parts[2], :path => parts[3], parts[1].to_sym => true}
      end
    elsif captures[2] == 'blob'
      @debug = `cd #{@repo_path}; git show master:#{captures[3]}`
    end
  end
end
