module Contracts

	def assert_true(expected,message)
		if !expected
			puts 'contract failed. Expected value to be false. Instead it was: ' + expected.to_s + "\n" + message
		end
	end

	def assert_equal(expected,actual,message)
		if expected != actual
			puts 'contract failed. Expected ' + expected.to_s + "\nGot " + actual.to_s + "\n" + message
		end
	end

	def assert_not_equal(expected,actual,message)
		if expected == actual
			puts 'contract failed. Expected not ' + expected.to_s + "\nGot " + actual.to_s + "\n" + message
		end
	end

end
