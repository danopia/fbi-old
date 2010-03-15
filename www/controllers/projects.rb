class ProjectsController < Mustache
  attr_reader :project, :projects, :repo, :repos, :commits2, :page, :pages2, :editing, :viewing
  
  def main captures, params, env
    @projects = Project.all
  end
  
  def show captures, params, env
    @project = Project.from_slug captures.first
  end
  
  def pages captures, params, env
    @pages2 = []
    
    @project = Project.from_slug captures.first
    repo = File.join(File.dirname(__FILE__), '..', 'wikis', @project.slug)
    
    unless File.directory? repo
      system 'mkdir', repo
      
      Dir.chdir repo do
        `git init --bare`
        
        IO.popen('git hash-object -w --path index.md --stdin', 'w+') do |io|
          io.puts "This is the wiki for #{@project.title}."
          io.close_write
          $blob = io.gets.chomp
        end
        
        IO.popen('git mktree', 'w+') do |io|
          io.puts "100644 blob #{$blob}	index.md"
          io.close_write
          $tree = io.gets.chomp
        end
        
        IO.popen("git commit-tree #{$tree}", 'w+') do |io|
          io.puts "Initial commit"
          io.close_write
          $commit = io.gets.chomp
        end
        
        puts `git update-ref refs/heads/master #{$commit}`
      end
    end
    
    Dir.chdir repo do
      `git ls-tree master`.each_line do |line|
        line.chomp!
        
        page = Page.new
        page.title = line.split.last.sub('.md', '')
        @pages2 << page
      end
    end
    
    case captures[1]
    
      #~ when nil
        #~ Dir.chdir repo do
          #~ `git ls-tree master`.each_line do |line|
            #~ line.chomp!
            #~ 
            #~ page = Page.new
            #~ page.title = line.split.last.sub('.md', '')
            #~ @pages << page
          #~ end
        #~ end
      
      when 'edit'
        @editing = true
        @page = Page.new
        @page.title = captures[2]
        Dir.chdir repo do
          @page.contents = `git show master:#{captures[2]}.md`
        end
      
      when 'save'
        @editing = true
        @page = Page.new
        @page.title = captures[2]
        
        data = env['rack.input'].read
        data = CGI::unescape(data[9..-1])
        
        path = "#{captures[2]}.md"
        
        Dir.chdir repo do
          
          IO.popen("git hash-object -w --path #{path} --stdin", 'w+') do |io|
            io.puts data
            io.close_write
            $blob = io.gets.chomp
          end
          
          IO.popen('git mktree', 'w+') do |io|
            `git ls-tree master`.each_line do |line|
              io.puts line unless line =~ /#{path}$/
            end
            io.puts "100644 blob #{$blob}	#{path}"
            io.close_write
            $tree = io.gets.chomp
          end
          
          previous = `git show --format=format:%H`
          
          IO.popen("git commit-tree #{$tree} -p #{previous}", 'w+') do |io|
            io.puts "Updated via website"
            io.close_write
            $commit = io.gets.chomp
          end
          
          `git update-ref refs/heads/master #{$commit} #{previous}`
        end
        
        @viewing = true
        @page = Page.new
        @page.title = path.sub('.md', '')
        Dir.chdir repo do
          @page.contents = `git show master:#{path}`
        end
      
      when 'show'
        @viewing = true
        @page = Page.new
        @page.title = captures[2]
        Dir.chdir repo do
          @page.contents = `git show master:#{captures[2]}.md`
        end
      
      when 'history'
        @viewing = true
        @page = Page.new
        @page.title = captures[2] + ' history'
        @page.contents = ''
        Dir.chdir repo do
          `git log --oneline -- #{captures[2]}.md`.each_line do |line|
            id, message = line.split(' ', 2)
            @page.contents << "  * [#{message}](../commits/#{id})\n"
          end
        end
      
      when 'commits'
        @viewing = true
        @page = Page.new
        @page.title = "Commit #{captures[2]}"
        Dir.chdir repo do
          @page.contents = `git show #{captures[2]}`
        end
    end
  end
  
  def repos captures, params, env
    @project = Project.from_slug captures.first
    @repo = @project.repo_by_id captures[1].to_i
  end
  
  def commits captures, params, env
    @project = Project.from_slug captures.first
    
    if params[:mode] == 'repo'
      @repo = @project.repo_by_id captures[1].to_i
      @repos = [@repo]
    else
      @repos = @project.repos
    end
    
    if params[:mode] == 'author'
      @commits2 = Commits.filter(:repo_id => @repos.map{|r| r.id }, :author => CGI::unescape(captures[1])).reverse_order(:committed_at).all
    else
      @commits2 = Commits.filter(:repo_id => @repos.map{|r| r.id }).reverse_order(:committed_at).all
    end
    
    @commits2.map! do |commit|
      Commit.new commit
    end
  end
end
