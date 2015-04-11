module Contracts

	def assert(expected,actual,message)
		if expected != actual
			puts 'contract failed. Expected ' + expected.to_s + "\nGot " + actual.to_str + "\n" + message
		end
	end

	def assert_not_equal(expected,actual,message)
		if expected == actual
			puts 'contract failed. Expected not ' + expected.to_s + "\nGot " + actual.to_str + "\n" + message
		end
	end

end
