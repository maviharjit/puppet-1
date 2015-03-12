#
# Puppet class to set yum proxy details
#

class yum::proxy {

	file { "/usr/local/bin/set-yum-proxy":
		mode		=> 700,
		owner		=> root,
		group		=> root,
		source		=> "puppet:///modules/yum/set-yum-proxy",
	}

	exec { "set yum proxy":
		command		=> "/usr/local/bin/set-yum-proxy",
		require		=> File["/usr/local/bin/set-yum-proxy"],
		timeout		=> 60,
	}

}

