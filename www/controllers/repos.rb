class ReposController < Mustache
  attr_reader :project, :repo, :repos, :commits, :pages, :debug, :files, :filename, :parent
  
  def list captures, params, env
    @project = Project.from_slug captures.first
    @repos = @project.repos
  end
  
  def tree captures, params, env
    @project = Project.from_slug captures.first
    @repo = @project.repo_by_id captures[1].to_i
		@repo_path = File.join(File.dirname(__FILE__), '..', 'repos', @repo.id.to_s)
    
    captures += [''] if captures.size == 2
    
    root = (captures[2] == '') ? '' : "#{captures[2]}/"
    @parent = File.dirname captures[2] if captures[2] != ''
    
    @files = `cd #{@repo_path}; git ls-tree master:#{captures[2]}`.scan(/^(\d+)\s+([a-z]+)\s+([a-f0-9]+)\s+(.+)/).map do |parts|
      {:modes => parts[0], :type => parts[1], :hash => parts[2], :path => "#{root}#{parts[3]}", :name => parts[3], parts[1].to_sym => true}
    end
  end
  
  def blob captures, params, env
    @project = Project.from_slug captures.first
    @repo = @project.repo_by_id captures[1].to_i
		@repo_path = File.join(File.dirname(__FILE__), '..', 'repos', @repo.id.to_s)
    
    @filename = captures[2]
    @parent = File.dirname @filename
    @debug = `cd #{@repo_path}; git show master:#{captures[2]}`
  end
end
