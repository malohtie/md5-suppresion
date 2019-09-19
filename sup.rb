#!/usr/bin/ruby

require 'rubygems'
require 'csv'
require 'trollop'
require 'digest/md5'


opts = Trollop::options do
    opt :email_csv, 'The path to the CSV file containing subscriber email addresses.',
        :short => 'e', :type => String,  :required => true

    opt :email_csv_column, 'The column in the subscriber CSV file containing email addresses.',
        :short => 'c', :type => Integer, :default => 1

    opt :hash_csv, 'The path to the CSV file of MD5 hashes.',
        :short => 'a', :type => String,  :required => true

    opt :output_directory, 'Path to where the output file should be saved.',
        :short => 'o', :type => String,  :default => '.'
end

opts[:output_directory].chop! if opts[:output_directory].end_with? '/'


puts 'Calculating email address hashes...'
email_hashes = {}
email_counter = 0
CSV.foreach(opts[:email_csv], skip_blanks: true, liberal_parsing: true) do |row|
	if !row[opts[:email_csv_column] - 1].nil? && !row[opts[:email_csv_column] - 1].empty?
		email = row[opts[:email_csv_column] - 1].chomp.downcase       # count from zero
		#puts "#{email}"
		hash  = Digest::MD5.hexdigest(email)
		#puts "#{hash}"
		email_hashes[hash] = email
		email_counter += 1
		# show progress
		puts "Calculating: #{email_counter}" if email_counter % 100000 == 0
	end
end

puts 'Matching against suppression list...'
blacklist_counter = 0
matching_counter  = 0

# open the suppression list and iterate over the hashes
hash_file = File.new(opts[:hash_csv], 'r')
while (hash = hash_file.gets)
	if !hash.nil? && !hash.empty?
		hash = hash.chomp
		unless email_hashes[hash].nil?
			blacklist_counter += 1
			puts "FOUND EMAIL DELETING : #{blacklist_counter} - #{email_hashes[hash]}"
			email_hashes.delete hash
		end
	end
    # show progress
    matching_counter += 1
    puts "Matching: #{matching_counter}" if matching_counter % 100000 == 0
end
hash_file.close

puts "SUP FILE ENDED"
# Flush the whitelist to disk
puts "WRITING EMAILS TO FILE"

File.open("#{opts[:output_directory]}/whitelist.csv", "w+") do |f|
	email_hashes.each do |element|
		puts "#{element[1]}"
		f.puts(element[1])
	end
end
puts "DONE...."
