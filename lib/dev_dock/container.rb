require 'docker'
require 'dev_dock/util'
require 'dev_dock/image'
require 'dev_dock/volumes'

module DevDock

	class DevContainer

		def initialize(image_name)
			@image = DevDock::DevImage.new(image_name)
			@volumes = DevDock::DevVolumes.new(@image)
			@name = DevDock::Util::snake_case("dev_dock_" + image_name)
		end

		def image
			@image
		end

		def volumes
			@volumes
		end

		def exist?
			Docker::Container.get(@name)
			true
		rescue Docker::Error::NotFoundError
			false
		end

		# kill container
		def kill
			Docker::Container.get(@name).kill		
		end

		def enable_x11(arguments)
			arguments.push '-v'
			arguments.push '/tmp/.X11-unix:/tmp/.X11-unix:ro'
			arguments.push '-e'
			arguments.push 'DISPLAY'
		end

		def run
			arguments = [
				'/usr/local/bin/docker',
				'run',
				'--privileged',
				'--name', @name,
				'--net=host',
				'--rm',
				'-ti',
				'--detach-keys',
				'ctrl-q,ctrl-q',
				'-u', `id -u`,
				'-e', 'GH_USER',
				'-e', 'GH_PASS',
				'-v', '/run/docker.sock:/var/run/docker.sock'
			]

			['workspaces', '.gitconfig', '.ssh'].each do |directory|
				arguments.push '-v', "#{ENV['HOME']}/#{directory}:/home/#{@image.user}/#{directory}"
			end

			if RUBY_PLATFORM == "x86_64-linux"
				enable_x11(arguments)
				arguments.push '-v', '/etc/localhost:/etc/localhost:ro'
			end

			@volumes.list.each do |volume|
				arguments.push '--mount', "source=#{volume.name},target=#{volume.path}"
			end

			arguments.push @image.name

			arguments.push 'tmux'
			arguments.push 'new'

			exec *arguments
		end
	end
end
