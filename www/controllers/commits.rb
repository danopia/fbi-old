class CommitsController < Controller
  attr_reader :project, :repo, :author, :repos, :commits
  
  def list captures, params, env
    @project = Project.find :slug => captures.first
    
    if params[:mode] == 'repo'
      @repo = @project.repo_by_id captures[1].to_i
      @repos = [@repo]
    else
      @repos = @project.repos
    end
    
    if params[:mode] == 'author'
      @author = CGI::unescape captures[1]
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }, :author => @author).reverse_order(:committed_at).all
    else
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }).reverse_order(:committed_at).all
    end
    
    @commits.map! do |commit|
      Commit.new commit
    end
  end
end
