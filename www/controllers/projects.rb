class ProjectsController < Mustache
  attr_reader :project, :projects, :repo, :repos, :commits, :page, :pages, :editing, :viewing
  
  def do_main env, path
    @projects = Project.all
  end
  
  def do_show env, path
    @project = Project.from_slug path.first
  end
  
  def do_pages env, path
    @pages = []
    
    @project = Project.from_slug path.first
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
        @pages << page
      end
    end
    
    case path[2]
    
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
        @page.title = path[3..-1].join('/')
        Dir.chdir repo do
          @page.contents = `git show master:#{path[3..-1].join('/')}.md`
        end
      
      when 'save'
        @editing = true
        @page = Page.new
        @page.title = path[3..-1].join('/')
        
        data = env['rack.input'].read
        data = CGI::unescape(data[9..-1])
        
        Dir.chdir repo do
          path = "#{path[3..-1].join('/')}.md"
          
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
        @page.title = path[3..-1].join('/')
        Dir.chdir repo do
          @page.contents = `git show master:#{path[3..-1].join('/')}.md`
        end
    end
  end
  
  def do_repos env, path
    @project = Project.from_slug path.first
    @repo = @project.repo_by_id path[2].to_i
  end
  
  def do_commits env, path
    @project = Project.from_slug path.first
    
    if path.size == 2 || path[2] != 'repos'
      @repos = @project.repos
    else
      @repo = @project.repo_by_id path[3].to_i
      @repos = [@repo]
    end
    
    if path.size > 2 && path[2] == 'authors'
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }, :author => CGI::unescape(path[3])).reverse_order(:committed_at).all
    else
      @commits = Commits.filter(:repo_id => @repos.map{|r| r.id }).reverse_order(:committed_at).all
    end
    
    @commits.map! do |commit|
      Commit.new commit
    end
  end
end
