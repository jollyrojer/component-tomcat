import os

from test_runner import BaseComponentTestCase
from qubell.api.private.testing import instance, workflow, values


class TomcatDevComponentTestCase(BaseComponentTestCase):
    name = "component-tomcat-dev"
    apps = [{
        "name": name,
        "file": os.path.join(os.path.dirname(__file__), '../%s.yml'.format(name))
    }]

    @instance(byApplication=name)
    @values({"app-hosts": "hosts", "app-port": "port"})
    def test_port(self, instance, hosts, port):
        import socket

        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        result = sock.connect_ex((hosts, port))

        assert result == 0