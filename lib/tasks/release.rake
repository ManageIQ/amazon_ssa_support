namespace :release do
  desc "Tasks to run on a new branch when a new branch is created"
  task :new_branch do
    require 'pathname'

    branch = ENV["RELEASE_BRANCH"]
    if branch.nil? || branch.empty?
      STDERR.puts "ERROR: You must set the env var RELEASE_BRANCH to the proper value."
      exit 1
    end

    current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
    if current_branch == "master"
      STDERR.puts "ERROR: You cannot do new branch tasks from the master branch."
      exit 1
    end

    root = Pathname.new(__dir__).join("../..")

    # Modify Gemfile
    gemfile = root.join("Gemfile")
    content = gemfile.read
    gemfile.write(content.gsub(/(:branch => ")[^"]+(")/, "\\1#{branch}\\2"))

    # Commit
    files_to_update = [gemfile]
    exit $?.exitstatus unless system("git add #{files_to_update.join(" ")}")
    exit $?.exitstatus unless system("git commit -m 'Changes for new branch #{branch}'")

    puts
    puts "The commit on #{current_branch} has been created."
    puts "Run the following to push to the upstream remote:"
    puts
    puts "\tgit push upstream #{current_branch}"
    puts
  end
end
