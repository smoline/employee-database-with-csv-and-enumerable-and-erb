require 'csv'
require 'awesome_print'
require 'erb'

class Person
  attr_reader "name", "phone", "address", "position", "salary", "slack", "github"

  def initialize(name, phone, address, position, salary, slack, github)
    @name = name
    @phone = phone
    @address = address
    @position = position
    @salary = salary
    @slack = slack
    @github = github
  end
end

class MyDatabase
  EMPLOYEES_FILE = "employees.csv"

  def initialize
    @people = []
    CSV.foreach(EMPLOYEES_FILE, headers: true) do |row|
      name = row["name"]
      phone = row['phone']
      address = row["address"]
      position = row["position"]
      salary = row["salary"]
      slack = row["slack"]
      github = row["github"]

      person = Person.new(name, phone, address, position, salary, slack, github)

      @people << person
    end
  end

  def ask_question
    puts "What would you like to do?"
    puts "A to Add an Employee"
    puts "S to Search for an Employee"
    puts "D to Delete an Employee"
    puts "R to see a Report of all Employees"
    puts "Or just press enter to exit."
    choice = gets.chomp
    return choice.upcase
  end

  def add_person
    found_name = nil
    puts "What is the person's name?"
    name = gets.chomp
    found_name = @people.find { |person| person.name == name }
    if found_name
      puts "That Employee already exists.\n\n"
    elsif name.empty?
      puts "Name can not be blank"
    else
      puts "What is their phone number?"
      phone = gets.chomp

      puts "What is their address?"
      address = gets.chomp

      puts "What is their position?"
      position = gets.chomp

      puts "What is their salary?"
      salary = gets.chomp.to_i

      puts "What is their Slack account?"
      slack = gets.chomp

      puts "What is their GitHub account?"
      github = gets.chomp

      person = Person.new(name, phone, address, position, salary, slack, github)

      puts "You have added #{name}."
      puts "#{name}\'s phone number is #{phone}."
      puts "#{name} lives at #{address}."
      puts "Their position with the company is #{position} and they make $#{salary} a year."
      puts "Their Slack account is #{slack}."
      puts "Their GitHub account is #{github}.\n\n"

      @people << person

      save_database
    end
  end

  def search_for_person
    print "Please enter the person's name, Slack Account, or Github Account: "
    search_name = gets.chomp
    found_name = @people.find { |person| person.name == search_name || person.slack == search_name || person.github == search_name || person.name.include?(search_name) }
    if found_name
      puts "Search Results:"
      puts "Name: #{found_name.name}"
      puts "Phone: #{found_name.phone}"
      puts "Address: #{found_name.address}"
      puts "Position: #{found_name.position}"
      puts "Salary: $#{found_name.salary}"
      puts "Slack: #{found_name.slack}"
      puts "GitHub: #{found_name.github}\n\n"
    else
      puts "That person does not exist.\n\n"
    end
  end

  def delete_person
    print "Please enter the name of the person you want to delete: "
    delete_name = gets.chomp
    if @people.any? { |person| person.name == delete_name }
      @people.delete_if { |person| person.name == delete_name || person.slack == delete_name || person.github == delete_name }
      puts "#{delete_name} has been deleted.\n\n"
    else
      puts "That person does not exist.\n\n"
    end
    save_database
  end

  def people_by_position
    people_by_position = @people.group_by { |person| person.position }
    return people_by_position
  end

  def total_salary_by_position
    people_by_position
    salary_by_position = people_by_position.map { |position,people_for_position| [position, people_for_position.collect { |person| person.salary.to_i }.sum] }
    return salary_by_position
  end

  def total_by_position
    people_by_position
    results = people_by_position.map {|key,value| [key,value.count]}.to_h
    return results
  end

  def report_choice
    puts "How would you like your report?"
    puts "1. To view on your screen"
    puts "2. To print to an text file"
    puts "3. To print to an HTML file"
    r_choice = gets.chomp
    return r_choice
  end

  def employee_report_console
    @people.each do |person|
      printf("%-10s%-30s%12s\n%10s%-33s$%8d\n%10s%-30s%12s\n\n", "#{person.name}", "#{person.address}", "#{person.phone}", " ", "#{person.position}", "#{person.salary}", " ", "#{person.slack}", "#{person.github}")
    end
    salary_total = total_salary_by_position
    printf("%30s\n", "Total Salaries by Position:")
    salary_total.each do |position,salary|
      printf("%10s%20s%6s$%9d\n", " ", "#{position}:", " ", "#{salary}")
    end
    printf("\n")
    results = total_by_position
    printf("%30s\n", "Total Employees by Position:")
    results.each do |position,count|
      printf("%10s%20s%16d\n", " ", "#{position}:", "#{count}")
    end
    puts "End of Report\n\n"
  end

  def employee_report_text_file
    File.open("employee-report.txt", "w") do |text|
      text.printf("Employee Report\n\n")
      @people.each do |person|
        text.printf("%-10s%-30s%12s\n%10s%-33s$%8d\n%10s%-30s%12s\n\n", "#{person.name}", "#{person.address}", "#{person.phone}", " ", "#{person.position}", "#{person.salary}", " ", "#{person.slack}", "#{person.github}")
      end
      salary_total = total_salary_by_position
      text.printf("%30s\n", "Total Salaries by Position:")
      salary_total.each do |position,salary|
        text.printf("%10s%20s%6s$%9d\n", " ", "#{position}:", " ", "#{salary}")
      end
      text.printf("\n")
      results = total_by_position
      text.printf("%30s\n", "Total Employees by Position:")
      results.each do |position,count|
        text.printf("%10s%20s%16d\n", " ", "#{position}:", "#{count}")
      end
      text.puts "End of Report\n\n"
    end
    puts "Saving Text file...\n\n"
  end

  def employee_report_html
    template_string = File.read("report.html.erb")

    erb_template = ERB.new(template_string)
    html = erb_template.result(binding)

    File.write("report.html", html)

    puts "Saving HTML file...\n\n"
  end

  def employee_report
    r_choice = report_choice
    if r_choice == "1"
      employee_report_console
    elsif r_choice == "2"
      employee_report_text_file
    elsif r_choice == "3"
      employee_report_html
    else
      puts "That is not one of the choices.\n\n"
    end
  end

  def save_database
    CSV.open(EMPLOYEES_FILE, "w") do |csv|
      csv << ["name", "phone", "address", "position", "salary", "slack", "github"]
      @people.each do |person|
        csv << [person.name, person.phone, person.address, person.position, person.salary, person.slack, person.github]
      end
    end
  end

  def start
    choice = ()
    while choice != ""
      choice = ask_question
      if choice == "A"
        add_person
      elsif choice == "S"
        search_for_person
      elsif choice == "D"
        delete_person
      elsif choice == "R"
        employee_report
      else
        puts "Saving and exiting...\n\n"
        save_database
      end
    end
  end
end

MyDatabase.new.start
