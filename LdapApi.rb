
require 'rubygems'
require 'net/ldap'
require 'yaml'

class LdapUser
  
#  attr_reader :lda
  
  def get_yaml_values
    d= YAML.load_file('LdapApi.yml')
     @lda_host= d['connection_values']['host']
     @lda_port= d['connection_values']['port']
     
     @auth_dn= d['auth_values']['auth_dn']
     @auth_pwd= d['auth_values']['auth_pwd']
     
     @users_suffix= d['base_value']['users_suffix']
     @root_suffix= d['base_value']['root_suffix']
  end

   def create_connection
     @lda = Net::LDAP.new
     @lda.host = @lda_host
     @lda.port = @lda_port
     puts "****** Conncection result ********"
     puts @lda.get_operation_result 
     @lda
    
   end
  
  
  def authenticate
    @lda.authenticate "#{@auth_dn}","#{@auth_pwd}"   # only admin is able to authenticate
    puts "******* authentication result ********"

    if @lda.bind
     # puts ' authentication success'
      puts @lda.get_operation_result 
    else
     # puts 'authentication failed'
      puts @lda.get_operation_result 
    end   
  end

  
  # Takes first name, last name and password
  # already existing error when trying to add a user with same cn
  def create_user 
    
    if ARGV
       ARGV.each do |arg|
         @firstname = ARGV[0]
         @lastname=ARGV[1]
         @password = ARGV[2]
       end
     end  

    dn = "cn=#{@firstname}, #{@users_suffix}"
     attr = {
       :objectClass => 'inetOrgPerson',
       :cn=> @firstname,
       :sn => @lastname,
       :userPassword => @password
            }
    @lda.add(:dn => dn, :attributes => attr) 
    puts "********** create user result **********"
    puts @lda.get_operation_result   
  end
  
  #directly replaces existing password with given new value
  #future enhancements - ask for current password and check if that password exists in database
  def change_password
   
    if ARGV
       ARGV.each do |arg|
         @firstname = ARGV[0]
         @password=ARGV[1]
         @new_password = ARGV[2]
       end
     end  
    filter = Net::LDAP::Filter.eq( "cn","#{@firstname}" ) & Net::LDAP::Filter.eq( "userPassword", "#{@password}" )
   @lda.search( :base => "#{@root_suffix}", :filter =>filter, :return_result => true ) do |entry|
      if entry.dn
        @flag = true
      else 
        @flag = false
      end
   end
   #puts @flag if @flag
    
    # if credentials are correct
     puts "******** change password result *************"
    if @flag
        dn = "cn=#{@firstname},ou=people,dc=example,dc=com"
        @lda.replace_attribute dn, :userPassword, @new_password
        puts @lda.get_operation_result
      else
        puts "invalid username or password"
      end
  end
  
  # can modify any attribute of any user
  #no such attribute error on trying to modify non existing user
  def modify
   
    if ARGV
       ARGV.each do |arg|
         @firstname = ARGV[0]
         @password = ARGV[1]
         @attribute = ARGV[2]
         @value = ARGV[3]
       end
     end
     filter = Net::LDAP::Filter.eq( "cn","#{@firstname}" ) & Net::LDAP::Filter.eq( "userPassword", "#{@password}" )
     @lda.search( :base => "#{@root_suffix}", :filter =>filter, :return_result => true ) do |entry|
        if entry.dn
          @flag = true
        else 
          @flag = false
        end
     end
      puts "*********** modify result *********"
     if @flag
         dn = "cn=#{@firstname},#{@users_suffix}"
         ops = [
           [:replace, @attribute.to_sym, @value ]
         ]
         @lda.modify :dn => dn, :operations => ops
         puts @lda.get_operation_result
       else
         puts "invalid username or password" 
      end
  end

end #end of class

user = LdapUser.new
user.get_yaml_values
user.create_connection
user.authenticate
#user.create_user       #give arguments firstname, lastname, password
#user.modify             #give arguments firstname, password, attribute to change, value
#user.change_password   # give arguments firstname, password, new password






