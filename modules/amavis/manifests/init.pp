#
# puppet class to manage amavisd-new
#

class amavis {
	include amavis::package
	include amavis::service
	include amavis::groups
}

class amavis::package {
	$pkg = "amavisd-new"
	package { $pkg:
		ensure		=> installed
	}
}

class amavis::service {
	$svc = "amavis"
	service { $svc:
		enable		=> true,
		hasrestart	=> true,
		hasstatus	=> true,
		require		=> Class["amavis::package"],
	}
}

class amavis::groups {
	include clamav
	$groups = [ "amavis", "clamav" ]
	user { "amavis":
		ensure		=> present,
		groups		=> $groups,
		membership	=> minimum,
		require		=> Class["amavis::package"],
		notify		=> Class["amavis::service"],
	}
	user { "clamav":
		ensure		=> present,
		groups		=> $groups,
		membership	=> minimum,
		require		=> Class["amavis::package"],
		notify		=> Class["clamav::service"],
	}
}

# extra utilities which enable amavis to look deeper into content
class amavis::decoders {
	$pkgs = [
		"cabextract",
		"lzop",
		"nomarch",
		"p7zip",
		"p7zip-full",
		"ripole",
		"rpm2cpio",
		"unrar-free",
		"zoo",
	]
	package { $pkgs:
		ensure	=> installed,
		notify	=> Class["amavis::service"],
	}
}

