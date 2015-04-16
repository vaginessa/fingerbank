
namespace :users do |ns|
  task :list do
    puts 'all tasks:'
    puts ns.tasks
  end

  task :create, [:name,:email] => [:environment] do |t, args|
    if args[:name].nil? || args[:email].nil?
      puts "Missing name or e-mail"
      next
    end
    puts "Creating user : #{args[:name]} with e-mail #{args[:email]}"

    User.create!(:name => "local.#{args[:name]}", :email => args[:email])
  end

end
