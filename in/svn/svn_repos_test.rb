# Copyright (c) 2007 Tim Coulter
# 
# You are free to modify and use this file under the terms of the GNU LGPL.
# You should have received a copy of the LGPL along with this file.
# 
# Alternatively, you can find the latest version of the LGPL here:
#      
#      http://www.gnu.org/licenses/lgpl.txt
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

require 'svn_repos'
require 'test/unit'
require "fileutils"

class SvnReposTest < Test::Unit::TestCase

  TEST_REPOS = "./test_repo"
  
  def setup
    @repos = SvnRepos.create(TEST_REPOS)
    assert @repos.repos_path == TEST_REPOS
  end
  
  def teardown
    FileUtils.remove_dir(TEST_REPOS, true)
  end
  
  def test_simple_commit_and_contents_lookup
  
    assert_equal @repos.revision_count, @repos.youngest_revision  
    initial_revision_count = @repos.revision_count
    path = "/simple"
    data = "Yippee!"
    
    @repos.commit(path => data)
    
    assert_equal data, @repos.file_contents(path), "Data in repository did not match as expected."
    assert_equal initial_revision_count + 1, @repos.revision_count, "Wrong revision count"
    assert_equal @repos.revision_count, @repos.youngest_revision  
  end
  
  def test_commit_creates_directories
  
    initial_revision_count = @repos.revision_count
    path = "/this/is/a/path/to/a/file"
    data = "Some data."
    
    @repos.commit(path => data)
    
    assert_equal data, @repos.file_contents(path), "Data in repository did not match as expected."
    assert_equal initial_revision_count + 1, @repos.revision_count, "Wrong revision count"
  end
  
  def test_multiple_commit
  
    commit_list = {"/I/love/rock/and/roll" => "Livin' in the 80's!",
                    "/dentistfiles/patient1" => "He's got gum disease.",
                    "/damnit/Jim" => "I'm an engineer!"}
                  
    initial_revision_count = @repos.revision_count
    
    @repos.commit(commit_list)
    
    assert_equal initial_revision_count + 1, @repos.revision_count, "Wrong revision count"
    
    commit_list.each do |path, data|
      assert_equal data, @repos.file_contents(path), "Data in repository did not match as expected."
    end
  
  end
  
  def test_single_commit_saves_author
    
    path = "/my/favorite/movie/quote"
    data = "Hey Laserlips. Your mama was a snowblower."
    author = "shortcircuitlover1985"
    
    @repos.commit(path => data, :author => author)
    
    assert_equal author, @repos.property(:author, @repos.youngest_revision)
    
  end
  
  def test_history_with_single_path
  
    path = "/this/is/a/path"
    revision_ids = []
    
    @repos.commit(path => "first")
    revision_ids.push(@repos.youngest_revision)
    @repos.commit(path => "second")
    revision_ids.push(@repos.youngest_revision)
    @repos.commit(path => "third")
    revision_ids.push(@repos.youngest_revision)
    
    history = @repos.history(path)
    
    assert_equal revision_ids.length, history.length, "Different lengths."
    assert_equal revision_ids, history, "Wrong history returned."
    
  end
  
  def test_history_with_multiple_paths
  
    path1 = "/we/are/the/knights/who/say/ni"
    path2 = "/I/am/not/a/witch/I/am/not/a/witch"
    
    revision_ids = []
    
    @repos.commit(path1 => "What is your favorite color?")
    revision_ids.push(@repos.youngest_revision)
    
    @repos.commit(path2 => "Little small rocks!")
    revision_ids.push(@repos.youngest_revision)
    
    @repos.commit(path1 => "Logically...")
    revision_ids.push(@repos.youngest_revision)
    
    history = @repos.history([path1, path2])
    
    assert_equal revision_ids.length, history.length, "Different lengths."
    assert_equal revision_ids, history, "Wrong history returned."
  
  end

  def test_commit_with_block
    
    path1 = "/whos/my/dad"
    data1 = "Master Yoda, I must know. Is Darth Vader my father?"
    path2 = "/Im/all/parts"
    data2 = "They're going to execute Master Luke, and if we're not careful, us too. (Artoo beeps). I wish I had your confidence."
    path3 = "/only/walk/in/lighted/areas"
    data3 = "Once you start down the dark path, forever will it dominate your destiny."
    
    @repos.commit {|requests|
      requests[path1] = data1
      requests[path2] = data2
      requests[path3] = data3
    }
    
    assert_equal data1, @repos.file_contents(path1), "Data in repository did not match as expected."
    assert_equal data2, @repos.file_contents(path2), "Data in repository did not match as expected."
    assert_equal data3, @repos.file_contents(path3), "Data in repository did not match as expected."
  end
  
  def test_history_with_multiple_paths_and_multiple_commits
  
    path1 = "/we/are/the/knights/who/say/ni"
    path2 = "/I/am/not/a/witch/I/am/not/a/witch"
    
    revision_ids = []
    
    @repos.commit(path1 => "What is your favorite color?")
    revision_ids.push(@repos.youngest_revision)
    
    @repos.commit(path2 => "Little small rocks!", path1 => "This one isn't in the test above.")
    revision_ids.push(@repos.youngest_revision)
    
    @repos.commit(path1 => "Logically...")
    revision_ids.push(@repos.youngest_revision)
    
    history = @repos.history([path1, path2])
    
    # Even if two items were committed on the same commit, we should still only receive 
    # three results.
    assert_equal revision_ids.length, history.length, "Different lengths."
    assert_equal revision_ids, history, "Wrong history returned."
  
  end
  
  def test_youngest_revision_with_and_without_parameters
  
    first_path = "/first/path"
    second_path = "/second/path"
    
    commit_list = {first_path => "Some data.", second_path => "Other data."}
    
    # This first commit will make the revision number of both paths the same. 
    @repos.commit(commit_list)
    
    first_revision_number = @repos.youngest_revision
    
    # Now lets updated the second path, so each path has a different revision number.
    @repos.commit(second_path => "Word up.")
    
    second_revision_number = @repos.youngest_revision
    
    # Assert an assumption...
    assert first_revision_number != second_revision_number
    
    assert_equal first_revision_number, @repos.youngest_revision(first_path), "Wrong revision number: " + first_revision_number.to_s
    assert_equal second_revision_number, @repos.youngest_revision(second_path), "Wrong revision number: " + second_revision_number.to_s
    
  end
  
  def test_youngest_revision_on_a_nonsense_path
    
    path = "/oogily/googily"
    
    begin
      @repos.youngest_revision(path)
      fail "Should have thrown an error."
    rescue SvnPathNotFoundError => e
      # Do nothing. Test passed.
    end    
  end

end
