require 'time'

require 'bluecloth'

require 'octopi'
include Octopi

class WikiController < Controller
  attr_reader :project, :title, :contents, :pages, :commits, :commit
  
  def fetch_repo repo
    remote = repo.clone_url.sub('github.com', 'fbi_gh')
    
    Dir.chdir File.dirname(@repo) do
      `git clone --bare #{remote} #{@project.slug}`
    end
    
    Dir.chdir @repo do
      `git remote add origin #{remote}`
    end
  end
  
  def create_repo
    repo = Repository.create :name => @project.slug
    remote = repo.clone_url.sub('github.com', 'fbi_gh')
    
    system 'mkdir', @repo
    
    Dir.chdir @repo do
      `git init --bare`
      
      IO.popen('git hash-object -w --path index.md --stdin', 'w+') do |io|
        io.puts "This is the wiki for #{@project.title}."
        io.close_write
        $blob = io.gets.chomp
      end
      
      IO.popen('git hash-object -w --path README --stdin', 'w+') do |io|
        io.puts "This is the FBI wiki repo for #{@project.title}."
        io.puts
        io.puts "This repo is used to allow flexible editing of the wiki."
        io.close_write
        $blob2 = io.gets.chomp
      end
      
      IO.popen('git mktree', 'w+') do |io|
        io.puts "100644 blob #{$blob}	index.md"
        io.puts "100644 blob #{$blob2}	README"
        io.close_write
        $tree = io.gets.chomp
      end
      
      IO.popen("git commit-tree #{$tree}", 'w+') do |io|
        io.puts "Initial commit"
        io.close_write
        $commit = io.gets.chomp
      end
      
      `git update-ref refs/heads/master #{$commit}`
      
      `git remote add origin #{remote}`
      `git push origin master`
    end
  end
  
  def pull
    Dir.chdir @repo do
      `git fetch origin master:refs/heads/master`
    end
  end
  
  def setup project
    @pages = []
    
    @project = Project.find :slug => project
    @repo = File.join(File.dirname(__FILE__), '..', 'wikis', @project.slug)
    
    return unless @project.slug
    
    if File.directory? @repo
      #pull
    else
      config = File.open('github_auth.yaml') { |yf| YAML::load(yf) }
      config.each_pair {|key, val| config[key.to_sym] = val }
      authenticated_with config do
        begin
          fetch_repo Repository.find(:name => @project.slug, :user => Api.api.login)
        rescue Octopi::APIError
          create_repo
        end
      end
    end
    
    Dir.chdir @repo do
      `git ls-tree master`.each_line do |line|
        line.chomp!
        
        @pages << {:title => line.split.last.sub('.md', '')} if line.include? '.md'
      end
    end
  end
  
  def edit captures, params, env
    setup captures.first
    
    @title = captures[1]
    Dir.chdir @repo do
      @contents = `git show master:#{captures[1]}.md`
    end
  end
  
  def new captures, params, env
    setup captures.first
    
    return if env['REQUEST_METHOD'] != 'POST'
    
    pull
    
    data = CGI.parse(env['rack.input'].read)
    contents = data['contents'].first
    message = data['message'].first
    @title = data['title'].first
    
    path = "#{@title}.md"
    
    Dir.chdir @repo do
      # pull
      
      IO.popen("git hash-object -w --path #{path} --stdin", 'w+') do |io|
        io.puts contents
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
      
      IO.popen("export GIT_AUTHOR_NAME=#{env['REMOTE_ADDR']}; export GIT_AUTHOR_EMAIL=www@fbi.danopia.net; export GIT_COMMITTER_EMAIL=wikis@fbi.danopia.net; export GIT_COMMITTER_NAME=FBI; git commit-tree #{$tree} -p #{previous}", 'w+') do |io|
        io.puts message
        io.close_write
        $commit = io.gets.chomp
      end
      
      `git update-ref refs/heads/master #{$commit} #{previous}`
      `git push origin master`
    end
    
    @title = path.sub('.md', '')
    @contents = BlueCloth.new(contents).to_html
    
    render :path => 'wiki/show'
  end
  
  def save captures, params, env
    return edit(captures, params, env) unless env['REQUEST_METHOD'] == 'POST'
    
    setup captures.first
    pull
    
    @title = captures[1]
    
    data = CGI.parse(env['rack.input'].read)
    contents = data['contents'].first
    message = data['message'].first
    
    path = "#{captures[1]}.md"
    
    Dir.chdir @repo do
      # pull
      
      IO.popen("git hash-object -w --path #{path} --stdin", 'w+') do |io|
        io.puts contents
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
      
      IO.popen("export GIT_AUTHOR_NAME=#{env['REMOTE_ADDR']}; export GIT_AUTHOR_EMAIL=www@fbi.danopia.net; export GIT_COMMITTER_EMAIL=wikis@fbi.danopia.net; export GIT_COMMITTER_NAME=FBI; git commit-tree #{$tree} -p #{previous}", 'w+') do |io|
        io.puts message
        io.close_write
        $commit = io.gets.chomp
      end
      
      `git update-ref refs/heads/master #{$commit} #{previous}`
      `git push origin master`
    end
    
    @title = path.sub('.md', '')
    @contents = BlueCloth.new(contents).to_html
    
    render :path => 'wiki/show'
  end
  
  def index captures, params, env
    captures[1] = 'index'
    show captures, params, env
  end
  
  def show captures, params, env
    setup captures.first
    
    @title = captures[1]
    
    Dir.chdir @repo do
      @contents = `git show master:#{captures[1]}.md`
      @contents = BlueCloth.new(@contents).to_html
    end
    
  end
  
  def history captures, params, env
    setup captures.first
    
    @title = captures[1]
    @contents = ''
    Dir.chdir @repo do
      `git log --oneline -- #{captures[1]}.md`.each_line do |line|
        id, message = line.split(' ', 2)
        @contents << "  * [#{message}](../commits/#{id})\n"
      end
    end
    @contents = BlueCloth.new(@contents).to_html
  end
  
  def commits captures, params, env
    setup captures.first

    Dir.chdir @repo do
      contents = `git show #{captures[1]}`
      
      @commit = {}
      @commit[:hash] = captures[1]
      
      author = contents.match(/^Author: (.+) \<(.+)\>$/).captures
      @commit[:author] = {:name => author[0], :mail => author[1]}
      
      date = contents.match(/^Date:\W+(.+)$/).captures.first
      @commit[:date] = Time.parse(date).utc.strftime('%B %d, %Y')
      
      message_start = contents.index("\n\n") + 2
      message_end = contents.index("\n\n", message_start) - 1
      @commit[:message] = contents[message_start..message_end]
      
      @commit[:files] = contents.split("\ndiff")
      @commit[:files].shift
      @commit[:files].map! do |raw|
        file = raw.match(/^\+\+\+ b\/(.+)$/).captures.first
        {:path => file.sub('.md', ''), :diff => raw[raw.index('@@')..-1]}
      end
    end
  end
end
