task :mutant do
  classes_to_mutate.each do |klass|
    vars = 'NOCOVERAGE=true'
    flags = '--include lib --use rspec'
    unless system("#{vars} mutant #{flags} #{klass}")
      raise 'Mutation testing failed'
    end
  end
end

task(:default).prerequisites << task(:mutant)

private

def classes_to_mutate
  files = grep_files_for_classes
  klasses = extract_classes_for_mutation(files)
  klasses.map { |k|
    setup_class_for_run(k)
  }
end

# This is a nasty hack because we’re using POROs; otherwise, we could just use
# ApplicationRecord.descendants...
#
# Grepping through the source code seemed to be the most pragmatic solution
# so that developers don’t need to remember to add new classes to a list for
# mutation testing, but it’s not ideal
def grep_files_for_classes
  Dir.glob('lib/**/*.rb').
    map { |f|
    # There are some examples of `class << self` in codebase.
    File.readlines(f).grep(/\bclass(?!\s<<)/)
  }.flatten
end

def extract_classes_for_mutation(files)
  re = /class (?<klass>\w+)/

  files.map { |s|
    re.match(s)[:klass]
  }.compact
end

def setup_class_for_run(klass)
  Object.const_get(klass)
rescue NameError
  Object.const_get("GlimrApiClient::#{klass}")
end
