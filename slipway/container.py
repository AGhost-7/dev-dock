
import os
from .image import Image
from .volumes import Volumes
from .binds import Binds
from .util import snake_case


class Container(object):

    def __init__(self, client, args):
        self.client = client
        self.args = args
        self.image = Image(self.client, self.args)
        self.volumes = Volumes(self.client, self.args, self.image)
        self.binds = Binds(self.client, self.args, self.image)
        self.name = 'slipway_' + snake_case(self.args.image)

    def _run_arguments(self):
        arguments = [
            'docker',
            'run',
            '--net=host',
            '--rm',
            '-ti',
            '--detach-keys', 'ctrl-q,ctrl-q',
            '--name', self.name,
            '-e', 'GH_USER',
            '-e', 'GH_PASS',
            '-e', 'DISPLAY'
        ]

        for bind in self.binds.list():
            arguments.append('-v')
            argument = bind.host_path + ':' + bind.container_path
            if 'ro' in bind.type:
                argument += ':ro'
            arguments.append(argument)

        for volume in self.volumes.list():
            arguments.append('--mount')
            arguments.append(
                'source={},target={}'.format(volume.name, volume.path))
        arguments.append(self.image.name)
        arguments.append('tmux')
        arguments.append('new')
        return arguments

    def run(self):
        os.execvp('docker', self._run_arguments())
