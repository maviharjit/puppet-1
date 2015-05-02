# puppet class to configure postfix

class postfix {
	include postfix::package
	include postfix::service
	include postfix::removepkgs
	include postfix::make
	include postfix::files
}

class postfix::files {
	define postfix_file ( $replace = false ) {
		file { "/etc/postfix/$name":
			ensure	=> file,
			owner	=> root,
			group	=> root,
			mode	=> 640,
			notify	=> Class["postfix::make"],
			require	=> Class["postfix::package"],
			replace	=> $replace,
			source	=> "puppet:///modules/postfix/$name",
		}
	}

	# files that merely need to be present - should not be overwritten by puppet
	$files = [ "access", "header-checks", "sender-access", "transport", "virtual" ]
	postfix_file { $files: }

	# files that puppet distributes
	postfix_file { "Makefile": replace => true }
}

class postfix::make {
	include make::package
	exec { "update postfix databases":
		command		=> "make",
		cwd		=> "/etc/postfix",
		logoutput	=> true,
		refreshonly	=> true,
		require		=> Class["make::package"],
	}
}

class postfix::package {
	$pkg = "postfix"
	package { $pkg:
		ensure		=> installed,
	}
}

class postfix::service {
	$svc = "postfix"
	service { $svc:
		enable		=> true,
		require		=> Class["postfix::package"],
	}
}

# remove conflicting mail server
class postfix::removepkgs {
	$removepackages = [
		"exim4",
		"exim4-base",
		"exim4-config",
		"exim4-daemon-light",
	]
	package { $removepackages:
		ensure		=> purged,
		require		=> Class["postfix::package"],
	}
}

# enable sasl for postfix
class postfix::sasl {
	include ::sasl

	file { "/etc/postfix/sasl":
		ensure		=> directory,
		owner		=> root,
		group		=> root,
		mode		=> 755,
	}

	file { "/etc/postfix/sasl/smtpd.conf":
		ensure		=> file,
		owner		=> root,
		group		=> root,
		mode		=> 644,
		require		=> File["/etc/postfix/sasl"],
		before		=> Class["sasl::package"],
		notify		=> Class["sasl::service"],
		content		=> '# Managed by puppet - do not edit here
pwcheck_method: saslauthd
mech_list: PLAIN LOGIN DIGEST-MD5 CRAM-MD5
',
	}

	# create directories for postfix chroot
	$dirs = [ "/var/spool/postfix/var", "/var/spool/postfix/var/run", "/var/spool/postfix/var/run/saslauthd" ]
	file { $dirs:
		ensure	=> directory,
		owner	=> root,
		group	=> sasl,
		mode	=> 775,
	}

	# modify sasl startup configuration to put its file in the postfix chroot
	case $operatingsystem {
		debian, ubuntu: {
			text::replace_lines { "/etc/default/saslauthd postfix":
				file		=> "/etc/default/saslauthd",
				pattern		=> '^(OPTIONS=.-c -m) (.var.run.saslauthd)',
				replace		=> '\1 \/var\/spool\/postfix\2',
				require		=> [
					Class["sasl::package"],
					File["/var/spool/postfix/var/run/saslauthd"],
				],
				notify		=> Class["sasl::service"],
			}
		}
	}

	# create symlink pointing to the redirected run dir
	$linkdest = "/var/spool/postfix/var/run/saslauthd"
	file { "/var/run/saslauthd":
		backup		=> false,
		before		=> Class["sasl::package"],
		ensure		=> $linkdest,
		force		=> true,
		require		=> File[$linkdest],
	}

	# add postfix user to sasl group
	user { "postfix":
		membership	=> minimum,
		groups		=> "sasl",
	}

}

