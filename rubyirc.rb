
#NOTICE nick : VERSION Telnet version 0.1 :)
#:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP PRIVMSG #test :a message to the channel
#:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP PRIVMSG testdev :PING 3399361702
#:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP PART #test :"Leaving"
=begin
while joining a channel:
JOIN #test

:testdev!testdev@sorcery-j2kt9o.bc.googleusercontent.com JOIN :#test

:gaia.sorcery.net 353 testdev = #test :alisa_000 testdev 

:gaia.sorcery.net 366 testdev #test :End of /NAMES list.


giving ops,voice,kick
MODE #test +o :alisa_000

:testdev!testdev@sorcery-j2kt9o.bc.googleusercontent.com MODE #test +o alisa_000
:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP MODE #test -o testdev
:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP MODE #test +v testdev
:alisa_000!alisa_000@sorcery-c1h.ces.171.78.IP KICK #test testdev :alis
=end
require 'socket'
require 'thread'

class Command
	def privmsg(target, content, action=false)
		
	end
	
	def part(channel, message="Leaving")
		result = "PART #{channel} #{message}"
		return result
	end
	
	def mode(target, content)
		#parse the content to process different mode commands
		#Manage +o,-o, +v, -v, for users
		#Manage channel modes (explore some popular ones)
		#Manage +b, -b, it has a special case with hostname
	end
	
	def join(channel)
		result = "JOIN #{channel}"
		return result
	end
	
	def kick(channel, nickname,reason=nil)
		result = "KICK #{channel} #{nickname}"
		if reason
			result += (" "+ reason)
		end
		return result
	end
	
end

def get_nickname(server_line)
    length = server_line.index("!")
    return server_line[1...length]
end

def get_message_command(server_line)
	message_command = server_line.match(/\s[A-Z]*(\s)/)[0].strip
	return message_command
end

def get_message_target(server_line)
	message_target= server_line.split[2]
	return message_target
end

def get_message_content(server_line)
	split_line=server_line.split
	message_content=split_line.reverse[0...-3].reverse.join(' ')
	return message_content
end

def get_user_info(server_line)
	#client mesajda ünlem ve space arasındaki kısmı parse et
	user_info = server_line.match(/!([^\s]*)/)[1]
	return user_info
end

def parse_incoming_message(server_line)
	split_line = server_line.split
	
	if /\d{1,3}/.match(split_line[1])
		server_message= Hash.new
		server_message = {
			:message_type => "server_message",
			:host => split_line[0],
			:message_id => split_line[1],
			:reciever => split_line[2],
			:message_content => split_line[3..-1].join(' ')
		}
		return server_message

	elsif split_line[0]=="PING"
		server_message= Hash.new
		server_message = {
			:message_type => "ping_message",
			:message_content => server_line,				  
			:message_response => server_line.gsub("PING","PONG")
		}
		
		return server_message
	elsif split_line[1]=="NOTICE"
		server_message= Hash.new
		server_message = {:message_type => "notice_message"}
		return server_message
	else
		client_message = Hash.new
		client_message = {
			:message_type => "client_message", 
			:nickname => get_nickname(server_line), 
			:user_info => get_user_info(server_line), 
			:message_command => get_message_command(server_line), 
			:message_target => get_message_target(server_line), 
			:message_content => get_message_content(server_line)
			
		}
		return client_message
		
	end
end

def connect_server(hostname,port,my_nick,user)
	puts "Connecting to #{hostname} on port: #{port}..."
	server_socket=TCPSocket.open(hostname,port)
	puts "NICK #{my_nick}"
	server_socket.puts "NICK #{my_nick}"
	puts user
	server_socket.puts user
	return server_socket
end

def recieve_data (server_socket)
	while true
			server_line = server_socket.gets
			recieved = parse_incoming_message(server_line)
			if recieved[:message_type] == "server_message"
				puts "#{recieved[:host]} #{recieved[:message_id]} #{recieved[:message_content]}"
			elsif recieved[:message_type]=="client_message"
				puts "#{recieved[:nickname]} : #{recieved[:message_command]} to #{recieved[:message_target]} #{recieved[:message_content]}"
			else puts server_line
			end

			if server_line
				if recieved[:message_type]=="ping_message"
					server_socket.puts recieved[:message_response]
					puts recieved[:message_response]
				elsif server_line.include?("VERSION")
					puts "NOTICE IRC : VERSION RubyIRC Test"
				end
			end
	end
end

def send_data (server_socket)
	while true
		client_line = gets.chomp
		server_socket.puts(client_line)
	end
end

hostname = 'irc.sorcery.net'
port = "6667"
my_nick = "testdev"
user = "USER #{my_nick} #{my_nick} #{hostname} :realname"

server_socket = connect_server(hostname, port, my_nick,user)
recieve_thread = Thread.new{recieve_data(server_socket)}
send_thread = Thread.new{send_data(server_socket)}
send_thread.join
recieve_thread.join

