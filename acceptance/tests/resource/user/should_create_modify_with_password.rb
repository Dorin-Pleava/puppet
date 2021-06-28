# frozen_string_literal: true

test_name 'should create a user with password and modify the password' do

  tag 'audit:high',
      'audit:acceptance' # Could be done as integration tests, but would
  # require changing the system running the test
  # in ways that might require special permissions
  # or be harmful to the system running the test

  skip_test 'on Windows and OSX, we cannot check passwords from `puppet resource user user_name`' if agents.any? {|agent| agent['platform'] =~ /(windows|osx)/ }
  
  name = "pl#{rand(999_999).to_i}"
  initial_password = 'Gérard'
  modified_password = 'Gérard1'

  agents.each do |agent|
    teardown do
      on(agent, puppet('resource', 'user', name, 'ensure=absent'))
    end

    step 'ensure the user does not exist'
    agent.user_absent(name)

    step 'create the user with password' do
      apply_manifest_on(agent, <<-MANIFEST, catch_failures: true)
          user { '#{name}':
            ensure => present,
            password => '#{initial_password}',
          }
        MANIFEST
    end

    step 'verify the password was set correctly' do
      on(agent, puppet('resource', 'user', name), acceptable_exit_codes: 0) do
        assert_match(/password\s*=>\s*'#{initial_password}'/, stdout, 'Password was not set correctly')
      end
    end

    step 'modify the user with a different password' do
      apply_manifest_on(agent, <<-MANIFEST, catch_failures: true)
	    user { '#{name}':
	      ensure => present,
	      password => '#{modified_password}',
	    }
	MANIFEST
    end

    step 'verify the password was set correctly' do
      on(agent, "puppet resource user #{name}", acceptable_exit_codes: 0) do
        assert_match(/password\s*=>\s*'#{modified_password}'/, stdout, 'Password was not changed correctly')
      end
    end
  end
end
