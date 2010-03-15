class WikiController < Mustache
  attr_reader :project, :page, :pages, :editing, :viewing
  
  def setup project
    @pages = []
    
    @project = Project.from_slug project
    @repo = File.join(File.dirname(__FILE__), '..', 'wikis', @project.slug)
    
    unless File.directory? @repo
      system 'mkdir', @repo
      
      Dir.chdir @repo do
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
    
    Dir.chdir @repo do
      `git ls-tree master`.each_line do |line|
        line.chomp!
        
        page = Page.new
        page.title = line.split.last.sub('.md', '')
        @pages << page
      end
    end
  end
  
  def edit captures, params, env
    setup captures.first
    
    @editing = true
    @page = Page.new
    @page.title = captures[1]
    Dir.chdir @repo do
      @page.contents = `git show master:#{captures[1]}.md`
    end
  end
  
  def save captures, params, env
    setup captures.first
    
    @editing = true
    @page = Page.new
    @page.title = captures[1]
    
    data = env['rack.input'].read
    data = CGI::unescape(data[9..-1])
    
    path = "#{captures[1]}.md"
    
    Dir.chdir @repo do
      
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
      previous = previous[0, previous.index("\n")]
      
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
    Dir.chdir @repo do
      @page.contents = `git show master:#{path}`
    end
  end
  
  def index captures, params, env
    captures[1] = 'index'
    show captures, params, env
  end
  
  def show captures, params, env
    setup captures.first
    
    @viewing = true
    @page = Page.new
    @page.title = captures[1]
    Dir.chdir @repo do
      @page.contents = `git show master:#{captures[1]}.md`
    end
  end
  
  def history captures, params, env
    setup captures.first
    
    @viewing = true
    @page = Page.new
    @page.title = captures[1] + ' history'
    @page.contents = ''
    Dir.chdir @repo do
      `git log --oneline -- #{captures[1]}.md`.each_line do |line|
        id, message = line.split(' ', 2)
        @page.contents << "  * [#{message}](../commits/#{id})\n"
      end
    end
  end
  
  def commits captures, params, env
    setup captures.first

    @viewing = true
    @page = Page.new
    @page.title = "Commit #{captures[1]}"
    Dir.chdir @repo do
      @page.contents = `git show #{captures[1]}`
    end
  end
end
